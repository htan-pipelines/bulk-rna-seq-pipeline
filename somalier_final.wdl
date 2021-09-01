task somalier_final {

    File somalier_pairs
    Array[String] sample_id
    Array[String] particpant_id

   command {
       echo ${sep=',' sample_id}
       
       Rscript /home/analysis/somalier_final_function.R --no-save --args ${somalier_pairs} ${sep=',' sample_id} ${sep=',' particpant_id}  
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

workflow somalier_final_workflow {
    call somalier_final
}
