
// nf-core imports
include { BEDTOOLS_GENOMECOV } from '../../modules/nf-core/modules/bedtools/genomecov/main'
include { BEDTOOLS_MERGE } from '../../modules/nf-core/modules/bedtools/merge/main'
include { MINIMAP2_ALIGN } from '../../modules/nf-core/modules/minimap2/align/main'


workflow CREATE_MASKS {
    take:
        bam
        reference
        filter_min
    main:

        BEDTOOLS_GENOMECOV(bam, [], 'bed', filter_min)
        // need this step to avoid name collision in the minimap step
        MINIMAP2_ALIGN(reference, reference, false, false, false, true)
        // merge the bed files to create a single mask BED for each sample that 
        // both masks low coverage areas as well as repeat regions in the reference
        // genome
        single_bed_ch = BEDTOOLS_GENOMECOV.out.genomecov.combine(MINIMAP2_ALIGN.out.bed).map {meta, cov_bed, repeat_bed -> {
            return [meta, [cov_bed, repeat_bed]]
        }}
        BEDTOOLS_MERGE(single_bed_ch)
    emit:
        mask = BEDTOOLS_MERGE.out.bed
}