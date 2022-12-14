process MINIMAP2_ALIGN {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? 'bioconda::minimap2=2.21 bioconda::samtools=1.12' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:1679e915ddb9d6b4abda91880c4b48857d471bd8-0' :
        'quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:1679e915ddb9d6b4abda91880c4b48857d471bd8-0' }"

    input:
    tuple val(meta), path(reference), path(reference_index)
    tuple val(meta_query), path(query, stageAs: 'query.fasta'), path(query_index, stageAs: 'query.fasta.fai')
    val bam_format
    val cigar_paf_format
    val cigar_bam
    val self_align

    output:
    tuple val(meta), path("*.paf"), optional: true, emit: paf
    tuple val(meta), path("*.bam"), optional: true, emit: bam
    path "*.bed"                  , optional: true, emit: bed
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bam_output = bam_format ? "-a | samtools sort | samtools view -@ ${task.cpus} -b -h -o ${prefix}.bam" : "-o ${prefix}.paf"
    def cigar_paf = cigar_paf_format && !bam_format ? "-c" : ''
    def set_cigar_bam = cigar_bam && bam_format ? "-L" : ''
    def bed = self_align ? "cat ${prefix}.paf | cut -f 1,3,4 | sort -k1,1 -k2,2n | awk '{print \$1,\$2,\$3+1}' | tr ' ' '\t' > ${prefix}.bed" : ''
    """
    minimap2 \\
        $args \\
        -t $task.cpus \\
        $reference \\
        $query \\
        $cigar_paf \\
        $set_cigar_bam \\
        $bam_output

        $bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """
}
