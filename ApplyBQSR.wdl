task ApplyBQSR {

    File input_bam
    File input_bam_index
    String base_name
    File recalibration_report

    File ref_dict
    File ref_fasta
    File ref_fasta_index

    String gatk_path

    String docker
    Int preemptible_count

    command <<<
        ${gatk_path} \
            --java-options "-XX:+PrintFlagsFinal -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps \
            -XX:+PrintGCDetails -Xloggc:gc_log.log \
            -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Xms3000m" \
            ApplyBQSR \
            --add-output-sam-program-record \
            -R ${ref_fasta} \
            -I ${input_bam} \
            --use-original-qualities \
            -O ${base_name}.bam \
            --bqsr-recal-file ${recalibration_report}
    >>>

    output {
        File output_bam = "${base_name}.bam"
        File output_bam_index = "${base_name}.bai"
    }

    runtime {
        memory: "3500 MB"
        disks: "local-disk " + sub((size(input_bam,"GB")*4)+30, "\\..*", "") + " HDD"
        preemptible: preemptible_count
        docker: docker
    }
}

workflow ApplyBQSR_workflow{
    call ApplyBQSR
}
