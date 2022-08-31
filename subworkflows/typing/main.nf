// typing imports
include { MLST } from '../../modules/nf-core/modules/mlst/main'
include { SISTR } from '../../modules/nf-core/modules/sistr/main'
include { EMMTYPER } from '../../modules/nf-core/modules/emmtyper/main'
include { NGMASTER } from '../../modules/nf-core/modules/ngmaster/main'
include { LISSERO } from '../../modules/nf-core/modules/lissero/main'
include { MENINGOTYPE } from '../../modules/nf-core/modules/meningotype/main'
include { AMRFINDERPLUS_UPDATE } from '../../modules/nf-core/modules/amrfinderplus/update/main'
include { AMRFINDERPLUS_RUN } from '../../modules/nf-core/modules/amrfinderplus/run/main'

workflow TYPING {
    take:
        assembly
    main:
        // amr_ch = assembly.map {meta, scaffolds -> {
        //     meta.organism = 'Salmonella'
        //     return [meta, scaffolds]
        // }}
        AMRFINDERPLUS_UPDATE()
        AMRFINDERPLUS_RUN(assembly, AMRFINDERPLUS_UPDATE.out.db)
        SISTR(assembly)
        LISSERO(assembly)
        EMMTYPER(assembly)
        NGMASTER(assembly)
        MENINGOTYPE(assembly)
        MLST(assembly)
    emit:
        serotype = SISTR.out.tsv
        mlst = MLST.out.tsv
        // amr_genes = AMRFINDERPLUS_RUN.out.report
        // amr_mutations = AMRFINDERPLUS_RUN.out.mutation_report
}
