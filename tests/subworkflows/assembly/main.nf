#!/usr/bin/env nextflow

include { ASSEMBLY } from '../../../subworkflows/assembly/main.nf';

workflow test_assembly {

    input = [ [ id:'DRR040053', single_end:false ], // meta map
              [ file(params.test_data['fastq']['read1_clean'], checkIfExists: true),
                file(params.test_data['fastq']['read2_clean'], checkIfExists: true) ], // paired end fastq 
              [ file(params.test_data['fastq']['merged_clean'], checkIfExists: true)]  // merged fastq
              ];
    reads = Channel.from([input])

    ASSEMBLY(reads)
}
