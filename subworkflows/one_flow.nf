// load subworkflows
include { REFERENCE_PREPROCESSING } from '../reference_preprocessing/main'


workflow ONE_FLOW {
    take:
        data
        reference
        is_complete
        chromosome_id
        kraken_db
    main:
        REFERENCE_PREPROCESSING(reference, is_complete, chromosome_id)
        QC(data)
        SPECIATION(QC.out.corrected_reads, kraken_db, false, false)
        ASSEMBLY(QC.out.reads)
        TYPING(ASSEMBLY.out.assembly)
        VARIANT_DETECTION(QC.out.reads, reference)
        CREATE_MASKS(VARIANT_DETECTION.out.bams, reference)
        ALIGN(VARIANT_DETECTION.out.variants, reference, CREATE_MASKS.out.mask)
        TREE_BUILD(ALIGN.out.alignment, ALIGN.out.reference)
}