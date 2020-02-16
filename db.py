import psycopg2
import config

class Connection(object):
  def __init__(self, host, db, user, password, schema):
    dbname = db
    self.db = None
    self.db = psycopg2.connect(
      host=host,
      dbname=dbname,
      user=user,
      password=password,
      options=f'-c search_path={schema}'
    )
    self.db.set_session(autocommit=True)
    self.cursor = self.db.cursor()

  def __del__(self):
    if self.db is not None:
      self.db.close()
