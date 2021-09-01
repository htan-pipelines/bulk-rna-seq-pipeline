task createSE {

    File input_file
    File tinfile
    File gtf
    File gene_file
    File isoform_file
    File star_file
    String sample_name
    Int disk


    command {
        gene=gunzip${gene_file}
        isoform=gunzip ${isoform_file}        
        Rscript /home/analysis/createSE.R ${input_file} ${tinfile} ${gtf} $gene $isoform ${sample_name} ${star_file} 
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
