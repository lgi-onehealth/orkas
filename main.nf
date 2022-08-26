include { ONE_FLOW } from "./subworkflows/one_flow"


local_data = Channel.fromPath(params.local_input)
            .splitCsv(header: ['sample_id', 'read1', 'read2'])
            .map {row ->
                def meta = [:]
                meta.id = row.sample_id
                meta.single_end = row.read2.length() == 0
                def read1 = file(row.read1)
                def read2 = row.read2.size() > 0 ? file(row.read2) : null
                if (meta.single_end) {
                    [meta, read1]
                } else {
                    [meta, [read1, read2]]
                }
            }.take(20)

context_input = file(params.context_input)

context_data = Channel.from(context_input.text)
               .splitCsv(header: true, quote: '\"')
               .map {row ->
                   def meta = [:]
                   meta.id = row.sample
                   meta.single_end = row.fastq_2.length() == 0
                   def read1 = file(row.fastq_1)
                   def read2 = row.fastq_2.size() > 0 ? file(row.fastq_2) : null
                   if (meta.single_end) {
                       [meta, read1]
                   } else {
                       [meta, [read1, read2]]
                   }
               }

data = local_data.mix(context_data)

reference = file("gs://fastq-minag/ref_seqs/GCF_002266085.2_ASM226608v2_genomic.fna.gz")

workflow {
    ONE_FLOW(data, reference, params.kraken_db)
}