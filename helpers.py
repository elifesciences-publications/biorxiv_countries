import re

def Find_posted_date(resp):
    newer = resp.html.find('.hw-version-current-link', first=True)
    # Also grab the "Posted on" date on this page:
    posted = resp.html.find('meta[name="article:published_time"]', first=True)
    # if newer is not None: # if there's an newer version, grab the date
    #     date_search = re.search('(\w*) (\d*), (\d{4})', newer.text)
    #     if len(date_search.groups()) < 3:
    #         return None
    #     month = date_search.group(1)
    #     day = date_search.group(2)
    #     year = date_search.group(3)
    #     datestring = f"{year}-{month_to_num(month)}-{day}"
    #     return datestring
    if posted is not None: # if not, just grab the date from the current version
        return posted.attrs["content"]
    return None

def Trim_name(name):
    nopunc = re.sub(r"\.", "", name)
    nomi = re.sub(r"\s[A-Z][\.\s]", " ", name)
    for repeat in range(2): # we remove up to 3 middle initials
        nomi = re.sub(r"\s[A-Z][\.\s]", " ", nomi)
    nomi = re.sub(r"\s+", " ", nomi) # trim all the extra spaces we added when looking for initials
    nomi = re.sub(r"\.", "", nomi) # stripping punctuation from names w periods in places other than middle initial
    return (nopunc, nomi)

def Make_tables(cursor):
    cursor.execute("CREATE TABLE IF NOT EXISTS article_authors (id SERIAL PRIMARY KEY, name text NOT NULL, affiliation text, orcid text, email text, observed date, name_nopunc text, name_nomi text, article integer NOT NULL);")
    
    cursor.execute("CREATE TABLE IF NOT EXISTS institutions (id SERIAL PRIMARY KEY, name text NOT NULL, ror text, grid text, country text);")
    cursor.execute("CREATE TABLE IF NOT EXISTS affiliation_institutions (affiliation text PRIMARY KEY, institution integer NOT NULL);")
    cursor.execute("CREATE TABLE IF NOT EXISTS countries (alpha2 text PRIMARY KEY, name text NOT NULL, continent text);")

    cursor.execute("CREATE TABLE IF NOT EXISTS publication_dates (article int PRIMARY KEY, date date")