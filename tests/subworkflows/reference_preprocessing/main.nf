include { REFERENCE_PREPROCESSING } from '../../../subworkflows/reference_preprocessing/main'

workflow test_reference_preprocessing {

    reference = "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/016/889/925/GCF_016889925.1_ASM1688992v1/GCF_016889925.1_ASM1688992v1_genomic.gbff.gz"
    is_complete = true
    chromosome_id = "NZ_CP069563"

    REFERENCE_PREPROCESSING(reference, is_complete, chromosome_id)
}