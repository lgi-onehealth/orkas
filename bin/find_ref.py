"""
Given a list of FASTQ files, and a list of reference sequences,
use mash to calculate the distance, and then find the closest 
reference sequence to the FASTQ files. Return the path to the 
closest reference sequence.
"""

import argparse
import asyncio
import pathlib
import re
import urllib.request

# WEBENV = re.compile(r'<WebEnv>(\S+)</WebEnv>')
# KEY = re.compile(r'<QueryKey>(\d+)</QueryKey>')
# ASM_RELEASE_DATE_GENBANK = re.compile('<AsmReleaseDate_GenBank>(\S+_</AsmReleaseDate_GenBank>')
# ASM_RELEASE_DATE_REFSEQ = re.compile('<AsmReleaseDate_RefSeq>(\S+)</AsmReleaseDate_RefSeq>')


def parse_args():
    """
    Parse the command line arguments.
    """
    parser = argparse.ArgumentParser(description="Find the closest reference sequence to a set of FASTQ files.")
    parser.add_argument("-f", "--fastq", nargs="+", help="FASTQ files to compare to the reference sequences.", required=True, type=pathlib.Path)
    parser.add_argument("-r", "--ref", nargs="+", help="Reference sequences to compare the FASTQ files to.", required=True, type=pathlib.Path)
    parser.add_argument("-t", "--threads", help="Number of threads to use.", default=1, type=int)
    parser.add_argument("-e", "--email", help="Email address to use for Entrez.", default="andersgs+entrez@gmail.com")
    return parser.parse_args()


async def run_mash(reads, ref):
    """
    Run mash.
    """
    cmd = f"mash dist {ref} {' '.join([str(r) for r in reads])}"
    proc = await asyncio.create_subprocess_shell(
        cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    stdout, _ = await proc.communicate()
    return stdout.decode('utf-8')


# async def search_entrez(term, email):
#     """
#     Search Entrez for a term.
#     """
#     base = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/'
#     db = 'assembly'
#     url = f"{base}esearch.fcgi?db={db}&term={term}&usehistory=y"
#     request = urllib.request.urlopen(url)
#     data = request.read().decode('utf-8')
#     webenv = WEBENV.search(data).group(1)
#     key = KEY.search(data).group(1)
#     url = base + f"esummary.fcgi?db={db}&query_key={key}&WebEnv={webenv}"


async def safe_mash(reads, ref, sem):
    """
    Add mash to the task quey using semaphore  to limit the number of threads.
    """
    async with sem:
        return await run_mash(reads, ref)


async def main():
    """
    Main function.
    """
    args = parse_args()
    sem = asyncio.Semaphore(args.threads)
    fastq_files = args.fastq
    ref_files = args.ref
    tasks = [
        asyncio.ensure_future(safe_mash(fastq_files, ref, sem)) for ref in ref_files
    ]
    results = await asyncio.gather(*tasks)
    dists = []
    for result in results:
        data = [res.split("\t") for res in result.strip().split("\n")]
        mean_dist = sum([float(d[2]) for d in data]) / len(data)
        dists.append([data[0][0], mean_dist])
    sorted(dists, key=lambda x: x[1])
    min_mean_dist = dists[0][1]
    suitable_refs = [d[0] for d in dists if d[1] == min_mean_dist]
    if len(suitable_refs) > 1:
        print(f"Multiple reference sequences found with the same distance to the FASTQ files. Please check the reference sequences.")
    print(suitable_refs)


if __name__ == "__main__":
    asyncio.run(main())
