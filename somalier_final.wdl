task somalier_final {

    File somalier_pairs
    Array[String] sample_id
    Array[String] particpant_id

   command {
       R 
       source("/home/analysis/somalier_final_function.R")

       somalier_stats(${somalier_pairs}, ${sample_id}, ${particpant_id})
   } 

   output {
       File somalier_final_output = "somalier.final.tsv"
   }

   runtime {
        disks: "local-disk 100 HDD"
        memory: "8 GB"
        docker: "docker.io/htanpipelines/aggregation:latest"
        preemptible: 0
    }
}

workflow somalier_final {
    call somalier_final
}