task RSEQC_TIN {
    File bam_input
    File bam_index
    File gene_bed

    # runtime values

    String rseqc_docker
    Int machine_mem_mb = 16
    Int cpu = 16
    # multiply input size by 2.2 to account for output bam file + 20% overhead, add size of reference.
    Int disk = 200
    # by default request non preemptible machine to make sure the slow star alignment step completes
    Int preemptible = 0

  
  command {
     
     set -euo pipefail
     
     tin.py -i ${bam_input} -r ${gene_bed}
     }

  runtime {

    docker: rseqc_docker
    memory: "${machine_mem_mb} MiB"
    disks: "local-disk ${disk} SSD"
    cpu: cpu
    preemptible: preemptible
  }
  output {
   File TIN_summary = glob("*.summary.txt")[0]
  }
}
workflow RSEQC_TIN_workflow{

  call RSEQC_TIN
}
