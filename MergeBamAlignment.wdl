task MergeBamAlignment {

    File ref_fasta
    File ref_dict

    File unaligned_bam
    File star_bam
    String base_name

    String gatk_path

    String docker
    Int preemptible_count
    #Using default for max_records_in_ram
 
    command <<<
        ${gatk_path} \
            MergeBamAlignment \
            --REFERENCE_SEQUENCE ${ref_fasta} \
            --UNMAPPED_BAM ${unaligned_bam} \
            --ALIGNED_BAM ${star_bam} \
            --OUTPUT ${base_name}.bam \
            --INCLUDE_SECONDARY_ALIGNMENTS false \
            --PAIRED_RUN False \
            --VALIDATION_STRINGENCY SILENT
    >>>
 
    output {
        File output_bam="${base_name}.bam"
    }
    runtime {
        docker: docker
        disks: "local-disk " + sub(((size(unaligned_bam,"GB")+size(star_bam,"GB")+1)*5),"\\..*","") + " HDD"
        memory: "4 GB"
        preemptible: preemptible_count
    }
}
workflow MergeBamAlignment_workflow {
  call MergeBamAlignment
}
