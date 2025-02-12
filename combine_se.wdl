task write_json {

    Array[File] iso_se
    Array[File] gene_se
    String prefix

    command <<<
        echo '{"iso_se": ["'$(echo ${sep='","' iso_se})'"], 
               "gene_se": ["'$(echo ${sep='","' gene_se})'"], 
               "prefix": "'${prefix}'"}' > ${prefix}_input.json
    >>>

    output {
        File json_file = "${prefix}_input.json"
    }

    runtime {
        disks: "local-disk 10 SSD"
        memory: "4 GB"
        docker: "ubuntu:latest"
    }
}

task combine_se {

    File json_file
    File somalier_final_output
    File genotype_tsv
    String prefix
    Int disk

    command {
        Rscript /home/analysis/combine_se.R ${json_file} ${somalier_final_output} ${genotype_tsv}
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

    Array[File] iso_se
    Array[File] gene_se
    File somalier_final_output
    File genotype_tsv
    String prefix
    Int disk

    call write_json {
        input:
            iso_se = iso_se,
            gene_se = gene_se,
            prefix = prefix
    }

    call combine_se {
        input:
            json_file = write_json.json_file,
            somalier_final_output = somalier_final_output,
            genotype_tsv = genotype_tsv,
            prefix = prefix,
            disk = disk
    }
}