// Process reference files and output a reference as a tuple 
// with metadata data, a FASTA, and the index

include { ANY2FASTA } from '../../modules/local/any2fasta'
include { SAMTOOLS_FAIDX } from '../../modules/nf-core/modules/samtools/faidx/main'


workflow REFERENCE_PREPROCESSING {
    take:
        reference
        is_complete
        chromosome_id
    main:
        ANY2FASTA(reference)
        ref_ch = ANY2FASTA.out.fasta.map { fasta -> 
        tuple(
            [id: "reference", is_complete: is_complete, chromosome_id: chromosome_id], 
            fasta) 
        }
        SAMTOOLS_FAIDX(ref_ch)
        ref_ch = ref_ch.cross(SAMTOOLS_FAIDX.out.fai) { it -> it[0].id }.map( it -> 
        tuple(
            [id: "reference", is_complete: is_complete, chromosome_id: chromosome_id], 
            it[0][1], 
            it[1][1]) 
        )

    emit:
        reference  = ref_ch 
}