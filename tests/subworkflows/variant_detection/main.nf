#!/usr/bin/env nextflow

include { VARIANT_DETECTION } from '../../../subworkflows/variant_detection/main.nf';
workflow test_variant_detection {

    reads = [ [ id:'test_1', single_end:false ], // meta map
              [file("ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR527/000/SRR5276050/SRR5276050_1.fastq.gz", checkIfExists: true),
               file("ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR527/000/SRR5276050/SRR5276050_2.fastq.gz", checkIfExists: true)
               ],
               []
            ];
    ref = file("https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/016/889/925/GCF_016889925.1_ASM1688992v1/GCF_016889925.1_ASM1688992v1_genomic.gbff.gz", checkIfExists: true);

    VARIANT_DETECTION(reads, ref)
}