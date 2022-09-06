
include { KRAKEN2_KRAKEN2 } from '../modules/nf-core/modules/kraken2/kraken2/main'
include { BRACKEN_BRACKEN } from '../modules/nf-core/modules/bracken/bracken/main'


workflow SPECIATION {
    take:
        reads
        db
        save_output_fastqs
        save_reads_assignment
    main:
        KRAKEN2_KRAKEN2(reads, db, save_output_fastqs, save_reads_assignment)
        BRACKEN_BRACKEN(KRAKEN2_KRAKEN2.out.report, db)
    emit:
        kraken2 = KRAKEN2_KRAKEN2.out.report
        bracken = BRACKEN_BRACKEN.out.reports
}