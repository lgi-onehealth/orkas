def select_organism_key(organism) {
    def organisms = [
        'Acinetobacter baumannii',
        'Burkholderia cepacia',
        'Burkholderia pseudomallei',
        'Campylobacter',
        'Clostridioides difficile',
        'Enterococcus faecalis',
        'Enterococcus faecium',
        'Escherichia',
        'Klebsiella',
        'Neisseria',
        'Pseudomonas aeruginosa',
        'Salmonella', 
        'Staphylococcus aureus',
        'Staphylococcus pseudintermedius',
        'Streptococcus agalactiae',
        'Streptococcus pneumoniae',
        'Streptococcus pyogenes',
        'Vibrio cholerae',
    ]
    for (org in organisms) {
        if (organism =~ org) {
            return org.replaceAll(' ', '_')
        }
    }
    return null
}

process AMRFINDERPLUS_RUN {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::ncbi-amrfinderplus=3.10.30" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ncbi-amrfinderplus:3.10.30--h6e70893_0':
        'quay.io/biocontainers/ncbi-amrfinderplus:3.10.30--h6e70893_0' }"

    input:
    tuple val(meta), path(fasta)
    path db

    output:
    tuple val(meta), path("${prefix}.tsv")          , emit: report
    tuple val(meta), path("${prefix}-mutations.tsv"), emit: mutation_report, optional: true
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def is_compressed = fasta.getName().endsWith(".gz") ? true : false
    prefix = task.ext.prefix ?: "${meta.id}.amrfinder"
    organism = meta.containsKey("organism") ? select_organism_key(meta.organism): null
    organism_param = organism ? "--organism ${organism} --mutation_all ${prefix}-mutations.tsv" : ""
    fasta_name = fasta.getName().replace(".gz", "")
    fasta_param = "-n"
    if (meta.containsKey("is_proteins")) {
        if (meta.is_proteins) {
            fasta_param = "-p"
        }
    }
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    mkdir amrfinderdb
    tar xzvf $db -C amrfinderdb

    amrfinder \\
        $fasta_param $fasta_name \\
        $organism_param \\
        $args \\
        --database amrfinderdb \\
        --threads $task.cpus > ${prefix}.tsv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amrfinderplus: \$(amrfinder --version)
        amrfinderplus-database: \$(echo \$(echo \$(amrfinder --database amrfinderdb --database_version 2> stdout) | rev | cut -f 1 -d ' ' | rev))
    END_VERSIONS
    """
}
