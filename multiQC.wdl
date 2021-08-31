task MultiQC{
    Array[File] star_files

    # runtime values
    
    Int machine_mem_mb
    Int cpu = 16
    Int disk
    Int preemptible = 0



  command {
  # Create temporary MultiQC input file
  multiqc_input_tempfile=\$(mktemp)

  for filename in \
    '${star_files[0].join("' '")}'
  do
    echo "\$filename" >> \$multiqc_input_tempfile
  done
  
  # Run MultiQC
  multiqc -n sample_multiqc --file-list \$multiqc_input_tempfile
}

  runtime {
    docker: "docker.io/ewels/multiqc:latest"
    memory: "${machine_mem_mb} MiB"
    disks: "local-disk ${disk} SSD"
    cpu: cpu
    preemptible: preemptible
  }
    output {
    File multiqc_output_reseqc = "sample_multiqc_data/multiqc_rseqc_*.txt"
    File mutiqc_output_star = "sample_multiqc_data/multiqc_star.txt"
    File multiqc_output = "sample_multiqc.html"
  }
}

workflow multiqc_workflow{
  call MultiQC
}
