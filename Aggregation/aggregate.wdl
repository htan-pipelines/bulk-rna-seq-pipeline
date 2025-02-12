import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/somalier_relate.wdl" as somalier_relate
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/somalier_final.wdl" as somalier_final
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/arcasHLA_merge.wdl" as arcasHLA_merge
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/combine_se.wdl" as combine_se

workflow aggregation_workflow {

    Array[String] sample_id
    Int preemptible_count


    call somalier_relate.somalier_relate {
    }

    call somalier_final.somalier_final {
        input: somalier_pairs = somalier_relate.somalier_pairs, sample_id = sample_id
    }

    call arcasHLA_merge.arcasHLA_merge {
    }

    call combine_se.write_json {
        input:
            iso_se = iso_se,
            gene_se = gene_se,
            prefix = prefix
    }

    call combine_se.combine_se {
        input:
            json_file = write_json.json_file,
            somalier_final_output = somalier_final.somalier_final_output,  # Added this
            genotype_tsv = arcasHLA_merge.genotype_tsv,  # Added this
    }
}