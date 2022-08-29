# Test data

## FASTQ

The FASTQ data of choice for testing was a small data set consisting of PE reads
of _Mycoplasma pneumoniae_, which was sequenced with the Illumina MiSeq platform. 
We chose the dataset because the genome is small and the data is also relatively small
allowing for relatively fast testing, but still relatively real data size. Also, the 
read lenghts should be long enough to allow for some good overlap between reads.

More information on the data can be found on SRA [here](https://trace.ncbi.nlm.nih.gov/Traces/index.html?view=run_browser&acc=DRR040053&display=metadata).

Data was downloaded from SRA and placed in the `fastq` directory with:

```bash
docker run --rm -it lighthousegenomics/phcue-ck phcue-ck -a DRR040053 \
        | grep -Eo '"url": "[^"]*"' \
        | grep -o '"[^"]*"$' \
        | xargs -n1 curl -O
```