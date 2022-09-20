// tree building imports
include { IQTREE } from '../../modules/nf-core/modules/iqtree/main'
include { GOTREE_REROOTMIDPOINT } from '../../modules/local/gotree/rerootmidpoint'
include { GOTREE_ROTATESORT } from '../../modules/local/gotree/rotatesort'

workflow PHYLOGENETIC_RECONSTRUCTION {
    take:
        alignment
    main:
        IQTREE(alignment, [])
        GOTREE_REROOTMIDPOINT(IQTREE.out.phylogeny)
        GOTREE_ROTATESORT(GOTREE_REROOTMIDPOINT.out.tree)
    emit:
        phylogeny = GOTREE_ROTATESORT.out.tree
}