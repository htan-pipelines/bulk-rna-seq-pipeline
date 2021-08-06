task somalier_extract {
    String prefix
    File known_indels_sites_VCF
    File ref_fasta
    File ref_fasta_index
    File input_bam
    File input_bam_index

    Int preemptible_count

    command <<<
          somalier extract --d `pwd`/ --sites ${known_indels_sites_VCF}  --fasta ${ref_fasta}  ${input_bam}
    >>>

        output {
           File somalier_output="${prefix}.somalier"
        }

        runtime {
        disks: "local-disk " + sub(((size(input_bam,"GB")+1)*5 + " HDD"
        memory: "2 GB"
        docker: "docker.io/brentp/somalier:latest"
        preemptible: preemptible_count
    }
  }
workflow somalier_extraction {
  call somalier_extract
  }
