task gtfToCallingIntervals {
    File gtf
    File ref_dict
    Int memory
    Int disk_space
    Int num_threads

    String output_name = basename(gtf, ".gtf") + ".exons.interval_list"

    String docker
    String gatk_path
    Int preemptible_count

    command <<<
        set -euo pipefail
        Rscript --no-save -<<'RCODE'
            gtf = read.table("${gtf}", sep="\t")
            gtf = subset(gtf, V3 == "exon")
            write.table(data.frame(chrom=gtf[,'V1'], start=gtf[,'V4'], end=gtf[,'V5']), "exome.bed", quote = F, sep="\t", col.names = F, row.names = F)
        RCODE

        awk '{print $1 "\t" ($2 - 1) "\t" $3}' exome.bed > exome.fixed.bed

        ${gatk_path} \
            BedToIntervalList \
            -I exome.fixed.bed \
            -O ${output_name} \
            -SD ${ref_dict}
    >>>

    output {
        File interval_list = "${output_name}"
    }

    runtime {
        docker: docker
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: preemptible_count
    }
}
workflow CallingIntervals{
    call gtfToCallingIntervals
}
