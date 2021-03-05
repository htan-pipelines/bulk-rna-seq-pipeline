task star_fusion_kickstart {
    File? chimeric_out_junction
    File genome
    String sample_id
    Int preemptible
    String docker
    Int cpu
    String memory
    Float extra_disk_space
    Float fastq_disk_space_multiplier
    Float genome_disk_space_multiplier
    String? additional_flags
    Boolean use_ssd

  command <<<

        set -e

        mkdir -p ${sample_id}
        mkdir -p genome_dir

        pbzip2 -dc ${genome} | tar x -C genome_dir --strip-components 1

        /usr/local/src/STAR-Fusion/STAR-Fusion \
        --genome_lib_dir `pwd`/genome_dir/ctat_genome_lib_build_dir \
        -J ${chimeric_out_junction} \
        --output_dir ${sample_id} \
        --CPU ${cpu} \
        ${"" + additional_flags}

  >>>
  runtime {
    preemptible: "${preemptible}"
    disks: "local-disk " + ceil((fastq_disk_space_multiplier * (size(chimeric_out_junction, "GB"))) + size(genome, "GB") * genome_disk_space_multiplier + extra_disk_space) + " " + (if use_ssd then "SSD" else "HDD")
    docker: "${docker}"
    cpu: "${cpu}"
    memory: "${memory}"
  }
  output {
    File fusion_predictions = "${sample_id}/star-fusion.fusion_predictions.tsv"
    File fusion_predictions_abridged = "${sample_id}/star-fusion.fusion_predictions.abridged.tsv"
  }

}

workflow star_fusion {
    call star_fusion_kickstart
}
