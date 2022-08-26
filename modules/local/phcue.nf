
process PHCUE {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "ph-cue=0.2.0" : null)
    container "andersgs/ph-cue:v0.2.0"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path(reads), emit: reads
    tuple val(meta), path("*.phcue.txt"), emit: stats
    tuple val(meta), env(GENOME_SIZE), emit: genome_size
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ph-cue \
        -t ${task.cpus} \
        ${reads[0]} > \
        ${prefix}.phcue.txt    
    GENOME_SIZE=`cat ${prefix}.phcue.txt | grep "Total unique" | sed 's/Total unique: //g' | sed 's/,//g'`


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        phcue: \$(echo \$(ph-cue --version 2>&1) | sed 's/ph-cue //g' ))
    END_VERSIONS
    """
}
