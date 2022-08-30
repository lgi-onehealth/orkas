// An assembly subworkflow
// 
// This workflow takes as input FASTQ files and outputs assemblies and assembly
// statistics.
//
// The workflow is as follows:
// 1. Reads are assembled using Unicycler
// 2. Assembly statistics are generated using Quast

// TODO: Move the read_ch logic to outside of the workflow. The input to the 
// workflow should be a lot simpler.

// Assembly imports
include { UNICYCLER } from '../../modules/nf-core/modules/unicycler/main'
include { QUAST } from '../../modules/nf-core/modules/quast/main'

workflow ASSEMBLY {
    take:
        reads
    main:
        // two params for quast. setting to false for now, but perhaps at a 
        // later date these could be used to get better assembly metrics
        use_fasta = false
        use_gff = false
        // create channel to add the long reads to the assembly 
        // perhaps at some point this will be useful
        reads_ch = reads.map {meta, shortreads, mergedreads -> {
                    return [meta, shortreads, [], mergedreads]
                }
            }
        UNICYCLER(reads_ch)
        QUAST(UNICYCLER.out.scaffolds, [], [], use_fasta, use_gff)
    emit:
        assembly =  UNICYCLER.out.scaffolds
}
