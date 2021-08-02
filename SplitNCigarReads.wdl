task SplitNCigarReads {

  File input_bam
  File input_bam_index
  String base_name
  File interval_list

  File ref_fasta
  File ref_fasta_index
  File ref_dict
  
  String gatk_path
  String docker
  Int preemptible_count

    command <<<
        ${gatk_path} \
                SplitNCigarReads \
                -R ${ref_fasta} \
                -I ${input_bam} \
                -O ${base_name}.bam 
    >>>

        output {
                File output_bam = "${base_name}.bam"
                File output_bam_index = "${base_name}.bai"
        }

    runtime {
        disks: "local-disk " + sub(((size(input_bam,"GB")+1)*5 + size(ref_fasta,"GB")),"\\..*","") + " HDD"
        docker: docker
        memory: "8 GB"
        preemptible: preemptible_count
    }
}
workflow SplitNCigarReads_workflow{
  call SplitNCigarReads
}
