task BaseRecalibrator {

    File input_bam
    File input_bam_index
    String recal_output_file

    File dbSNP_vcf
    File dbSNP_vcf_index
    Array[File] known_indels_sites_VCFs
    Array[File] known_indels_sites_indices

    File ref_dict
    File ref_fasta
    File ref_fasta_index

    String gatk_path

    String docker
    Int preemptible_count

    command <<<
        ${gatk_path} --java-options "-XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -XX:+PrintFlagsFinal \
            -Xlog:gc::utctime -XX:+PrintGCDateStamps -XX:+PrintGCDetails \
            -Xloggc:gc_log.log -Xms4000m" \
            BaseRecalibrator \
            -R ${ref_fasta} \
            -I ${input_bam} \
            --use-original-qualities \
            -O ${recal_output_file} \
            -known-sites ${dbSNP_vcf} \
            -known-sites ${sep=" --known-sites " known_indels_sites_VCFs}
    >>>

    output {
        File recalibration_report = recal_output_file
    }

    runtime {
        memory: "16 GB"
        disks: "local-disk " + sub((size(input_bam,"GB")*3)+30, "\\..*", "") + " HDD"
        docker: docker
        preemptible: preemptible_count
    }
}
workflow BaseRecalibrator_workflow{
    call BaseRecalibrator
}
