
process ANY2FASTA {
    tag "$reference"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::any2fasta=0.4.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/any2fasta:0.4.2--hdfd78af_3':
        'quay.io/biocontainers/any2fasta:0.4.2--hdfd78af_3' }"

    input:
    path reference

    output:
    path "reference.fasta", emit: fasta
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    any2fasta \\
        $args \\
        $reference \\
        > reference.fasta
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        any2fasta: \$(echo \$(any2fasta -v 2>&1) | sed 's/^.*any2fasta //' )
    END_VERSIONS
    """
}
