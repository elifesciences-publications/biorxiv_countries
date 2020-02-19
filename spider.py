#     Rxivist, a system for crawling papers published on bioRxiv
#     and organizing them in ways that make it easier to find new
#     or interesting research. Includes a web application for
#     the display of data.
#     Copyright (C) 2019 Regents of the University of Minnesota

#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU Affero General Public License as
#     published by the Free Software Foundation, version 3.

#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU Affero General Public License for more details.

#     You should have received a copy of the GNU Affero General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.

#     Any inquiries about this software or its use can be directed to
#     Professor Ran Blekhman at the University of Minnesota:
#     email: blekhman@umn.edu
#     mail: MCB 6-126, 420 Washington Avenue SE, Minneapolis, MN 55455
#     http://blekhmanlab.org/
import csv
import sys
import time

import config
import db

import models

def consolidate(spider, limit=5000000, reconsolidate=False):
  if reconsolidate:
    # Breaks all existing links between papers and canonical authors,
    # and reassigns them using the current collection of known authors
    with spider.connection.db.cursor() as cursor:
      cursor.execute('DELETE FROM prod.canonical_author WHERE TRUE')

  # fetch all article authors not linked to a canonical identity
  todo = []
  with spider.connection.db.cursor() as cursor:
    # NOTE: This fetches the *canonical institution* NOT the affiliation string
    cursor.execute(f"""
      SELECT a.name, i.institution, a.email, a.observed, a.orcid, a.id, a.name_nopunc, a.name_nomi, a.article
      FROM prod.article_authors a
      LEFT JOIN prod.canonical_author c ON a.id=c.article_author
      INNER JOIN prod.affiliation_institutions i ON a.affiliation=i.affiliation 
      WHERE c.canonical IS NULL
      ORDER BY a.observed, a.id, a.name
      LIMIT %s
    """, (limit,))
    for x in cursor:
      if len(x) > 0:
        todo.append(models.Author(*x))
  spider.log.record(f'TO DO: {len(todo)}')
  done = 0
  for entry in todo:
    link_canonical_author(spider, entry)
    done += 1
    if done % 1000 == 0:
      with spider.connection.db.cursor() as cursor:
        cursor.execute(f"""
          SELECT COUNT(article_author), COUNT(DISTINCT canonical)
          FROM prod.canonical_author
        """)
        x = cursor.fetchone()
        if x is not None:
          print(f'Entries: {x[0]} || Authors: {x[1]}\n')

def link_canonical_author(spider, entry):
  """
  Given the author of a single paper, this determines what existing canonical author
  they should be linked to. If one is not found, it creates a new one.
  """
  with spider.connection.db.cursor() as cursor:
    spider.log.record(f'Evaluating {entry.name}', 'debug')
    if entry.orcid is not None:
      spider.log.record(f'  Entry has ORCID.', 'debug')
      # if the author has an ORCID, make sure it's not assigned to a bunch of
      # people on the same paper.
      cursor.execute(f"""
        SELECT COUNT(id) FROM prod.article_authors
        WHERE article=%s
        AND orcid=%s
      """, (entry.article, entry.orcid))
      count = author = cursor.fetchone()[0]
      if count > 1:
        spider.log.record('  ORCID shared among authors on same paper; disregarding', 'debug')
        entry.orcid = None

    if entry.orcid is not None:
      spider.log.record(f'  Entry has valid ORCID', 'debug')
      cursor.execute(f"""
        SELECT id FROM prod.authors
        WHERE orcid=%s
      """, (entry.orcid,))
      author = cursor.fetchone()

      # if author has a recognized ORCID
      if author is not None:
        #spider.log.record(f'  Existing author found with orcid {entry.orcid}')
        spider.record_author_links(entry, author[0])
        return

      # if ORCID isn't recognized, check full name matches among authors WITHOUT orcids
      spider.log.record(f'  ORCID not recognized; checking full name', 'debug')
      cursor.execute(f"""
        SELECT COUNT(DISTINCT n.author)
        FROM prod.author_names n
        INNER JOIN prod.authors a ON a.id=n.author
        WHERE n.name_nopunc=%s
        AND a.orcid IS NULL
      """, (entry.name_nopunc,))
      count = cursor.fetchone()
      # if author has a recognized full name
      if count is not None:
        count = count[0]
        spider.log.record(f'  Authors with name {entry.name}: {count}', 'debug')
        if count == 1:
          spider.log.record(f'  Only one author! Linking! {entry.name}', 'debug')
          cursor.execute(f"""
            SELECT DISTINCT n.author
            FROM prod.author_names n
            INNER JOIN prod.authors a ON a.id=n.author
            WHERE n.name_nopunc=%s
            AND a.orcid IS NULL
          """, (entry.name_nopunc,))
          author = cursor.fetchone()[0]
          spider.record_author_links(entry, author)
          # Add the ORCID to the existing author
          cursor.execute('UPDATE prod.authors SET orcid=%s WHERE id=%s', (entry.orcid, author))
          return
        # elif count > 1: # if an author shows up with an ORCID, and multiple authors have that name already but none has ORCID?
        #   *tk

      # if author has ORCID but no full name match, check match with no middle initials
      # but with an institution match
      spider.log.record(f'  No full-name match. Checking without middle initials', 'debug')
      cursor.execute(f"""
        SELECT DISTINCT i.author
        FROM prod.author_institutions i
        LEFT JOIN prod.author_names n ON i.author=n.author
        INNER JOIN prod.authors a ON a.id=i.author
        WHERE i.institution = %s
        AND i.institution > 0
        AND n.name_nomi = %s
        AND a.orcid IS NULL
      """, (entry.affiliation, entry.name_nomi,))
      # (we use a LEFT JOIN here so an author with multiple names and/or multiple institutions
      # will appear in the results with every name paired with every institution.)
      author = cursor.fetchone()
      # if author has a recognized NoMI name
      if author is not None:
        spider.log.record(f'  author (with ORCID) found using institution and no middle initial name: {author[0]} {entry.name}', 'debug')
        spider.record_author_links(entry, author[0])
        # Add the ORCID to the existing author
        cursor.execute('UPDATE prod.authors SET orcid=%s WHERE id=%s', (entry.orcid, author[0]))
        return
      
      # if author has no legit matches, create a new author record
      spider.log.record(f'  No matches found. Creating new author', 'debug')
      cursor.execute("INSERT INTO prod.authors (name, orcid) VALUES (%s, %s) RETURNING id", (entry.name, entry.orcid))
      new_id = cursor.fetchone()[0]
      spider.record_author_links(entry, new_id)
      spider.log.record(f'  Author {entry.name} recorded with ID {new_id}', 'debug')
      return
    
    #-------------------
    # if the author doesn't have an ORCID
    # (this section is essentially the same as above, except it doesn't rule out existing authors
    # that already have ORCIDs)
    spider.log.record(f'  No ORCID; checking full name', 'debug')
    cursor.execute(f"""
      SELECT COUNT(DISTINCT n.author)
      FROM prod.author_names n
      INNER JOIN prod.authors a ON a.id=n.author
      WHERE n.name_nopunc=%s
    """, (entry.name_nopunc,))
    count = cursor.fetchone()
    # if author has a recognized full name
    if count is not None:
      count = count[0]
      spider.log.record(f'  Authors with name {entry.name}: {count}', 'debug')
      if count == 1:
        spider.log.record(f'  Only one author! Linking! {entry.name}', 'debug')
        cursor.execute(f"""
          SELECT DISTINCT n.author
          FROM prod.author_names n
          INNER JOIN prod.authors a ON a.id=n.author
          WHERE n.name_nopunc=%s
        """, (entry.name_nopunc,))
        author = cursor.fetchone()[0]
        spider.record_author_links(entry, author)
        return
      # elif count > 1: # if the name is shared by multiple existing authors, prefer the one with the ORCID
      #   *tk

    # if author has no full name match, check match with no middle initials
    spider.log.record(f'  No full-name match. Checking without middle initials', 'debug')
    cursor.execute(f"""
      SELECT DISTINCT i.author
      FROM prod.author_institutions i
      LEFT JOIN prod.author_names n ON i.author=n.author
      WHERE i.institution = %s
      AND i.institution > 0
      AND n.name_nomi = %s
    """, (entry.affiliation, entry.name_nomi,))
    author = cursor.fetchone()
    # if author has a recognized NoMI name
    if author is not None:
      spider.log.record(f'  author found using institution and no middle initial name: {author[0]} {entry.name}', 'debug')
      spider.record_author_links(entry, author[0])
      return
    
    # This had an annoyingly high false-positive rate
    # last try is to look for a NoMI name match with someone who has an ORCID in the same country
    # cursor.execute(f"""
    #   SELECT DISTINCT i.author
    #   FROM prod.author_institutions i
    #   LEFT JOIN prod.author_names n ON i.author=n.author
    #   INNER JOIN prod.authors a ON a.id=i.author
    #   INNER JOIN prod.institutions ON i.institution=institutions.id
    #   WHERE institutions.country = (SELECT country FROM prod.institutions WHERE id=%s)
    #   AND n.name_nomi = %s
    #   AND a.orcid IS NOT NULL
    # """, (entry.affiliation, entry.name_nomi))
    # author = cursor.fetchone()
    # # if author has a recognized NoMI name
    # if author is not None:
    #   spider.log.record(f'  author with ORCID found using COUNTRY and no middle initial name: {author[0]} {entry.name}', 'info')
    #   spider.record_author_links(entry, author[0])
    #   return
    
    # if author has no legit matches, create a new author record
    #spider.log.record(f'  No matches found. Creating new author')
    cursor.execute("INSERT INTO prod.authors (name) VALUES (%s) RETURNING id", (entry.name,))
    new_id = cursor.fetchone()[0]
    spider.record_author_links(entry, new_id)
    spider.log.record(f'  Author {entry.name} recorded with ID {new_id}', 'debug')

def load_manual_assignments(spider, file):
  with open(file,'r') as csvfile, spider.connection.db.cursor() as cursor: # asdf
    reader = csv.reader(csvfile, delimiter=',', quotechar='"')
    i= 0
    for row in reader:
      spider.log.record(f'|{row[0]}| assigned to |{row[1]}|')
      cursor.execute('UPDATE prod.affiliation_institutions SET institution=%s WHERE affiliation=%s', (row[1], row[0]))
      i += 1
      if i % 100 == 0:
        print(f'\n\n\n{i}\n\n')

def full_run(spider):
  todo = spider.find_unprocessed_articles()
  spider.process_articles(todo)
  spider.canonical_names()
  consolidate(spider)

if __name__ == "__main__":
  spider = models.Spider()
  if len(sys.argv) == 1: # if no action is specified, do everything
    full_run(spider)

  elif sys.argv[1] == 'articles': # Fetches authorship of preprints
    if len(sys.argv) > 2:
      todo = spider.find_unprocessed_articles(int(sys.argv[2]))
    else:
      todo = spider.find_unprocessed_articles()
    spider.process_articles(todo)

  elif sys.argv[1] == 'affiliations': # Converts affiliation strings to canonical institutions
    if len(sys.argv) > 2:
      spider.canonical_names(int(sys.argv[2]))
    else:
      spider.canonical_names()
  
  elif sys.argv[1] == 'consolidate': # Determines canonical authors for preprint authors
    if len(sys.argv) > 2:
      consolidate(spider, int(sys.argv[2]))
    else:
      consolidate(spider)

  # Breaks all existing links between papers and canonical authors,
  # and reassigns them using the current collection of known authors
  elif sys.argv[1] == 'reconsolidate': 
    if len(sys.argv) > 2:
      consolidate(spider, int(sys.argv[2]), reconsolidate=True)
    else:
      consolidate(spider, reconsolidate=True)
  
  elif sys.argv[1] == 'load': 
    if len(sys.argv) > 2:
      load_manual_assignments(spider,sys.argv[2])
    else:
      print("Expected file name to load. Exiting.")
      exit(1)
