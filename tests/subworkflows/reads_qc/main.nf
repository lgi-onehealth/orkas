#!/usr/bin/env nextflow

include { READS_QC } from '../../../subworkflows/reads_qc/main.nf';
workflow test_reads_qc {

    input = [ [ id:'test', single_end:false ], // meta map
              [ file(params.test_data['fastq']['read1'], checkIfExists: true),
                file(params.test_data['fastq']['read2'], checkIfExists: true) ] ];

    READS_QC(input)
}
