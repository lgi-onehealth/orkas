#!/usr/bin/env nextflow

include { PHYLOGENETIC_RECONSTRUCTION } from '../../../subworkflows/phylogenetic_reconstruction/main.nf'

workflow test_phylogenetic_reconstruction {

    alignment = Channel.fromPath(params.test_data['alignment']['aln_5seq'])

    PHYLOGENETIC_RECONSTRUCTION(alignment)

}