process BCFTOOLS_CONSENSUS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::bcftools=1.15.1; bioconda::samtools=1.15.1" : null)
    container "lighthousegenomics/samtools-suite:v1.15.1"

    input:
    tuple val(meta), path(vcf), path(tbi), path(mask)
    tuple val(meta_ref), path(ref_fasta), path(ref_fai)

    output:
    tuple val(meta), path('*.fasta'), emit: fasta
    path  "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mask_file = mask ? "--mask ${mask}" : ''
    def is_gzipped = ref_fasta.getName().endsWith('.gz')
    def fasta_name = ref_fasta.getName().replace('.gz', '')
    def ref = meta_ref.is_complete && meta_ref.chromosome_id? "samtools faidx $fasta_name $meta_ref.chromosome_id" : "cat $fasta_name"
    def label_seqs = meta_ref.is_complete && meta_ref.chromosome_id? "sed 's/^>.*\$/>${meta.id}/'" : "awk '/>/{\$0 = ">"${meta.id}.++i} 1'"

    """
    if [ "${is_gzipped}" == true ]; then 
        gzip -d -c ${ref_fasta} > ${fasta_name}
    fi

    $ref \\
        | bcftools \\
            consensus \\
            $vcf \\
            $args \\
            $mask_file \\
            | $label_seqs > ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
