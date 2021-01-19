task FastqToSam {
    File fastq1
    File? fastq2
    String sample_name
    String read_group
    String library_name
    String platform_unit
    String platform_name
    String sequencing_center

    String gatk_path

    String docker
	  Int preemptible_count

	command <<<
	 	${gatk_path} \
	 	    FastqToSam \
        F1=${fastq1} \
        F2=${fastq2} \
        O=${read_group}.unmapped.bam \
        SM=${sample_name} \
        RG=${read_group} \
        LB=${library_name} \
        PU=${platform_unit} \
        PL=${platform_name} \
        CN=${sequencing_center} 
        
	>>>

	output {
		File unmapped_output_bam = "${readgroup_name}.unmapped.bam"
	}

	runtime {
		docker: docker
		memory: "4 GB"
		disks: "local-disk " + sub(((size(fastq1,"GB")+1)*5),"\\..*","") + " HDD"
		preemptible: preemptible_count
	}
}

workflow FastqToSam_workflow {
  call FastqToSam
}
