// TODO: ADD SPECIATION WORKFLOW WITH KRAKEN2
// TODO: BRING SPECIES INTO THE META DATA TO INFORM DOWNSTREAM TYPING
// load nf-core modules
// typing imports
include { MLST } from '../modules/nf-core/modules/mlst/main'
include { SISTR } from '../modules/nf-core/modules/sistr/main'
include { AMRFINDERPLUS_UPDATE } from '../modules/nf-core/modules/amrfinderplus/update/main'
include { AMRFINDERPLUS_RUN } from '../modules/nf-core/modules/amrfinderplus/run/main'
// speciation imports
include { KRAKEN2_KRAKEN2 } from '../modules/nf-core/modules/kraken2/kraken2/main'
include { BRACKEN_BRACKEN } from '../modules/nf-core/modules/bracken/bracken/main'
// variant detection imports
include { BOWTIE2_BUILD } from '../modules/nf-core/modules/bowtie2/build/main'
include { BOWTIE2_ALIGN } from '../modules/nf-core/modules/bowtie2/align/main'
include { SAMTOOLS_FAIDX } from '../modules/nf-core/modules/samtools/faidx/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_NAME } from '../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_ORDER } from '../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_FIXMATE } from '../modules/nf-core/modules/samtools/fixmate/main'
include { FREEBAYES } from '../modules/nf-core/modules/freebayes/main'
include { BCFTOOLS_INDEX } from '../modules/nf-core/modules/bcftools/index/main'
include { BCFTOOLS_VIEW } from '../modules/nf-core/modules/bcftools/view/main'
include { BCFTOOLS_NORM } from '../modules/nf-core/modules/bcftools/norm/main'
include { BCFTOOLS_ANNOTATE } from '../modules/nf-core/modules/bcftools/annotate/main'
include { BCFTOOLS_MPILEUP } from '../modules/nf-core/modules/bcftools/mpileup/main'
// align imports
include { BCFTOOLS_CONSENSUS } from '../modules/nf-core/modules/bcftools/consensus/main'
include { BEDTOOLS_GENOMECOV } from '../modules/nf-core/modules/bedtools/genomecov/main'
include { BEDTOOLS_MERGE } from '../modules/nf-core/modules/bedtools/merge/main'
include { MINIMAP2_ALIGN } from '../modules/nf-core/modules/minimap2/align/main'
// tree building imports
include { IQTREE } from '../modules/nf-core/modules/iqtree/main'
// load local modules
include { SAMTOOLS_MARKDUP } from '../modules/local/samtools/markdup'
include { SAMCLIP } from '../modules/local/samclip'
include { GOALIGN_APPEND } from '../modules/local/goalign/append'



workflow TYPING {
    take:
        assembly
    main:
        amr_ch = assembly.map {meta, scaffolds -> {
            meta.organism = 'Salmonella'
            return [meta, scaffolds]
        }}
        AMRFINDERPLUS_UPDATE()
        AMRFINDERPLUS_RUN(amr_ch, AMRFINDERPLUS_UPDATE.out.db)
        SISTR(assembly)
        MLST(assembly)
    emit:
        serotype = SISTR.out.tsv
        mlst = MLST.out.tsv
        amr_genes = AMRFINDERPLUS_RUN.out.report
        amr_mutations = AMRFINDERPLUS_RUN.out.mutation_report
}

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

workflow VARIANT_DETECTION {
    take:
        reads
        reference
    main:
        samples = []
        populations = []
        cnv = []
        var_detection_mode = 'bcftools'
        SAMTOOLS_FAIDX([[],reference])
        ref_ix = SAMTOOLS_FAIDX.out.fai.map {it -> it[1]}
        BOWTIE2_BUILD(reference)
        BOWTIE2_ALIGN(reads, BOWTIE2_BUILD.out.index, false, false, true)
        SAMCLIP(BOWTIE2_ALIGN.out.sam, reference, ref_ix)
        SAMTOOLS_SORT_NAME(SAMCLIP.out.sam)
        SAMTOOLS_FIXMATE(SAMTOOLS_SORT_NAME.out.bam)
        SAMTOOLS_SORT_ORDER(SAMTOOLS_FIXMATE.out.bam)
        SAMTOOLS_MARKDUP(SAMTOOLS_SORT_ORDER.out.bam)
        if (var_detection_mode == 'freebayes') {
            bam_ch = SAMTOOLS_MARKDUP.out.bam.cross(SAMTOOLS_MARKDUP.out.bam_index){it -> it[0].id}.map {
                it -> {
                    def meta = it[0][0]
                    def input_1 = it[0][1]
                    def input_1_index = it[1][1]
                    def input_2 = []
                    def input_2_index = []
                    def target_bed = []
                    return [meta, input_1, input_1_index, input_2, input_2_index, target_bed]
                    }
                }
            FREEBAYES(bam_ch, reference, ref_ix, samples, populations, cnv)
            BCFTOOLS_INDEX(FREEBAYES.out.vcf)
            vcf_ch = FREEBAYES.out.vcf.cross(BCFTOOLS_INDEX.out.csi) {it -> it[0].id}.map {
                def meta = it[0][0]
                def vcf = it[0][1]
                def csi =  it[1][1]
                return [meta, vcf, csi]
            }
             BCFTOOLS_VIEW(vcf_ch, [], [], [])
             vcf_filtered_ch = BCFTOOLS_VIEW.out.vcf
        } else if (var_detection_mode == 'bcftools') {
            save_mpileup = false
            BCFTOOLS_MPILEUP(SAMTOOLS_MARKDUP.out.bam, reference, save_mpileup)
            vcf_filtered_ch = BCFTOOLS_MPILEUP.out.vcf.cross(BCFTOOLS_MPILEUP.out.tbi) {it -> it[0].id}.map {
                def meta = it[0][0]
                def vcf = it[0][1]
                def tbi = it[1][1]
                return [meta, vcf, tbi]
            }
        }
        BCFTOOLS_NORM(vcf_filtered_ch, reference)
        BCFTOOLS_ANNOTATE(BCFTOOLS_NORM.out.vcf)
    emit:
        variants = BCFTOOLS_ANNOTATE.out.vcf
        bams = SAMTOOLS_MARKDUP.out.bam
}

workflow CREATE_MASKS {
    take:
        bam
        reference
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