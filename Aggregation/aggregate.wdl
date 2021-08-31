import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/createSE.wdl" as createse
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/somalier_relate.wdl" as somalier_relate
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/somalier_final.wdl" as somalier_final
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/multiQC.wdl" as multiqc

workflow aggregation_workflow {
    
    Array[String] sample_id

    Int preemptible_count
    
    call multiqc.MultiQC {
        input: star_files=star_log

        File mutiqc_output_star=multiqc.multiqc_star
    }

    call somalier_relate.somalier_relate {
        input: somalier_counts=somalier_counts

        File somalier_pairs = somalier_relate.somalier_pairs
    }

    call somalier_final {
        input: somalier_pairs=somalier_relate.somalier_pairs, sample_id=sample_id, particpant_id=particpant_id, preemptible_count=preemptible_count

        File somalier_final_output = somalier_final.somalier_final_output
    }

    call createse.createSE {
        input: sample_name=sample_id, somalier_final=somalier_final.somalier_final_output, star_log_final=multiqc.multiqc_star
    }
}
