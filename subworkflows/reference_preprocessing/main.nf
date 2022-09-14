// Process reference files and output a reference as a tuple 
// with metadata data, a FASTA, and the index

include { ANY2FASTA } from '../../modules/local/any2fasta'
include { SAMTOOLS_FAIDX as INDEX } from '../../modules/nf-core/modules/samtools/faidx/main'
include { SAMTOOLS_FAIDX as INDEX_CHROM } from '../../modules/nf-core/modules/samtools/faidx/main'
include { SAMTOOLS_FAIDX as FILTER } from '../../modules/nf-core/modules/samtools/faidx/main'


workflow REFERENCE_PREPROCESSING {
    take:
        reference
        is_complete
        chromosome_id
    main:
        ref_chrom = []
        ANY2FASTA(reference)
        ref_ch = ANY2FASTA.out.fasta.map { fasta -> 
        tuple(
            [id: "reference", is_complete: is_complete, chromosome_id: chromosome_id], 
            fasta) 
        }
        INDEX(ref_ch, [], [], [])
        if (is_complete) {
            FILTER(ref_ch, chromosome_id, [], [])
            INDEX_CHROM(FILTER.out.fasta, [], [], [])
            ref_chrom = FILTER.out.fasta.cross(INDEX_CHROM.out.fai) {it -> it[0].id} .map(it ->
            tuple(
                [id: "reference_chrom", is_complete: is_complete, chromosome_id: chromosome_id], 
                it[0][1], 
                it[1][1])
            )
        }
        ref_ch = ref_ch.cross(INDEX.out.fai) { it -> it[0].id }.map( it -> 
        tuple(
            [id: "reference", is_complete: is_complete, chromosome_id: chromosome_id], 
            it[0][1], 
            it[1][1]) 
        )

    emit:
        reference  = ref_ch 
        reference_chrom = ref_chrom 
}