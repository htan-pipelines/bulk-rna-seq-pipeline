task arcasHLA_merge {
	Array[File] sample_genotype
	Int memory
	Int num_threads
	String docker
	Int preemptible_count
    
	command {
		mkdir genotype_out
		mv ${sep=' ' sample_genotype} genotype_out/
		echo "$PWD"
		arcasHLA merge --indir genotype_out  --verbose --outdir .
	}

	output {
		File genotype_tsv = "genotypes.tsv"
	}

	runtime {
		docker:docker
		memory: "${memory}GB"
		cpu: "${num_threads}"
		preemptible_count:preemptible_count

	}

}

workflow arcasHLA_mergeWorkflow {
	call arcasHLA_merge
}