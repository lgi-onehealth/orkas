import argparse
import csv
import datetime
import pathlib
from typing import List, Dict
import psycopg

# with psycopg.connect("dbname=onetrakr user=andersgs") as conn:
#     with conn.cursor() as cur:
#         cur.execute("""
#             CREATE TABLE test (
#                 id SERIAL PRIMARY KEY,
#                 name VARCHAR(255) NOT NULL,
#                 num INT NOT NULL,
#                 data VARCHAR(255) NOT NULL
#                 )""")

#         cur.execute("INSERT INTO test (name, num, data) VALUES (%s, %s, %s)",
#             ('test1', 1, 'this is a test'),
#         )

#         conn.commit()

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file', type=pathlib.Path, required=True)
    return parser.parse_args()

def parse_txt(filename: pathlib.Path) -> List[Dict]:
    with open(filename, 'r') as f:
        reader = csv.DictReader(f)
        return [row for row in reader]

def clean_values(data: List[Dict]) -> List[Dict]:
    for row in data:
        for key, value in row.items():
            if value == '':
                row[key] = None
            if "date" in key.lower():
                row[key] = None
                for fmt in ("%Y", "%Y-%m", "%Y-%m-%d","%Y-%m-%dT%H:%M:%SZ"):
                    try:
                        row[key] = datetime.datetime.strptime(value, fmt)
                        break
                    except ValueError:
                        pass
                # if row[key] is None and value != '':
                #     print("Could not parse date: {}".format(value))
    return data

def create_table(data: List[Dict]):
    with psycopg.connect("dbname=onetrakr user=andersgs") as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE sradata (
                    id SERIAL PRIMARY KEY
                    )""")

            header = data[0].keys()
            fields = []
            for field in header:
                print("Adding field: {}".format(field))
                if field == "sample_name":
                    field = "sample_name2"
                if field == "sub-species":
                    field = "sub_species2"
                if field == "subspecies":
                    field = "sub_species3"
                if field == "host-disease":
                    field = "host_disease2"
                if field == "collected-by":
                    field = "collected_by2"
                if field == "isolation-source":
                    field = "isolation_source2"
                field = field.lower().replace(' ', '_').replace('(', '').replace(')', '').replace('-', '_').replace("+", "plus").replace("/", "_").replace("#", "num")
                fields.append(field)
                if "date" in field.lower():
                    cur.execute("ALTER TABLE sradata ADD COLUMN {} DATE".format(field))
                elif field.lower() == 'avgspotlen':
                    cur.execute("ALTER TABLE sradata ADD COLUMN {} INT".format(field))
                elif field.lower() == 'bases':
                    cur.execute("ALTER TABLE sradata ADD COLUMN {} BIGINT".format(field))
                else:
                    cur.execute("ALTER TABLE sradata ADD COLUMN {} VARCHAR(255)".format(field))

            for row in data:
                cur.execute("INSERT INTO sradata ({}) VALUES ({})".format(
                    ', '.join(fields),
                    ', '.join(["%s"] * len(header))
                ), list(row.values()))
            conn.commit()

def main():
    args = parse_args()
    data = parse_txt(args.file)
    data = clean_values(data)
    create_table(data)

if __name__ == "__main__":
    main()