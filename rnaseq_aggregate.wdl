task rnaseqc2_aggregate {



    Array[File] tpm_gcts
    Array[File] count_gcts
    Array[File] exon_count_gcts
    Array[File] metrics_tsvs
    String prefix



    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt



    command {

        set -euo pipefail
        echo $(date +"[%b %d %H:%M:%S] Combining TPM GCTs")
        python3 /src/combine_GCTs.py ${write_lines(tpm_gcts)} "${prefix}.rnaseqc_tpm"
        echo $(date +"[%b %d %H:%M:%S] Combining count GCTs")
        python3 /src/combine_GCTs.py ${write_lines(count_gcts)} "${prefix}.rnaseqc_counts"
        echo $(date +"[%b %d %H:%M:%S] Combining exon count GCTs")
        python3 /src/combine_GCTs.py ${write_lines(exon_count_gcts)} "${prefix}.rnaseqc_exon_counts"
        echo $(date +"[%b %d %H:%M:%S] Combining metrics")
        python3 /src/aggregate_rnaseqc_metrics.py ${write_lines(metrics_tsvs)} ${prefix}

    }



    output {

        File tpm_gct="${prefix}.rnaseqc_tpm.gct.gz"
        File count_gct="${prefix}.rnaseqc_counts.gct.gz"
        File exon_count_gct="${prefix}.rnaseqc_exon_counts.gct.gz"
        File metrics="${prefix}.metrics.tsv"

    }



    runtime {

        docker: "gcr.io/broad-cga-francois-gtex/gtex_rnaseq:V9"
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"

    }



    meta {

        author: "Francois Aguet"

    }

}

task MultiQC{
  input {
    File rseqc_bam_stat_files
    File rseqc_geneBody_coverage_files
    File rseqc_infer_experiment_files
    File rseqc_inner_distance_files
    File rseqc_junction_annotation_files
    File rseqc_junction_saturation_files
    File rseqc_read_distribution_files
    File rseqc_read_duplication_files
    File rseqc_read_GC_files
    File star_files
    String filename

    # runtime values

    String docker = "quay.io/humancellatlas/secondary-analysis-star:v0.2.2-2.5.3a-40ead6e"
    Int machine_mem_mb = ceil((size(tar_star_reference, "Gi")) + 6) * 1100
    Int cpu = 16
    # multiply input size by 2.2 to account for output bam file + 20% overhead, add size of reference.
    Int disk = ceil((size(tar_star_reference, "Gi") * 2.5) + (size(bam_input, "Gi") * 2.5))
    # by default request non preemptible machine to make sure the slow star alignment step completes
    Int preemptible = 0

  }


  command {
  # Create temporary MultiQC input file
  multiqc_input_tempfile=\$(mktemp)

  for filename in \
    '${rseqc_bam_stat_files.join("' '")}' \
    '${rseqc_geneBody_coverage_files.join("' '")}' \
    '${rseqc_infer_experiment_files.join("' '")}' \
    '${rseqc_inner_distance_files.join("' '")}' \
    '${rseqc_junction_annotation_files.join("' '")}' \
    '${rseqc_junction_saturation_files.join("' '")}' \
    '${rseqc_read_distribution_files.join("' '")}' \
    '${rseqc_read_duplication_files.join("' '")}' \
    '${rseqc_read_GC_files.join("' '")}' \
    '${star_files.join("' '")}'
  do
    echo "\$filename" >> \$multiqc_input_tempfile
  done
  
  # Run MultiQC
  multiqc -n sample_multiqc --file-list \$multiqc_input_tempfile
}

  runtime {
    docker: docker
    memory: "${machine_mem_mb} MiB"
    disks: "local-disk ${disk} SSD"
    cpu: cpu
    preemptible: preemptible
  }
    output {
    File multiqc_output_reseqc = multiqc_rseqc_*.txt
    File mutiqc_output_star = multiqc_star.txt
    File multiqc_output = sample_multiqc.html
  }

}





workflow rnaseq_aggregate_workflow {

    call rnaseqc2_aggregate

    call multiQC

}
