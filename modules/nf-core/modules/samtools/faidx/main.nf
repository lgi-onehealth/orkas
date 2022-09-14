process SAMTOOLS_FAIDX {
    tag "$fasta"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::samtools=1.15.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.15.1--h1170115_0' :
        'quay.io/biocontainers/samtools:1.15.1--h1170115_0' }"

    input:
    tuple val(meta), path(fasta)
    val chromosome_id
    val region_start
    val region_end

    output:
    tuple val(meta), path ("*.fai"), emit: fai
    tuple val(meta), path("*.fasta"), emit: fasta, optional: true
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def is_compressed = fasta.getName().endsWith('.gz')
    def fasta_name = fasta.getName().replace(".gz", '')
    def subregion = region_start ? ":${region_start}-${region_end}" : ""
    def region = chromosome_id ? "${chromosome_id}${subregion} > ref_chrom.fasta" : ""
    """
    if [ "$is_compressed" = true ]; then
        bgzip -c -d $fasta > ${fasta_name}
    fi

    samtools \\
        faidx \\
        $args \\
        ${fasta_name} $region

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch ${fasta}.fai
    cat <<-END_VERSIONS > versions.yml

    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
