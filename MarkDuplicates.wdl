
task MarkDuplicates {

 	File input_bam
 	String base_name

  String gatk_path

  String docker
 	Int preemptible_count

 	command <<<
 	    ${gatk_path} \
 	        MarkDuplicates \
 	        --INPUT ${input_bam} \
 	        --OUTPUT ${base_name}.bam  \
 	        --CREATE_INDEX true \
 	        --VALIDATION_STRINGENCY SILENT \
 	        --METRICS_FILE ${base_name}.metrics
 	>>>

 	output {
 		File output_bam = "${base_name}.bam"
 		File output_bam_index = "${base_name}.bai"
 		File metrics_file = "${base_name}.metrics"
 	}

	runtime {
		disks: "local-disk " + sub(((size(input_bam,"GB")+1)*3),"\\..*","") + " HDD"
		docker: docker
		memory: "4 GB"
		preemptible: preemptible_count
	}
}
workflow markduplicates_workflow {
 call MarkDuplicates
}
