task RSEQC_TIN {
    File bam_input
    File gene_bed
    String prefix

    # runtime values

    String docker = "quay.io/humancellatlas/secondary-analysis-star:v0.2.2-2.5.3a-40ead6e"
    Int machine_mem_mb = ceil((size(bam_input, "Gi")) + 6) * 1100
    Int cpu = 16
    # multiply input size by 2.2 to account for output bam file + 20% overhead, add size of reference.
    Int disk = ceil((size(bam_input, "Gi") * 2.5) + (size(bam_input, "Gi") * 2.5))
    # by default request non preemptible machine to make sure the slow star alignment step completes
    Int preemptible = 0

  
  command {
     tin.py -i ${bam_input} -r ${gene_bed} > ${prefix}.summary.txt
     }

  runtime {

    docker: docker
    memory: "${machine_mem_mb} MiB"
    disks: "local-disk ${disk} SSD"
    cpu: cpu
    preemptible: preemptible
  }
  output {
   File TIN_summary = "${sampleID}.summary.txt"
  }
}
workflow RSEQC_TIN_workflow{

  call RSEQC_TIN
}
