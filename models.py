import config
import db
import helpers
from log import Logger
import models

import re
import time
import urllib.parse

import psycopg2
from requests_html import HTMLSession
import requests

class Author:
  def __init__(self, name, affiliation, email, observed, orcid=None, id=None, name_nopunc=None, name_nomi=None, article=None):
    if affiliation == "":
      affiliation = None
    if email == "":
      email = None
    if observed == "":
      observed = None
    if orcid == "":
      orcid = None
    if id == "":
      id = None
    if name_nopunc == "":
      name_nopunc = None
    if name_nomi == "":
      name_nomi = None
    if article == "":
      article = None
    self.name = name
    if affiliation is not None:
      if not isinstance(affiliation, int):
        # if this isn't one of the cases where we get an ID instead of a string,
        # lots of affiliation strings from biorxiv for some reason end in semicolons
        self.affiliation = re.sub(r";$", "", affiliation)
      else:
        self.affiliation = affiliation
    else:
      self.affiliation = None
    self.email = email
    self.observed = observed # date of the posting
    self.orcid = orcid
    self.id = id
    self.name_nopunc = name_nopunc # no periods
    self.name_nomi = name_nomi # no middle initial
    self.article = article # if the author is associated with a single article
    
class Article:
  def __init__(self, id, url):
    self.id = id
    self.url = url

class Spider(object):
  def __init__(self):
    # author database:
    self.connection = db.Connection(config.authordb["host"], config.authordb["db"], config.authordb["user"], config.authordb["password"], config.authordb["schema"])
    # Creates any missing tables that are expected to exist in the application database.
    # Does NOT verify whether the current columns are accurate.
    with self.connection.db.cursor() as cursor:
      helpers.Make_tables(cursor)

    # PROD DATABASE with article info:
    self.PROD =  db.Connection(config.rxdb["host"], config.rxdb["db"], config.rxdb["user"], config.rxdb["password"], config.rxdb["schema"])

    # Requests HTML configuration
    self.session = HTMLSession(mock_browser=False)
    self.session.headers['User-Agent'] = config.user_agent
    
    self.log = Logger()
  
  def find_unprocessed_articles(self, cap=10000):
    """
    Obtains a list of unprocessed articles and determines their author data.
    """
    done = []
    with self.connection.db.cursor() as cursor:
      cursor.execute(f'SELECT DISTINCT(article) FROM prod.article_authors ORDER BY article;')
      for record in cursor:
        if len(record) > 0:
          done.append(record[0])
    self.log.record(f'Found {len(done)} done already')

    todo = []
    with self.PROD.db.cursor() as cursor:
      cursor.execute(f'SELECT id, url FROM prod.articles WHERE url IS NOT NULL ORDER BY id;')
      for record in cursor:
        if len(record) > 0:
          if record[0] not in done:
            todo.append(models.Article(record[0], record[1]))
            if len(todo) >= cap:
              self.log.record(f'Found max of {cap} entries to do; returning')
              return todo
        else:
          self.log.record(f'Empty entry', 'error')
    self.log.record(f'GOT {len(todo)} TO DO')
    return todo

  def _flag_article(self, article):
    """
    Records a dummy author for preprints with bad data, so we don't revisit them over and over again
    """
    self.log.record(f'  Flagging preprint at {article.url} as problem.', 'warn')
    with self.connection.db.cursor() as cursor:
      cursor.execute('INSERT INTO prod.article_authors (article, name) VALUES (%s, %s)', (article.id, '000bad_data000'))

  def process_articles(self, todo):
    """
    Records authors for each paper
    """
    for x in todo:
      if config.polite:
        time.sleep(config.delay)
      try:
        authors = self.get_article_authors(x.url)
      except NameError:
        self.log.record("  Error finding authors.", "warn")
        self._flag_article(x)
        continue
      if len(authors) == 0:
        self.log.record("  No authors listed.", "warn")
        self._flag_article(x)

      self._record_authors(x.id, authors)

  def get_article_authors(self, url, retry_count=0):
    """
    Returns a list of author objects when given a preprint URL.
    """
    self.log.record(f'Getting authors for {url}')
    try:
      resp = self.session.get(f"{url}.article-metrics", timeout=10)
    except Exception as e:
      if retry_count < 3:
        self.log.record(f"Error requesting article metrics. Retrying: {e}", "error")
        return self.get_article_authors(url, retry_count+1)
      else:
        self.log.record(f"Error AGAIN requesting article metrics. Bailing: {e}", "error")
        return (None, None)
    if resp.status_code != 200:
      self.log.record(f"  Got weird status code: {resp.status_code}", 'warn')
      if retry_count < 1: # only retry once
        time.sleep(5)
        return self.get_article_authors(url, retry_count+1)
      else:
        # 403s here appear to be mostly caused by papers being "processed"
        raise NameError

    # Figure out the date this was posted
    datestring = helpers.Find_posted_date(resp)
    self.log.record(f'FOUND DATE: {datestring}', 'debug')
    # Then get the authors:
    authors = []
    author_tags = resp.html.find('meta[name^="citation_author"]')
    current_name = ""
    current_institution = ""
    current_email = ""
    current_orcid = ""
    for tag in author_tags:
      if tag.attrs["name"] == "citation_author":
        if current_name != "": # if this isn't the first author
          authors.append(models.Author(current_name, current_institution, current_email, datestring, current_orcid))
        current_name = tag.attrs["content"]
        current_institution = ""
        current_email = ""
        current_orcid = ""
      elif tag.attrs["name"] == "citation_author_institution":
        current_institution = tag.attrs["content"]
      elif tag.attrs["name"] == "citation_author_email":
        current_email = tag.attrs["content"]
      elif tag.attrs["name"] == "citation_author_orcid":
        current_orcid = tag.attrs["content"]
    # since we record each author once we find the beginning of the
    # next author's entry, the last step has to be to record whichever
    # author we were looking at when the author list ended:
    if current_name != "": # if we somehow didn't find a single author
      authors.append(models.Author(current_name, current_institution, current_email, datestring, current_orcid))
    
    return authors

  def _record_authors(self, article_id, authors, overwrite=False):
    """
    Given an array of authors, records them in the DB and associates them with a single paper.
    """
    to_write = []
    with self.connection.db.cursor() as cursor:
      for a in authors:
        nopunc, nomi = helpers.Trim_name(a.name)
        cursor.execute("""
        INSERT INTO article_authors (name, orcid, affiliation, email, observed, name_nopunc, name_nomi, article)
        VALUES (%s, %s, %s, %s, %s, LOWER(%s), LOWER(%s), %s)
        RETURNING id;
        """, (a.name, a.orcid, a.affiliation, a.email, a.observed, nopunc, nomi, article_id))
        a.id = cursor.fetchone()[0]
        self.log.record(f"  Recorded author {a.name} with ID {a.id}", "info")
        to_write.append((article_id, a.id))

  def record_author_links(self, entry, canonical):
    """
    When we figure out which canonical author ID should be linked to a paper's author,
    this records that info in all the places we keep track of the info
    """
    with self.connection.db.cursor() as cursor:
      # link the paper:
      cursor.execute("INSERT INTO prod.canonical_author VALUES (%s, %s)", (entry.id, canonical))
      # add new names:
      nopunc, nomi = helpers.Trim_name(entry.name)
      cursor.execute("""
        INSERT INTO prod.author_names (author, name, name_nopunc, name_nomi)
        VALUES (%s, %s, LOWER(%s), LOWER(%s))
        ON CONFLICT DO NOTHING
      """, (canonical, entry.name, nopunc, nomi))
      # add institution
      cursor.execute("INSERT INTO prod.author_institutions (author, institution) VALUES (%s, %s) ON CONFLICT DO NOTHING", (canonical, entry.affiliation))

  def _record_canonical_name(self, to_record, affiliation):
    """Helper function for canonical_names function below.

    """
    self.log.record(f"  Recording {to_record} for {affiliation}", 'info')
    with self.connection.db.cursor() as cursor:
      cursor.execute(f"""
        INSERT INTO {config.authordb['schema']}.affiliation_institutions (affiliation, institution)
        VALUES (%s, %s);
      """, (affiliation, to_record))

  def canonical_names(self, max_calls=10000):
    """Interacts with a local deployment of the ROR database to determine institution names

    """
    todo = []
    with self.connection.db.cursor() as cursor:
      self.log.record('Querying for unlinked affiliations', 'info')
      # current affiliations, sorted by how many authors are in them:
      cursor.execute(f"""
      SELECT affiliation FROM (
        SELECT affiliation, COUNT(id)
        FROM prod.article_authors
        WHERE affiliation IN (
          SELECT a.affiliation
          FROM prod.article_authors a
          LEFT JOIN prod.affiliation_institutions i ON a.affiliation=i.affiliation
          WHERE i.institution IS NULL
          AND a.affiliation IS NOT NULL
        )
        GROUP BY 1
        ORDER BY 2 DESC
      ) AS asdf
      LIMIT %s
      """, (max_calls,))
      # (There may be lots of authors not linked to an institution
      # if their affiliation string is empty.)

      # institutions listed on any preprint:
      # cursor.execute(f"""
      #   SELECT DISTINCT(affiliation)
      #   FROM(
      #     SELECT a.affiliation, i.institution AS canonical
      #     FROM prod.article_authors a
      #     LEFT JOIN prod.affiliation_institutions i ON a.affiliation=i.affiliation
      #     WHERE i.institution IS NULL
      #     ORDER BY a.observed DESC
      #   ) AS asdf
      #   LIMIT %s
      # """, (max_calls,))

      for record in cursor:
        if len(record) > 0:
          todo.append(record[0])
    self.log.record(f'Linking {len(todo)} affiliations.', 'debug')
    with self.connection.db.cursor() as cursor:
      for affiliation in todo:
        if affiliation is None: continue
        self.log.record(f'Translating |{affiliation}|')
        url_affiliation = urllib.parse.quote(affiliation) # avoiding weird symbols
        to_record = None
        try:
          r = requests.get(f"http://rorapiweb/organizations?affiliation={url_affiliation}")
        except Exception as e:
          self.log.record(f"Error calling ROR API: {e}", 'error')
          continue

        if r.status_code != 200:
          # If the API returns an error, record "unknown" for that institution and move on
          self.log.record(f"Got weird status code: {r.status_code}", 'error')
          self._record_canonical_name(0, affiliation)
          continue

        resp = r.json()

        if 'items' not in resp.keys() or len(resp['items']) == 0:
          self.log.record(f"  No results found for {affiliation}", 'info')
          self._record_canonical_name(0, affiliation)
          continue

        for item in resp['items']:
          if item['chosen']: # if it passes the ROR criteria for being the "right" answer
            answer = {
              'name': item['organization']['name'],
              'ror': item['organization']['id'],
              'grid': item['organization']['external_ids']['GRID']['preferred'],
              'country': item['organization']['country']['country_code']
            }
            break
        else:
          self.log.record(f"  No confident results found for {affiliation}", 'info')
          self._record_canonical_name(0, affiliation)
          continue

        cursor.execute(f"""
          SELECT id
          FROM {config.authordb['schema']}.institutions
          WHERE name=%s;
        """, (answer['name'],))
        exists_id = cursor.fetchone()
        if exists_id is not None:
          self.log.record(f"  Found entry for {affiliation}! {exists_id}", 'debug')
          self._record_canonical_name(exists_id[0], affiliation)
          continue

        self.log.record(f"\n\n\n\n  !!!Adding new institution: {answer['name']}!\n\n\n\n!!!!\n\n", 'info')
        cursor.execute(f"""
          INSERT INTO {config.authordb['schema']}.institutions (name, ror, grid, country)
          VALUES (%s, %s, %s, %s)
          RETURNING id;
        """, (answer['name'], answer['ror'], answer['grid'], answer['country']))
        to_record = cursor.fetchone()[0]
        # once the new institution is recorded, link it to this record:
        self._record_canonical_name(to_record, affiliation)