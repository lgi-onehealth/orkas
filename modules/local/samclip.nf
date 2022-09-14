process SAMCLIP {
    tag "$meta.id"
    label 'process_medium'
    conda (params.enable_conda ? "bioconda::samclip=0.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samclip:0.4.0--hdfd78af_1':
        'quay.io/biocontainers/samclip:0.4.0--hdfd78af_1' }"

    input:
    tuple val(meta), path(sam)
    tuple val(meta_ref), path(reference), path(reference_index)

    output:
    tuple val(meta), path("*.sam"), emit: sam
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.samclip"
    def is_compressed = reference.getName().endsWith(".gz")
    def ref_filename = reference.getName().replace(".gz", "") 
    """
    if [ "$is_compressed" == true ]; then
        gzip -d -c $reference > $ref_filename
    fi
    
    samclip \\
        $args \\
        --ref ${ref_filename} \\
        < $sam \\
        > ${prefix}.sam \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samclip: \$(echo \$(samclip --version 2>&1) | sed 's/^.*samclip //g' ))
    END_VERSIONS
    """
}
