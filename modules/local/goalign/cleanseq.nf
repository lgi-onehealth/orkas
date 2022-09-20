process GOALIGN_CLEANSEQ {
    tag "$fasta"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::goalign=0.3.5" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/goalign:0.3.5--h65a6115_0':
        'quay.io/biocontainers/goalign:0.3.5--h65a6115_0' }"

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
    goalign \\
        --auto-detect \\
        clean \\
        seqs \\
        $args \\
        -t $task.cpus \\
        -o alignment.goalign-cleanseq.fasta \\
        -i $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        goalign: \$(goalign --version 2>&1)
    END_VERSIONS
    """
}
