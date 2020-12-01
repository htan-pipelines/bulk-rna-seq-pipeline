
task somalier_relate {
    File somalier_counts
    File ped_input
    String docker
    Int preemptible_count

    command <<<
          somalier relate --ped ${ped_input} ${somalier_counts}
    >>>

        output {
          File somalier_pairs = "somalier.pairs.tsv"
          File somalier_samples = "somalier.samples.tsv"
          File somalier_html = "somalier.html"
        }

        runtime {
        disks: "local-disk 1 HDD"
        memory: "8 GB"
        docker: docker
        preemptible: preemptible_count
    }
  }
workflow somalier_relate_workflow {
  call somalier_relate
  }
