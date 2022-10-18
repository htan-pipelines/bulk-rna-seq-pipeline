task MiXCR {
    File mi_license 
    File fastq1
    File fastq2
    String docker
    String species
    String material
    Int preemptible_count
    String prefix

    command <<<
        mixcr activate-license < ${mi_license}
        mixcr analyze shotgun --starting-material ${material} -s ${species} --only-productive ${fastq1} ${fastq2} ${prefix}
    >>>
        output {
        File report = "${prefix}.report"
        File ALL = "${prefix}.clonotypes.ALL.txt"
        File clns = "${prefix}.clns"
        File vdjca = "${prefix}.vdjca"
        }

        runtime {
        disks: "local-disk 64 HDD"
        memory: "16 GB"
        docker: docker
        preemptible: preemptible_count
        }
}

workflow MiXCR_workflow {
    call MiXCR
}
