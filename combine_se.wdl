task combine_se {
    Array[File] iso_se
    Array[File] gene_se
    File somalier_final_output
    String prefix
    Int disk

    command {
         Rscript /home/analysis/combine_se.R ${prefix} ${somalier_final_output} ${sep=',' gene_se } ${sep=',' iso_se}
    }
    output {
        File sum_exp_gen = "${prefix}_Gene_Expression.rds"
        File sum_exp_iso = "${prefix}_Isoform_Expression.rds"
    }

    runtime {
        disks: "local-disk ${disk} SSD"
        memory: "16 GB"
        docker: "docker.io/htanpipelines/aggregation:latest"
        preemptible: 0
    }
}


workflow combine_se_workflow {
    call combine_se
}