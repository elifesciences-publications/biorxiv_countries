import os

# Information about how to connect to a postgres database will
# all the Rxivist data
authordb = {
  "host": "authordb",
  "db":  "postgres",
  "user":  "postgres",
  "password": "",
  "schema": "prod"
}

rxdb = {
  "host": os.environ['RX_DBHOST'],
  "db": "rxdb",
  "user":  "root",
  "password": os.environ['RX_DBPASSWORD'],
  "schema": "prod"
}

# How much output to send to application logs
log_level = "info"
# Whether to print messages to stdout
log_to_stdout = True
# Whether to record messages in a timestamped file
log_to_file = False

# how the web crawler should identify itself when sending http requests
# to sites such as bioRxiv and crossref
user_agent = "rxivist web crawler (rxivist.org)"

# whether to add pauses at several places in the crawl
polite = True
delay = 1.25 # pause length, in seconds
