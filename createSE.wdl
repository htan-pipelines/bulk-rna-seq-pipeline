task createSE {

    File input_file
    File tinfile
    File gtf
    File gene
    File isoform
    File star_file
    String sample_name
    Int disk


    command {
        Rscript /home/analysis/createSE.R ${input} ${tinfile} ${gtf} ${gene_file} ${isoform_file} ${sample.name} ${star_file} 
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
