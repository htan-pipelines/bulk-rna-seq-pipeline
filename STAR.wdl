task Star {
	File star_index
	File fastq1
	File? fastq2
	String base_name
	Int? read_length

	Int? num_threads
	Int threads = select_first([num_threads, 8])
	Int? star_mem_max_gb
	Int star_mem = select_first([star_mem_max_gb, 45])
	#Is there an appropriate default for this?
	Int? star_limitOutSJcollapsed

	Int? additional_disk
	Int add_to_disk = select_first([additional_disk, 0])
	String docker
	Int preemptible_count
  String ${RG_line}

	command <<<
    set -euo pipefail
        if [[ ${fastq1} == *".tar" || ${fastq1} == *".tar.gz" ]]; then
            tar -xvvf ${fastq1}
            fastq1_abs=$(for f in *_1.fastq*; do echo "$(pwd)/$f"; done | paste -s -d ',')
            fastq2_abs=$(for f in *_2.fastq*; do echo "$(pwd)/$f"; done | paste -s -d ',')
            if [[ $fastq1_abs == *"*_1.fastq*" ]]; then  # no paired-end FASTQs found; check for single-end FASTQ
                fastq1_abs=$(for f in *.fastq*; do echo "$(pwd)/$f"; done | paste -s -d ',')
                fastq2_abs=''
            fi
        else
            # make sure paths are absolute
            fastq1_abs=${fastq1}
            fastq2_abs=${fastq2}
            if [[ $fastq1_abs != /* ]]; then
                fastq1_abs=$PWD/$fastq1_abs
                fastq2_abs=$PWD/$fastq2_abs
            fi
        fi

        echo "FASTQs:"
        echo $fastq1_abs
        echo $fastq2_abs
    
		mkdir star_index
    tar -xvvf ${star_index} -C star_index --strip-components=1

		STAR \
		--genomeDir star_index \
		--runThreadN ${threads} \
		--readFilesIn ${fastq1} ${fastq2} \
		--readFilesCommand "gunzip -c" \
		${"--sjdbOverhang "+(read_length-1)} \
		--outSAMtype BAM SortedByCoordinate \
		--twopassMode Basic \
		--limitBAMsortRAM ${star_mem+"000000000"} \
		--limitOutSJcollapsed ${default=1000000 star_limitOutSJcollapsed} \
    --quantMode TranscriptomeSAM GeneCounts
    --outSAMattrRGline ${RG_line}
		--outFileNamePrefix ${base_name}.
	>>>

	output {
		File bam_file = "${base_name}.Aligned.sortedByCoord.out.bam"
    File bam_index= "${base_name}.Aligned.sortedByCoord.out.bam.bai"
    File transcriptome_bam = "${base_name}.Aligned.toTranscriptome.out.bam"
    File read_counts = "${base_name}.ReadsPerGene.out.tab.gz"
		File output_log_final = "${base_name}.Log.final.out"
		File output_log = "${base_name}.Log.out"
		File output_log_progress = "${base_name}.Log.progress.out"
		File output_SJ = "${base_name}.SJ.out.tab"
	}
