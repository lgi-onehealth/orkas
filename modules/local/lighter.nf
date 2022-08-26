process LIGHTER {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::lighter=1.1.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/lighter:1.1.2--hd03093a_4':
        'quay.io/biocontainers/lighter:1.1.2--h9a82719_3' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.cor.fq.gz"), emit: corrected_reads
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def k = meta.alpha ? "-k 21 ${meta.genome_size} ${meta.alpha}": "-K 21 ${meta.genome_size}"
    if (meta.single_end) {
    """
    lighter \
     -r ${reads} \
     ${k} \
     -t ${task.cpus} \
     ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lighter: \$(echo \$(lighter -v 2>&1) | sed 's/^.*Lighter //g' | sed 's/\)//g') ))
    END_VERSIONS
    """ 
    } else {
        """
    lighter \
     -r ${reads[0]} \
     -r ${reads[1]} \
     ${k} \
     -t ${task.cpus} \
     ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lighter: \$(echo \$(lighter -v 2>&1) | sed 's/^.*lighter //g' ))
    END_VERSIONS
    """
    }
}
