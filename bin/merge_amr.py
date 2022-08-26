"""
Merge NCBI AMR FinderPlus output files into a sigle large CSV file.

We will need to parse each file and generate a unique list of genes across all files.

This will form the first header row of the output CSV.

For each gene we will also capture the Class of antibiotic resistance, and that will form the second header row.

For each row of the output CSV file we will have the presence/absence of the gene in the sample. 
To be present, and gene must have at least 95% coverage and 95% identity to the gene in the database.

"""

import argparse
import csv
from collections import defaultdict
from typing import List, Tuple


def parse_args():
    parser = argparse.ArgumentParser(description="Merge AMR FinderPlus TSV files")
    parser.add_argument("input_files", nargs="+", help="Input files")
    parser.add_argument("--output-file", default="amr.csv", help="Output file")
    return parser.parse_args()


def parse_amr_output(input_file: str, min_coverage: float = 95.0, min_identity: float = 95.0) -> List[dict]:
    """
    Parse the output of AMR FinderPlus
    """
    result = []
    with open(input_file, "r") as f:
        for i,line in enumerate(f):
            if i == 0:
                # skip the header line
                continue
            line = line.strip().split("\t")
            sample_id = line[0]
            gene_symb = line[6]
            class_of_resistance = line[11]
            coverage = float(line[16])
            identity = float(line[17])
            if coverage >= min_coverage and identity >= min_identity:
                result.append({"sample_id": sample_id, "gene_symb": gene_symb, "class_of_resistance": class_of_resistance})
    return result


def merge_results(results: List[dict]) -> Tuple[dict,dict]:
    """
    Merge the results from multiple files into a single list of genes
    """
    genes = defaultdict(list)
    classes = {}
    for result in results:
        genes[result["gene_symb"]].append(result['sample_id'])
        if classes.get(result['gene_symb']) is None:
            classes[result['gene_symb']] = result['class_of_resistance']
    return genes, classes


def main():
    args = parse_args()
    results = []
    samples = []
    for input_file in args.input_files:
        samples.append(input_file.split("/")[1].split("_")[0])
        results.extend(parse_amr_output(input_file))
    genes, classes = merge_results(results)
    gene_symbs = sorted(list(genes.keys()))
    class_header = [" "] + [classes[g] for g in gene_symbs]
    samples = sorted(samples)
    with open(args.output_file, "w") as f:
        writer = csv.writer(f)
        writer.writerow(["sample_id"] + gene_symbs)
        writer.writerow(class_header)
        for sample in samples:
            writer.writerow([sample] + ["TRUE" if sample in genes[g] else 'FALSE' for g in gene_symbs])


if __name__ == "__main__":
    main()