process CLIPKIT {
    tag "$fasta"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::clipkit=1.3.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/clipkit:1.3.0--pyhdfd78af_0':
        'quay.io/biocontainers/clipkit:1.3.0--pyhdfd78af_0' }"

    input:
    path fasta

    output:
    path "*.fasta", emit: fasta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    clipkit \\
        $fasta \\
        $args \\
        -o alignment.clipkit.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        clipkit: \$(echo \$(clipkit --version | sed 's/clipkit //g'))
    END_VERSIONS
    """
}
