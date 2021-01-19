task UBam {

    # Command parameters
    String sample_name
    File fastq_1
    File fastq_2
    String readgroup_name
    String library_name
    String platform_unit
    String run_date
    String platform_name
    String sequencing_center
    String gatk_path

    # Runtime parameters
    Int addtional_disk_space_gb = 10
    Int machine_mem_gb = 7
    Int preemptible_attempts = 3
    String docker
    Int command_mem_gb = machine_mem_gb - 1
    Int disk_space_gb = ceil((size(fastq_1, "GB") + size(fastq_2, "GB")) * 2 ) + addtional_disk_space_gb
    
  command <<<
    ${gatk_path} --java-options "-Xmx${command_mem_gb}g" \
    FastqToSam \
    --FASTQ ${fastq_1} \
    --FASTQ2 ${fastq_2} \
    --OUTPUT ${readgroup_name}.unmapped.bam \
    --READ_GROUP_NAME ${readgroup_name} \
    --SAMPLE_NAME ${sample_name} \
    --LIBRARY_NAME ${library_name} \
    --PLATFORM_UNIT ${platform_unit} \
    --RUN_DATE ${run_date} \
    --PLATFORM ${platform_name} \
    --SEQUENCING_CENTER ${sequencing_center} 
  >>>
    output {
    File output_unmapped_bam = "${readgroup_name}.unmapped.bam"
  }
  runtime {
    docker: docker
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_space_gb + " HDD"
    preemptible: preemptible_attempts
  }
}

workflow UBam_workflow {
  call Ubam
}
