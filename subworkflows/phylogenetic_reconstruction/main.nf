// tree building imports
include { IQTREE } from '../modules/nf-core/modules/iqtree/main'
include { GOALIGN_APPEND } from '../modules/local/goalign/append'


workflow TREE_BUILD {
    take:
        alignment
        reference
    main:
        GOALIGN_APPEND(alignment, reference)
        IQTREE(GOALIGN_APPEND.out.alignment, [])
}