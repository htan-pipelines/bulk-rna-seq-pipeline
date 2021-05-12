task MergeVCFs {
    Array[File] input_vcfs
    Array[File] input_vcfs_indexes
    String output_vcf_name

    Int? disk_size = 5

    String gatk_path

    String docker
    Int preemptible_count


    command <<<
        ${gatk_path} --java-options "-Xms2000m"  \
            MergeVcfs \
            --INPUT ${sep=' --INPUT ' input_vcfs} \
            --OUTPUT ${output_vcf_name}
    >>>

    output {
        File merge_vcf = output_vcf_name
        File merge_vcf_index = "${output_vcf_name}.tbi"
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
