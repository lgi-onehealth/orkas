// TODO: ADD SPECIATION WORKFLOW WITH KRAKEN2
// TODO: BRING SPECIES INTO THE META DATA TO INFORM DOWNSTREAM TYPING
// load nf-core modules

// align imports
include { BCFTOOLS_CONSENSUS } from '../modules/nf-core/modules/bcftools/consensus/main'
// tree building imports
include { IQTREE } from '../modules/nf-core/modules/iqtree/main'
include { GOALIGN_APPEND } from '../modules/local/goalign/append'

workflow ALIGN {
    take:
        vcf
        reference
        mask
    main:
        // filter out only the choromosome for the alignment
        // this won't work for draft assemblies
        ref_ch = Channel.fromPath(reference)
             .splitFasta(record: [id: true, desc: true, seqString: true])
             .filter { record -> record.desc =~ /chromosome/ }
             .map { record -> '>' + record.id + '\n' + record.seqString }
             .collectFile(name: "ref.fasta")
        BCFTOOLS_INDEX(vcf)
        // create the input channel necessary for BCFTOOLS_CONSENSUS
        vcf_consensus_ch = vcf.cross(BCFTOOLS_INDEX.out.csi) {it -> it[0].id}.map {
            def meta = it[0][0]
            def vcf = it[0][1]
            def csi =  it[1][1]
            return [meta, vcf, csi]
        }.combine(ref_ch).cross(mask) {it -> it[0].id}.map {
            def meta = it[0][0]
            def vcf = it[0][1]
            def csi =  it[0][2]
            def ref = it[0][3]
            def mask = it[1][1]
            return [meta, vcf, csi, ref, mask]
        }
        BCFTOOLS_CONSENSUS(vcf_consensus_ch)
        // merge the output of the consensus step to create a single multiFASTA file
        // TODO: IMPROVE THIS STEP - PUT IT IN A MODULE OF ITS OWN AND ADD THE REFERENCE
        align_fa = BCFTOOLS_CONSENSUS.out.fasta.map{meta, fasta -> {
            def seq = fasta.text.split("\n")
            def seq_str = seq[1..-1].join("\n")
            def header = ">" + meta.id + "\n"
            return header+seq_str+"\n"
            }
        }.collectFile(name: "align_subs.fa", storeDir: "$params.outdir")
    emit:
        alignment = align_fa
        reference = ref_ch
}

workflow TREE_BUILD {
    take:
        alignment
        reference
    main:
        GOALIGN_APPEND(alignment, reference)
        IQTREE(GOALIGN_APPEND.out.alignment, [])
}

workflow ONE_FLOW {
    take:
        data
        reference
        kraken_db
    main:
        QC(data)
        SPECIATION(QC.out.corrected_reads, kraken_db, false, false)
        ASSEMBLY(QC.out.reads)
        TYPING(ASSEMBLY.out.assembly)
        VARIANT_DETECTION(QC.out.reads, reference)
        CREATE_MASKS(VARIANT_DETECTION.out.bams, reference)
        ALIGN(VARIANT_DETECTION.out.variants, reference, CREATE_MASKS.out.mask)
        TREE_BUILD(ALIGN.out.alignment, ALIGN.out.reference)
}