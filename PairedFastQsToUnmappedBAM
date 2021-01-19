task PairedFastQsToUnmappedBAM {
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

  # Runtime parameters
  Int? disk_space_gb
  Int? machine_mem_gb
  Int? preemptible_attempts
  String docker
  String gatk_path

  command {
    ${gatk_path} --java-options "-Xmx3000m" \
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
  }
  runtime {
    docker: docker
    memory: select_first([machine_mem_gb, 10]) + " GB"
    cpu: "1"
    disks: "local-disk " + select_first([disk_space_gb, 100]) + " HDD"
    preemptible: select_first([preemptible_attempts, 3])
  }
  output {
    File output_bam = "${readgroup_name}.unmapped.bam"
  }
}

workflow UBam_workflow{
 call PairedFastQsToUnmappedBAM
}
