from os import walk
import sqlite3
import csv
import requests
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
import time

##### This script creates a local SQLite database from OCI citation extracts.
#####

s = requests.Session()

retries = Retry(total=2,
                backoff_factor=1,
                status_forcelist=[ 500, 502, 503, 504 ])

s.mount('https://', HTTPAdapter(max_retries=retries))

listdois = {}

# path to OCI dump
path = "./oci"
# assuming the file does not exist
citation_filename = 'oci_extract_years.db'

con = sqlite3.connect(citation_filename)
cur = con.cursor()
cur.execute("create table if not exists articles (doi TEXT PRIMARY KEY, pmc TEXT NOT NULL, name TEXT NOT NULL)")
cur.execute("create table if not exists cites (doi_source TEXT, doi_target TEXT, year INTEGER, PRIMARY KEY (doi_source, doi_target))")
cur.execute("create index if not exists in_year on cites (year)")

def get_metadata(doi):
    try:
        r = s.get(
            "https://opencitations.net/index/api/v1/metadata/" + doi
        )

        json = r.json()
        return json[0]
    except:
        print("https://opencitations.net/index/api/v1/metadata/" + doi)

with open('pmc_doi.csv', 'r', encoding="utf-8") as read_obj:
    csv_reader = csv.reader(read_obj)
    next(csv_reader)
    
    for row in csv_reader:
        doi = row[2].strip()
        pmc = row[1]
        name = row[0]
        listdois[doi] = True
            
        metadata = get_metadata(doi)

        if metadata:
            cur.execute("insert or ignore into articles (doi, pmc, name) values (?, ?, ?)", (doi, pmc, name))

        time.sleep(0.1)

f = []
i = 0

for (dirpath, dirnames, filenames) in walk(path):
    for filename in filenames:
        print(filename)
        filename = path + "/" + filename

        reader = csv.DictReader(open(filename, 'r', encoding="utf-8"))
        for row in reader:
            
            source = row["citing"].strip()
            target = row["cited"].strip()
            
            year = row["creation"].strip().split("-")[0]

            if source in listdois or target in listdois:
                cur.execute("insert or ignore into cites (doi_source, doi_target, year) values (?,?,?)", (source, target, year))
                
            i = i + 1

            if i % 100000 == 0:
                print(i)

        con.commit()
