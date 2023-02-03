

task FASTQC {
    File fastq1
    File? fastq2
    String fwdfastq = sub(basename(fastq1),".f.*q.*$","")
    String revfastq = sub(basename(fastq2),".f.*q.*$","")
    String prefix
    # runtime values

    String fastqc_docker
    Int machine_mem_mb = ceil((size(fastq1, "Gi")) + 6) * 2200
    Int cpu = 16
    # multiply input size by 2.2 to account for fastq file size + 20% overhead, add size of reference.
    Int disk = ceil((size(fastq1, "Gi") * 5.5))
    # by default request non preemptible machine
    Int preemptible = 0



  command {
        set -euo pipefail
        /FastQC/fastqc -t 1 -o '.' \
        ${fastq1} ${fastq2}
 }


  runtime {

    docker: fastqc_docker
    memory: "${machine_mem_mb} MiB"
    disks: "local-disk ${disk} SSD"
    cpu: cpu
    preemptible: preemptible
  }
   

   output{
    File fastqc_1_html=glob("${fwdfastq}_fastqc.html")
    File fastqc_1_zip=glob("${fwdfastq}_fastqc.zip")
    File fastqc_2_html=glob("${revfastq}_fastqc.html")
    File fastqc_2_zip=glob("${revfastq}_fastqc.zip")
  }
}

workflow FASTQC_workflow {

 call FASTQC

}
