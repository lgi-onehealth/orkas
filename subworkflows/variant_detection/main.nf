// variant detection imports
include { BOWTIE2_BUILD } from '../../modules/nf-core/modules/bowtie2/build/main'
include { BOWTIE2_ALIGN } from '../../modules/nf-core/modules/bowtie2/align/main'
include { SAMTOOLS_FAIDX } from '../../modules/nf-core/modules/samtools/faidx/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_NAME } from '../../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_ORDER } from '../../modules/nf-core/modules/samtools/sort/main'
include { SAMTOOLS_FIXMATE } from '../../modules/nf-core/modules/samtools/fixmate/main'
if (params.var_detection_mode == 'freebayes') {
    include { FREEBAYES } from '../../modules/nf-core/modules/freebayes/main'
    include { BCFTOOLS_INDEX } from '../../modules/nf-core/modules/bcftools/index/main'
    include { BCFTOOLS_VIEW } from '../../modules/nf-core/modules/bcftools/view/main'
}
if (params.var_detection_mode == 'bcftools') {
    include { BCFTOOLS_MPILEUP } from '../../modules/nf-core/modules/bcftools/mpileup/main'
}
include { BCFTOOLS_NORM } from '../../modules/nf-core/modules/bcftools/norm/main'
include { BCFTOOLS_ANNOTATE } from '../../modules/nf-core/modules/bcftools/annotate/main'


// load local modules
include { SAMTOOLS_MARKDUP } from '../../modules/local/samtools/markdup'
include { SAMCLIP } from '../../modules/local/samclip'


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