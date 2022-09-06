#!/usr/bin/env nextflow

include { CREATE_MASKS } from '../../../subworkflows/create_masks/main.nf';
workflow test_create_masks {

    scale = 1;
    bam = [ [ id:'test_1', single_end:false ], // meta map
              file("https://github.com/nf-core/test-datasets/raw/modules/data/genomics/prokaryotes/bacteroides_fragilis/illumina/bam/test1.sorted.bam", checkIfExists: true),
              scale
            ];
    ref = file("https://github.com/nf-core/test-datasets/raw/modules/data/genomics/prokaryotes/bacteroides_fragilis/illumina/fasta/test1.contigs.fa.gz");
    filter_min = 1;

    CREATE_MASKS(bam, ref, filter_min)
}
