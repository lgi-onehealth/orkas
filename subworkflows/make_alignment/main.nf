// align imports
include { BCFTOOLS_INDEX } from '../../modules/nf-core/modules/bcftools/index/main'
include { BCFTOOLS_CONSENSUS } from '../../modules/nf-core/modules/bcftools/consensus/main'
include { GOALIGN_APPEND } from '../../modules/local/goalign/append'
include { GOALIGN_REPLACE } from '../../modules/local/goalign/replace'
include { GOALIGN_CLEANSITES } from '../../modules/local/goalign/cleansites'

workflow MAKE_ALIGNMENT {
    take:
        vcf
        reference
        mask
    main:
        BCFTOOLS_INDEX(vcf)
        // create the input channel necessary for BCFTOOLS_CONSENSUS
        vcf_consensus_ch = vcf.cross(BCFTOOLS_INDEX.out.csi) {it -> it[0].id}.map {
            def meta = it[0][0]
            def vcf = it[0][1]
            def csi =  it[1][1]
            return [meta, vcf, csi]
        }.cross(mask) {it -> it[0].id}.map {
            def meta = it[0][0]
            def vcf = it[0][1]
            def csi =  it[0][2]
            def mask = it[1][1]
            return [meta, vcf, csi, mask]
        }
        BCFTOOLS_CONSENSUS(vcf_consensus_ch, reference)
        // merge the output of the consensus step to create a single multiFASTA file
        consensus_seqs_ch = BCFTOOLS_CONSENSUS.out.fasta.map{seq -> seq[1]}.collect()
        GOALIGN_APPEND(reference, consensus_seqs_ch)
        // replace non ACGTacgt characters with -
        GOALIGN_REPLACE(GOALIGN_APPEND.out.fasta)
        // remove columns with more than 0% of gaps
        GOALIGN_CLEANSITES(GOALIGN_REPLACE.out.fasta)

    emit:
        alignment = CLIPKIT.out.fasta
}
