task VCF_tools {
    File vcf_input
    String prefix
	String docker
    Int preemptible_count

    command <<<
          vcftools --vcf $input_vcf --out ${prefix} --plink

    >>>

        output {
        File ped_file="${prefix}.ped"
        }

        runtime {
        disks: "local-disk 1 HDD"
        memory: "8 GB"
        docker: docker
        preemptible: preemptible_count
    }
}
workflow VCF_workflow {
  call VCF_tools
  }