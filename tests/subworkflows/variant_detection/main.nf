#!/usr/bin/env nextflow

include { REFERENCE_PREPROCESSING } from '../../../subworkflows/reference_preprocessing/main';
include { VARIANT_DETECTION } from '../../../subworkflows/variant_detection/main';

workflow test_variant_detection {

    reads = [ [ id:'SRR5276050', single_end:false ], // meta map
              [file("ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR527/000/SRR5276050/SRR5276050_1.fastq.gz", checkIfExists: true),
               file("ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR527/000/SRR5276050/SRR5276050_2.fastq.gz", checkIfExists: true)
               ],
               []
            ];
    
    reference = file("https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/016/889/925/GCF_016889925.1_ASM1688992v1/GCF_016889925.1_ASM1688992v1_genomic.gbff.gz", checkIfExists: true);
    is_complete = true
    chromosome_id = "NZ_CP069563"

    REFERENCE_PREPROCESSING(reference, is_complete, chromosome_id)
    VARIANT_DETECTION(reads, REFERENCE_PREPROCESSING.out.reference, params.var_detection_mode)
}