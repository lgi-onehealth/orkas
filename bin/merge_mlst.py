"""
Take a list of TSV files outputted from MLST and merge them into a single CSV file.

Each input TSV file will look like this:

SA20156567_unicycler.scaffolds.fa.gz    senterica_achtman_2     10      aroC(5) dnaN(2) hemD(3) hisD(6) purE(5) sucA(5) thrA(10)

The first column needs to be parsed to get the sample ID:
{sample_id}_remainder

The second column is the MLST scheme name

The third column is the MLST ST number

The remaing columns are the MLST alleles, and need to be joined together into a single string, separated by a semi-colon.

The output CSV file will look like this:
sample_id,scheme_name,st_number,alleles
"""

import argparse
import csv

def parse_args():
    parser = argparse.ArgumentParser(description="Merge MLST TSV files")
    parser.add_argument("input_files", nargs="+", help="Input files")
    parser.add_argument("--output-file", default="mlst.csv", help="Output file")
    return parser.parse_args()


def parse_mlst_file(input_file):
    """
    Parse the output of MLST
    """
    with open(input_file, "r") as f:
        lines = f.readlines()
        line = lines[0].strip().split("\t")
        sample_id = line[0].split("_")[0]
        scheme_name = line[1]
        st_number = line[2]
        alleles = ";".join(line[3:])
    return sample_id, scheme_name, st_number, alleles


def main():
    args = parse_args()
    with open(args.output_file, "w") as f:
        writer = csv.writer(f)
        writer.writerow(["sample_id", "scheme_name", "st_number", "alleles"])
        for input_file in args.input_files:
            sample_id, scheme_name, st_number, alleles = parse_mlst_file(input_file)
            writer.writerow([sample_id, scheme_name, st_number, alleles])


if __name__ == "__main__":
    main()