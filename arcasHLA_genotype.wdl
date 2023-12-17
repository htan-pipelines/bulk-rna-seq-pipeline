task arcasHLA_extract {
	String prefix
	File input_bam
	Int memory
	Int num_threads
	String docker
	Int preemptible_count

	command <<<
		arcasHLA extract ${input_bam} --verbose --threads ${num_threads} --outdir .
	>>>	

	output {
		File sample_extracted_1 = "${prefix}.extracted.1.fq.gz"
		File sample_extracted_2 = "${prefix}.extracted.2.fq.gz"
	}

	runtime {
    	disks: "local-disk " + sub(((size(input_bam,"GB")+1)*5),"\\..*","") + " HDD"
		docker:docker
		memory: "${memory}GB"
		cpu: "${num_threads}"
        preemptible_count:preemptible_count

	}

}

task arcasHLA_genotype {
	File sample_extracted_1
	File sample_extracted_2
	String prefix
	Int memory
	Int num_threads
	String docker
	Int preemptible_count

	command <<<
		arcasHLA genotype --verbose --threads ${num_threads} \
		${sample_extracted_1} \
		${sample_extracted_2} \
		--genes A,B,C,DPB1,DQB1,DQA1,DRB1 --outdir .
	>>>

	output {
		File sample_aligment = "${prefix}.alignment.p"
		File sample_em = "${prefix}.genes.json"
		File sample_genotype = "${prefix}.genotype.json"
	}

	runtime {
		docker:docker
		memory: "${memory}GB"
		cpu: "${num_threads}"
        preemptible_count:preemptible_count

	}
}

workflow arcasHLAWorkflow {
    String prefix

	call arcasHLA_extract {
		input:
			prefix=prefix
			input_bam=input_bam
			
	}

	call arcasHLA_genotype {
		input:
        	prefix=prefix,
			sample_extracted_1 = arcasHLA_extract.sample_extracted_1,
			sample_extracted_2 = arcasHLA_extract.sample_extracted_2
	}

}