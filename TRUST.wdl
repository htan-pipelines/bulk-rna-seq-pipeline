task TRUST {
    File ref_fasta_IMGT
    File ref_fasta
    File input_bam
    String trust_path
    String prefix
    String docker
    Int preemptible_count

    command <<<
          ${trust_path} -b ${input_bam} -f ${ref_fasta} --ref ${ref_fasta_IMGT}

    >>>

        output {
        File out_cdr3="${prefix}_cdr3.out"
        File trustfinal="${prefix}_final.out"
        File trustreport="${prefix}_report.tsv"
        }

        runtime {
        disks: "local-disk 1 HDD"
        memory: "8 GB"
        docker: docker
        preemptible: preemptible_count
    }
}    
workflow TRUST_workflow {
  call TRUST
  }
