#!/usr/bin/env nextflow

include { REFERENCE_PREPROCESSING } from '../../../subworkflows/reference_preprocessing/main'
include { MAKE_ALIGNMENT } from '../../../subworkflows/make_alignment/main.nf'

workflow test_make_alignment {

    // setup the reference
    reference = "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/016/889/925/GCF_016889925.1_ASM1688992v1/GCF_016889925.1_ASM1688992v1_genomic.gbff.gz"
    is_complete = true
    chromosome_id = "NZ_CP069563"

    // vcf input
    vcf = Channel.from([[
        [id: 'test1'], file(params.test_data['vcfs']['test1'], checkIfExists: true)
    ]])
    //mask input
    mask =Channel.from([[
        [id: 'test1'], file(params.test_data['masks']['test1'], checkIfExists: true)
    ]])

    REFERENCE_PREPROCESSING(reference, is_complete, chromosome_id)
    MAKE_ALIGNMENT(vcf, REFERENCE_PREPROCESSING.out.reference_chrom, mask)

}