process GOTREE_REROOTMIDPOINT {
    tag "$tree"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::gotree=0.4.3" : null)
    container "lighthousegenomics/gotree:v0.4.3"

    input:
    path tree

    output:
    path "*.tre", emit: tree
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    gotree \\
        reroot \\
        midpoint \\
        $args \\
        -t $task.cpus \\
        -i $tree \\
        -o ${tree.baseName}_midpoint-root.tre

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gotree: 0.4.3
    END_VERSIONS
    """
}
