process GOALIGN_APPEND {
    tag "$alignment_1"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::goalign=0.3.5" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/goalign:0.3.5--h65a6115_0':
        'quay.io/biocontainers/goalign:0.3.5--h65a6115_0' }"

    input:
    tuple val(meta_ref) path(reference)
    path alignment_2

    output:
    path "${output_filename}"     , emit: alignment
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    output_filename = "raw-align.goalign-append.fasta"
    """
    goalign append \
        -i $alignment_1 \
        -o $output_filename \
        $args \
        $alignment_2

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        goalign: \$(echo \$(goalign version))
    END_VERSIONS
    """
}
