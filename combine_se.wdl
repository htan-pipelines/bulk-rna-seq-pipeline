task combine_se_write_json {

    Array[File] iso_se
    Array[File] gene_se
    String prefix
    File somalier_final_output
    File genotype_tsv
    Int disk

    command <<<
        # Create the JSON file
        echo '{"iso_se": ["'$(echo ${sep='","' iso_se})'"], 
               "gene_se": ["'$(echo ${sep='","' gene_se})'"], 
               "prefix": "'${prefix}'"}' > ${prefix}_input.json

        # Run the R script to combine the data
        Rscript /home/analysis/combine_se.R ${prefix}_input.json ${somalier_final_output} ${genotype_tsv}
    >>>

    output {
        File json_file = "${prefix}_input.json"
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

    call combine_se_write_json
}