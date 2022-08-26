"""
Read a number of TSV files outputted by Bracken and merge them into a single CSV file.

The input files are expected to be in the following format:
name    taxonomy_id     taxonomy_lvl    kraken_assigned_reads   added_reads     new_est_reads   fraction_total_reads
Salmonella enterica     28901   S       263623  947313  1210936 0.99888
Salmonella bongori      54736   S       486     7       493     0.00041
Salmonella sp. SSDFZ69  2500543 S       28      110     138     0.00011

We are taking only the first data row for each sample.

The filename will have the sample_id and will need to be parsed to get the sample ID:

    {sample_id}_S.tsv

The output CSV will have the following columns:
sample_id,organism,n_assigned_reads,fraction_total_reads

"""

import argparse
import csv


def parse_args():
    parser = argparse.ArgumentParser(description="Merge Bracken TSV files")
    parser.add_argument("input_files", nargs="+", help="Input files")
    parser.add_argument("--output-file", default="bracken.csv", help="Output file")
    return parser.parse_args()


def parse_bracken_output(input_file):
    """
    Parse the output of Bracken
    """
    sample_id = input_file.split("/")[1].split("_")[0]
    with open(input_file, "r") as f:
        lines = f.readlines()
        # skip the header line
        line = lines[1].strip().split("\t")
        organism = line[0]
        n_assigned_reads = int(line[5])
        fraction_total_reads = float(line[6])
    return sample_id, organism, n_assigned_reads, fraction_total_reads


def main():
    args = parse_args()
    with open(args.output_file, "w") as f:
        writer = csv.writer(f)
        writer.writerow(["sample_id", "organism", "n_assigned_reads", "fraction_total_reads"])
        for input_file in args.input_files:
            sample_id, organism, n_assigned_reads, fraction_total_reads = parse_bracken_output(input_file)
            writer.writerow([sample_id, organism, n_assigned_reads, fraction_total_reads])


if __name__ == """__main__""":
    main()