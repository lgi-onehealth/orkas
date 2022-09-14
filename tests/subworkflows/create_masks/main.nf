#!/usr/bin/env nextflow

include { REFERENCE_PREPROCESSING } from '../../../subworkflows/reference_preprocessing/main';
include { CREATE_MASKS } from '../../../subworkflows/create_masks/main.nf';

workflow test_create_masks {

    scale = 1;
    bam = [ [ id:'SRR5276050', single_end:false ], // meta map
              file(params.test_data['bams']['SRR5276050'], checkIfExists: true),
              scale
            ];

    reference = file("https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/016/889/925/GCF_016889925.1_ASM1688992v1/GCF_016889925.1_ASM1688992v1_genomic.gbff.gz", checkIfExists: true);
    is_complete = true
    chromosome_id = "NZ_CP069563"

    filter_min = 1;

    println ("bam: ${bam}")
    REFERENCE_PREPROCESSING(reference, is_complete, chromosome_id)
    CREATE_MASKS(bam, REFERENCE_PREPROCESSING.out.reference, filter_min)
}
