#!/usr/bin/env nextflow

include { SPECIATION } from '../../../subworkflows/speciation/main.nf';


process GET_KRAKEN_DB {

    input:
    path(kraken_db)

    output:
    path('kraken2_bracken'), emit: db

    script:
    """
    tar -xzf ${kraken_db}
    """
}


workflow test_speciation {

    reads = [
                 [id:"SRR10903401", single_end:false ], 
                 [
                    file("https://github.com/nf-core/test-datasets/raw/covid19/illumina/SRR10903401_1.fastq.gz", checkIfExists: true), 
                    file("https://github.com/nf-core/test-datasets/raw/covid19/illumina/SRR10903401_2.fastq.gz", checkIfExists: true)
                  ]
            ];
    db = file("https://github.com/nf-core/test-datasets/raw/add-bracken/data/database/bracken/kraken2_bracken.tar.gz", checkIfExists: true);
    save_output_fastqs = false
    save_reads_assignment = false
    GET_KRAKEN_DB(db)
    SPECIATION(reads, GET_KRAKEN_DB.out.db, save_output_fastqs, save_reads_assignment)
}
