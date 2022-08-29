// A short read QC workflow
// 
// The workflow is as follows:
//  1. Basic statistics are calculated for each readset using phcue-qc, including expected genome
//     coverage and size. The genome size is used in the next step for read correction with Lighter.
//  2. Read correct with Lighter.
//  3. Use FASTP to trim, filter, remove adapter sequences and merge overlapping reads.

// nf-core imports
include { FASTP } from '../../modules/nf-core/modules/fastp/main'

// load local modules
include { PHCUE } from '../../modules/local/phcue'
include { LIGHTER } from '../../modules/local/lighter'

println("${params.test_data}")

workflow READS_QC {
    take:
        data
    main:
        save_trimmed_fail = false
        save_merged       = true
        PHCUE(data)
        raw_reads_ch = PHCUE.out.reads.cross(PHCUE.out.genome_size) {meta, data -> meta.id}.map {
            it -> {
                def meta = it[0][0]
                def reads = it[0][1]
                def genome_size = it[1][1]
                meta.genome_size = genome_size
                return [meta, reads]
            }
        }
        LIGHTER(raw_reads_ch)
        FASTP(LIGHTER.out.corrected_reads, save_trimmed_fail, save_merged)
        reads_ch = FASTP.out.reads.cross(FASTP.out.reads_merged) {
            it -> it[0].id
            }.map {
                it -> {
                    def meta = it[0][0]
                    def reads = it[0][1]
                    def reads_merged = it[1][1]
                    return [meta, reads, [reads_merged]]
                }
            }
    emit:
        reads = reads_ch
        corrected_reads = LIGHTER.out.corrected_reads
}
