import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/somalier_relate.wdl" as somalier_relate
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/somalier_final.wdl" as somalier_final
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/arcasHLA_merge.wdl" as arcasHLA_merge
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/combine_se.wdl" as combine_se

workflow aggregation_workflow {
    
    Array[String] sample_id
    Array[File] iso_se
    Array[File] gene_se
    Int preemptible_count
    String prefix
    Int disk

    call somalier_relate.somalier_relate {
    }

    call somalier_final.somalier_final {
        input: somalier_pairs=somalier_relate.somalier_pairs, sample_id=sample_id
    }

    call arcasHLA_merge.arcasHLA_merge {
    }

    call combine_se.combine_se {
        input: 
            somalier_final_output = somalier_final.somalier_final_output,
            genotype_tsv = arcasHLA_merge.genotype_tsv,
            iso_se = iso_se,
            gene_se = gene_se,
            prefix = prefix,
            disk = disk
    }
}