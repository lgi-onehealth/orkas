"""
Given a Google bucket and a list of sample IDs, generate a CSV file with 
sample ID, read1, and read2 path in the GS bucket.
"""

import argparse
import pathlib
from collections import defaultdict
from typing import List
from google.cloud import storage as gcs

def parse_args():
    """
    Parse command line arguments.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bucket', required=True,
                        help='Google bucket name', type=str)
    parser.add_argument('--path-prefix', help="Path prefix in the bucket", 
                        default='fastq/', type=str)
    parser.add_argument('--sample-ids', required=True,
                        help='List of sample IDs', type=pathlib.Path)
    parser.add_argument('--output', required=True,
                        help='Output file', type=str)
    return parser.parse_args()


def get_list_of_sample_ids(sample_ids_file: pathlib.Path) -> List[str]:
    """
    Get list of sample IDs from a file.
    """
    with open(sample_ids_file) as f:
        sample_ids = f.read().splitlines()
    return sample_ids


def get_list_of_sample_paths(bucket: str, sample_ids: List[str], path_prefix:str) -> defaultdict:
    """
    Instantiate a bucket instance, list all the files in the bucket, and then
    match them up to the sample IDs.
    """
    client = gcs.Client()
    bucket = client.get_bucket(bucket)
    blobs = bucket.list_blobs(prefix=path_prefix)
    sample_paths = defaultdict(list)
    for blob in blobs:
        # a blob name will look like this 'fastq/SA20210341_S27_L001_R2_001.fastq.gz
        # and we want to extract the sample ID from the filename
        sid = blob.name.split('/')[-1].split('_')[0]
        if sid in sample_ids:
            sample_paths[sid].append(f"gs://{blob.bucket.name}/{blob.name}")
    return sample_paths

def create_samplesheet(sample_paths: defaultdict, output_file: str):
    """
    Create a CSV file with sample ID, read1, and read2 path.
    """
    with open(output_file, 'w') as f:
        for sample_id, paths in sample_paths.items():
            paths = sorted(paths)
            f.write(f'{sample_id},{paths[0]},{paths[1]}\n')

def main():
    args = parse_args()
    sample_ids = get_list_of_sample_ids(args.sample_ids)
    sample_paths = get_list_of_sample_paths(args.bucket, sample_ids, args.path_prefix)
    create_samplesheet(sample_paths, args.output)


if __name__ == "__main__":
    main()