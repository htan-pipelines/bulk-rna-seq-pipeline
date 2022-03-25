

task FASTQC {
    File fastq1
    File? fastq2
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
    File fastqc_1_html=glob("*${fastq1}_fastqc.html")[0]
    File fastqc_1_zip=glob("*${fastq1}_fastqc.zip")[0]
    File fastqc_2_html=glob("*${fastq2}_fastqc.html")[0]
    File fastqc_2_zip=glob("*${fastq2}_fastqc.zip")[0]
  }
}

workflow FASTQC_workflow {

 call FASTQC

}
