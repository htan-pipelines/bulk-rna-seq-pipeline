


task FASTQC {
    File fastq1
    File? fastq2
    String prefix
    # runtime values

    String fastqc_docker
    Int machine_mem_mb = ceil((size(fastq1, "Gi")) + 6) * 2200
    Int cpu = 16
    # multiply input size by 2.2 to account for output fastq file + 20% overhead, add size of reference.
    Int disk = ceil((size(fastq1, "Gi") * 5.5))
    # by default request non preemptible machine
    Int preemptible = 0



  command {
      
      
        if [[ ${fastq1} == *".tar" || ${fastq1} == *".tar.gz" ]]; then
            tar -xvvf ${fastq1}
            fastq1_abs=$(for f in *_1.fastq*; do echo "$(pwd)/$f"; done | paste -s -d ',')
            fastq2_abs=$(for f in *_2.fastq*; do echo "$(pwd)/$f"; done | paste -s -d ',')
            if [[ $fastq1_abs == *"*_1.fastq*" ]]; then  # no paired-end FASTQs found; check for single-end FASTQ
                fastq1_abs=$(for f in *.fastq*; do echo "$(pwd)/$f"; done | paste -s -d ',')
                fastq2_abs=''
            fi
        else
            # make sure paths are absolute
            fastq1_abs=${fastq1}
            fastq2_abs=${fastq2}
            if [[ $fastq1_abs != /* ]]; then
                fastq1_abs=$PWD/$fastq1_abs
                fastq2_abs=$PWD/$fastq2_abs
            fi
        fi



        echo "FASTQs:"
        echo $fastq1_abs
        echo $fastq2_abs
      
        fastqc -t 1 -o . \
        $fastq1_abs $fastq2_abs
 }


  runtime {

    docker: fastqc_docker
    memory: "${machine_mem_mb} MiB"
    disks: "local-disk ${disk} SSD"
    cpu: cpu
    preemptible: preemptible
  }
   

   output{
    File fastqc_html="*_fastqc.html"
    File fastqc_zip="*_fastqc.zip"
  }
}

workflow FASTQC_workflow {

 call FASTQC

}
