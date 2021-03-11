task MiXCR {
    File fastq1
    File fastq2
    String docker
    String species
    String material
    Int machine_mem_mb = ceil((size(fastq1, "Gi")) + 6) * 2200
    Int preemptible_count
    String prefix

    command <<<
        mixcr analyze shotgun --starting-material ${material} -s ${species} --only-productive ${fastq1} ${fastq2} ${prefix}
    >>>
        output {
        File report = "${prefix}.report"
        File ALL = "${prefix}.clonotypes.all.txt"
        File clns = "${prefix}.clns"
        File vdjca = "${prefix}.vdjca"
        }

        runtime {
        disks: "local-disk 1 HDD"
        memory: "${machine_mem_mb} MiB"
        docker: docker
        preemptible: preemptible_count
        }
}

workflow MiXCR_workflow {
    call MiXCR
}
