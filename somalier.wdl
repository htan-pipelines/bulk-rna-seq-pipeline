task somalier_extract {
    string prefix
    Array[File] known_indels_sites_VCFs
    Array[File] known_indels_sites_indices
    File ref_fasta
    File input_vcf

    String docker
    Int preemptible_count

    command <<<
          somalier extract --d 'pwd'/ --sites ${known_indel_sites_VCF}  --fasta ${ref_fasta}  ${input_vcf}
    >>>

        output {
           File somalier_output="${prefix}.somalier"
        }

        runtime {
        disks: "local-disk 1 HDD"
        memory: "8 GB"
        docker: docker
        preemptible: preemptible_count
    }    
}
workflow somalier_extraction {
  call somalier_extract
  }
