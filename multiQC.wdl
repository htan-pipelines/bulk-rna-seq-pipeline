task MultiQC{
    Array[File] rseqc_bam_stat_files
    Array[File] rseqc_geneBody_coverage_files
    Array[File] rseqc_infer_experiment_files
    Array[File] rseqc_inner_distance_files
    Array[File] rseqc_junction_annotation_files
    Array[File] rseqc_junction_saturation_files
    Array[File] rseqc_read_distribution_files
    Array[File] rseqc_read_duplication_files
    Array[File] rseqc_read_GC_files
    Array[File] star_files
    String filename

    # runtime values

    #String docker = "quay.io/humancellatlas/secondary-analysis-star:v0.2.2-2.5.3a-40ead6e"
    Int machine_mem_mb
    Int cpu = 16
    # multiply input size by 2.2 to account for output bam file + 20% overhead, add size of reference.
    Int disk
    # by default request non preemptible machine to make sure the slow star alignment step completes
    #Int preemptible = 0



  command {
  # Create temporary MultiQC input file
  multiqc_input_tempfile=\$(mktemp)

  for filename in \
    '${rseqc_bam_stat_files.join("' '")}' \
    '${rseqc_geneBody_coverage_files.join("' '")}' \
    '${rseqc_infer_experiment_files.join("' '")}' \
    '${rseqc_inner_distance_files.join("' '")}' \
    '${rseqc_junction_annotation_files.join("' '")}' \
    '${rseqc_junction_saturation_files.join("' '")}' \
    '${rseqc_read_distribution_files.join("' '")}' \
    '${rseqc_read_duplication_files.join("' '")}' \
    '${rseqc_read_GC_files.join("' '")}' \
    '${star_files.join("' '")}'
  do
    echo "\$filename" >> \$multiqc_input_tempfile
  done
  
  # Run MultiQC
  multiqc -n sample_multiqc --file-list \$multiqc_input_tempfile
}

  runtime {
   # docker: docker
    memory: "${machine_mem_mb} MiB"
    disks: "local-disk ${disk} SSD"
    cpu: cpu
   # preemptible: preemptible
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
