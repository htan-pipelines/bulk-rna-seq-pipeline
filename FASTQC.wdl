


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

    String fastq_name = sub(sub(basename(fastq1), "\\.fastq.gz$", ""), "\\.fq.gz$", "" )



  command {
        /FastQC/fastqc -t 1 -o . \
        $fastq1 $fastq2
 }


  runtime {

    docker: fastqc_docker
    memory: "${machine_mem_mb} MiB"
    disks: "local-disk ${disk} SSD"
    cpu: cpu
    preemptible: preemptible
  }
   

   output{
    File fastqc_html="${fastq_name}_fastqc.html"
    File fastqc_zip="${fastq_name}_fastqc.zip"
  }
}

workflow FASTQC_workflow {

 call FASTQC

}
