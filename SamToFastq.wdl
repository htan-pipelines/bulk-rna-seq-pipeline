task SamToFastq {
    File unmapped_bam
    String base_name

    String gatk_path

    String docker
	Int preemptible_count

	command <<<
	 	${gatk_path} \
	 	    SamToFastq \
	 	    --INPUT ${unmapped_bam} \
	 	    --VALIDATION_STRINGENCY SILENT \
	 	    --FASTQ ${base_name}.1.fastq.gz \
	 	    --SECOND_END_FASTQ ${base_name}.2.fastq.gz
	>>>

	output {
		File fastq1 = "${base_name}.1.fastq.gz"
        File fastq2 = "${base_name}.2.fastq.gz"
	}

	runtime {
		docker: docker
		memory: "4 GB"
		disks: "local-disk " + sub(((size(unmapped_bam,"GB")+1)*5),"\\..*","") + " HDD"
		preemptible: preemptible_count
	}
}

workflow SamToFastq_workflow {
  call SamToFastq
}
