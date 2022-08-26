"""
Given a list of text files, parse them, and output a single CSV file

Each input text file will look like this:
Total reads: 1,217,028
Total bases: 294,902,507
Min read len: 35
Max read len: 251
Mean Q score: 35.21
Total kmers: 18,325,323
Total count: 270,558,407
Total unique: 4,805,405
Elapsed time: 42.171 seconds
Processing rate: 28859.36 reads/second

Each input file will have a name that includes the sample ID, and we need to parse the sample ID from the file name:
path/to/{sample_id}.phcue.txt

Each row of the output CSV file will look like this:
sample_id,total_reads,total_bases,min_read_len,max_read_len,mean_q_score,total_kmers,total_count,exp_genome_size,exp_cov
"""

import argparse
import csv

def parse_args():
    parser = argparse.ArgumentParser(description="Merge phcue files")
    parser.add_argument("input_files", nargs="+", help="Input files")
    parser.add_argument("--output-file", default="phcue.csv", help="Output file")
    return parser.parse_args()

def parse_phcue_output(input_file):
    """
    Parse the output of phcue
    """
    with open(input_file, "r") as f:
        lines = f.readlines()
        total_reads = int(lines[0].split(":")[1].strip().replace(",", "")) * 2
        total_bases = int(lines[1].split(":")[1].strip().replace(",", "")) * 2
        min_read_len = int(lines[2].split(":")[1].strip().replace(",", ""))
        max_read_len = int(lines[3].split(":")[1].strip().replace(",", ""))
        mean_q_score = float(lines[4].split(":")[1].strip())
        total_kmers = int(lines[5].split(":")[1].strip().replace(",", ""))
        total_count = int(lines[6].split(":")[1].strip().replace(",", ""))
        total_unique = int(lines[7].split(":")[1].strip().replace(",", ""))
        exp_cov = total_bases / total_unique
    return total_reads, total_bases, min_read_len, max_read_len, mean_q_score, total_kmers, total_count, total_unique,exp_cov

def main():
    args = parse_args()
    with open(args.output_file, "w") as f:
        writer = csv.writer(f)
        writer.writerow(["sample_id", "total_reads", "total_bases", "min_read_len", "max_read_len", "mean_q_score", "total_kmers", "total_count", "exp_genome_size", "exp_cov"])
        for input_file in args.input_files:
            sample_id = input_file.split("/")[-1].split(".")[0]
            total_reads, total_bases, min_read_len, max_read_len, mean_q_score, total_kmers, total_count, total_unique, exp_cov = parse_phcue_output(input_file)
            writer.writerow([sample_id, total_reads, total_bases, min_read_len, max_read_len, mean_q_score, total_kmers, total_count, total_unique, f"{exp_cov:.2f}"])


if __name__ == "__main__":
    main()