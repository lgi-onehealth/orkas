// tree building imports
include { IQTREE } from '../modules/nf-core/modules/iqtree/main'


workflow TREE_BUILD {
    take:
        alignment
    main:
        IQTREE(alignment, [])
}