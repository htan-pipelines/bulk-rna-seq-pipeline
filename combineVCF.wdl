task combineVCF {
    String prefix
    Array[File] known_indels_sites_VCFs
    Array[File] known_indels_sites_indices
    File ref_fasta
    File input_vcf

    String docker
    String gatk_path
    Int preemptible_count

    command <<<
          task combineVCF {
    String prefix
    Array[File] vcf_list
    File ref_fasta
    File input_vcf

    String docker
    String gatk_path
    Int preemptible_count

    command <<<
          ${gatk_path} \
       -T CombineVariants \
       -R ${ref_fasta} \
       -V ${vcf_file}.join(" -V ") \
       -o ${outfile}
    >>>

        output {
           File combined_vcf_output="${prefix}.combined.vcf"
        }

        runtime {
        disks: "local-disk 1 HDD"
        memory: "8 GB"
        docker: docker
        preemptible: preemptible_count
    }
}
workflow combineVCF_workflow {
  call combineVCF
  }
    >>>

        output {
           File combined_vcf_output="${prefix}.combined.vcf"
        }

        runtime {
        disks: "local-disk 1 HDD"
        memory: "8 GB"
        docker: docker
        preemptible: preemptible_count
    }
}
workflow combineVCF_workflow {
  call combineVCF
  }
