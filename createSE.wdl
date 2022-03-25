task createSE {

    File input_file
    File tinfile
    File gtf
    File gene_file
    File isoform_file
    File star_file
    File fastqc_1_file 
    File fastqc_2_file 
    File samtools_stats_file
    String sample_name
    Int disk


    command {
             
        Rscript /home/analysis/create_SE.R ${input_file} ${tinfile} ${gtf} ${gene_file} ${isoform_file} ${sample_name} ${star_file} ${fastqc_1_file} ${fastqc_2_file} ${samtools_stats_file}
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
