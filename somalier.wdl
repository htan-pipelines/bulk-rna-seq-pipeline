task somalier_extract {
    String prefix
    Array[File] known_indels_sites_VCFs
    File ref_fasta
    File input_bam

    String docker
    Int preemptible_count

    command <<<
          somalier extract --d `pwd`/ --sites ${known_indel_sites_VCF}  --fasta ${ref_fasta}  ${input_bam}
    >>>

        output {
           File somalier_output="${prefix}.somalier"
        }

        runtime {
        disks: "local-disk 1 HDD"
        memory: "2 GB"
        docker: docker
        preemptible: preemptible_count
    }
workflow somalier_extraction {
  call somalier_extract
  }
