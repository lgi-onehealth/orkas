
// nf-core imports
include { BEDTOOLS_GENOMECOV } from '../modules/nf-core/modules/bedtools/genomecov/main'
include { BEDTOOLS_MERGE } from '../modules/nf-core/modules/bedtools/merge/main'
include { MINIMAP2_ALIGN } from '../modules/nf-core/modules/minimap2/align/main'


workflow CREATE_MASKS {
    take:
        bam
        reference
        filter_min
    main:
    //TODO: MAKE FILTER_MIN A WORKFLOW PARAMETER
        scale = 1
        filter_min = 10
        // create the appropriate channel for bedtools process
        bedtools_ch = bam.map {meta, bam ->
                return [meta, bam, scale]
            }
        BEDTOOLS_GENOMECOV(bedtools_ch, [], 'bed', filter_min)
        // need this step to avoid name collision in the minimap step
        query_ref = Channel.fromPath(reference).collectFile(name: 'query_reference.fasta').collect().map {it -> [[id: 'ref', single_end:true], it]}
        MINIMAP2_ALIGN(query_ref, reference, false, false, false, true)
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