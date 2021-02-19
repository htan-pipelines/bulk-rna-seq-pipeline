task MergeVCFs {
    Array[File] input_vcfs
    Array[File] input_vcfs_indexes
    String output_vcf_name

    Int? disk_size = 5

    String gatk_path

    String docker
    Int preemptible_count

    # Using MergeVcfs instead of GatherVcfs so we can create indices
    # See https://github.com/broadinstitute/picard/issues/789 for relevant GatherVcfs ticket
    command <<<
        ${gatk_path} --java-options "-Xms2000m"  \
            MergeVcfs \
            --INPUT ${sep=' --INPUT ' input_vcfs} \
            --OUTPUT ${output_vcf_name}
    >>>

    output {
        File output_vcf = output_vcf_name
        File output_vcf_index = "${output_vcf_name}.tbi"
    }

    runtime {
        memory: "3 GB"
        disks: "local-disk " + disk_size + " HDD"
        docker: docker
        preemptible: preemptible_count
    }
}

workflow MergeVCFs_workflow{
    call MergeVCFs
}
