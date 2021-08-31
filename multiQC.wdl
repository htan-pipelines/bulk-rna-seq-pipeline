task MultiQC{
    Array[File] star_files

    # runtime values
    
    Int machine_mem_mb
    Int cpu = 16
    Int disk
    Int preemptible = 0



  command {
  # Run MultiQC
  multiqc -n sample_multiqc .
}

  runtime {
    docker: "docker.io/ewels/multiqc:latest"
    memory: "${machine_mem_mb} MiB"
    disks: "local-disk ${disk} SSD"
    cpu: cpu
    preemptible: preemptible
  }
    output {
    File mutiqc_output_star = "sample_multiqc_data/multiqc_star.txt"
    File multiqc_output = "sample_multiqc.html"
  }
}

workflow multiqc_workflow{
  call MultiQC
}
