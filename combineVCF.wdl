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
          ${gatk_path} -T CombineVariants -R ${ref_fasta} --variant vcfs.list -o ${prefix}.combined.vcf -genotypeMergeOptions UNIQUIFY
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