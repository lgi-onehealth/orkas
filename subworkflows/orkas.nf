// load subworkflows
include { REFERENCE_PREPROCESSING } from '../reference_preprocessing/main'


workflow ORKAS {
    take:
        data
        reference
        is_complete
        chromosome_id
        kraken_db
    main:
        REFERENCE_PREPROCESSING(reference, is_complete, chromosome_id)
        READS_QC(data)
        SPECIATION(QC.out.corrected_reads, kraken_db, false, false)
        ASSEMBLY(QC.out.reads)
        TYPING(ASSEMBLY.out.assembly)
        VARIANT_DETECTION(QC.out.reads, REFERENCE_PREPROCESSING.out.reference)
        CREATE_MASKS(VARIANT_DETECTION.out.bams,  REFERENCE_PREPROCESSING.out.reference)
        ALIGN(VARIANT_DETECTION.out.variants, REFERENCE_PREPROCESSING.out.reference, CREATE_MASKS.out.mask)
        TREE_BUILD(ALIGN.out.alignment)
}