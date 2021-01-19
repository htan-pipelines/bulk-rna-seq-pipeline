task RevertSam {
    File input_bam
    String base_name
    String sort_order

    String gatk_path

    String docker
    Int preemptible_count

    command <<<
        ${gatk_path} \
        	RevertSam \
        	--INPUT ${input_bam} \
        	--OUTPUT ${base_name}.bam \
            --VALIDATION_STRINGENCY SILENT \
        	--ATTRIBUTE_TO_CLEAR FT \
        	--ATTRIBUTE_TO_CLEAR CO \
        	--SORT_ORDER ${sort_order}
    >>>

    output {
        File output_bam = "${base_name}.bam"
    }

    runtime {
        docker: docker
        disks: "local-disk " + sub(((size(input_bam,"GB")+1)*5),"\\..*","") + " HDD"
        memory: "4 GB"
        preemptible: preemptible_count
     }
    
    }
    
    workflow RevertSam_workflow {
      call RevertSam
    }
