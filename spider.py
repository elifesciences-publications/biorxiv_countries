#     Copyright (C) 2020 Regents of the University of Minnesota

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
#     Dr. Ran Blekhman at the University of Minnesota:
#     email: blekhman@umn.edu
#     mail: MCB 6-126, 420 Washington Avenue SE, Minneapolis, MN 55455
#     http://blekhmanlab.org/
import csv
import sys
import time

import config
import db

import models

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
  elif sys.argv[1] == 'load': 
    if len(sys.argv) > 2:
      load_manual_assignments(spider,sys.argv[2])
    else:
      print("Expected file name to load. Exiting.")
      exit(1)
