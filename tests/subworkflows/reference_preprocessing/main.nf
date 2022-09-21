include { REFERENCE_PREPROCESSING } from '../../../subworkflows/reference_preprocessing/main'

workflow test_reference_preprocessing {

    reference = params.reference
    is_complete = params.ref_is_complete
    chromosome_id = params.chromosome_id

    REFERENCE_PREPROCESSING(reference, is_complete, chromosome_id)
}