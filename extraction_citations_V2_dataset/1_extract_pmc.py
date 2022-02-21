import os
import json 
import csv
import re

##### This script creates an extract of ALL pmc identifiers from the CORD19 dataset.
##### Input of this script is a directory path, specified in the path variable below.
##### Output is the combination of article titles and PMC IDs.
##### Article titles are included for verification and clarity.

# Path to pmc_json folder of the CORD19 dataset.
path = 'pmc_json'

outfile = "pmc_articlenames.csv"

with open(outfile, mode='w', encoding="utf-8", newline='') as out:
    writer = csv.writer(out, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)

    writer.writerow(
        [
            "title",
            "pmcid"
        ]
    )

    for root, dirs, files in os.walk(path):
        for file in files:
            f = open(path + '\\' + file, "r")
            contents = f.read()
            parsed = json.loads(contents)

            title = parsed["metadata"]["title"].strip()
            id = parsed["paper_id"]
            re.sub('\s+',' ', title)

            if title == "":
                continue

            writer.writerow(
                [
                    title,
                    id
                ]
            )