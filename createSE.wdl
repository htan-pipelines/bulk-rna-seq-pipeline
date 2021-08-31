task createSE {

    Array[File] input_file
    File tinfile
    File gtf
    Array[File] gene
    Array[File] isoform
    File star_log_final
    Array[String] sample_name
    File somalier_final
    Int disk


    command {
        R 
        source("/home/analysis/createSE.R")

        create_se(${input_file},${tinfile},${gene},${isoform},${sample_name},${star_log}, ${somalier_final})
    }

    output {
        File sum_exp_gen = "${sample_name}_Gene_Expression.rds"
        File sum_exp_iso = "${sample_name}_Isoform_Expression.rds"
    }

    runtime {
        disks: "local-disk ${disk} SSD"
        memory: "16 GB"
        docker: "docker.io/htanpipelines/aggregation:latest"
        preemptible: 0
    }
}

workflow summarized_experiment {
    call createSE
}
