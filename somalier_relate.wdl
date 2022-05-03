
task somalier_relate {
    Array[File] somalier_counts
    Int preemptible_count

    command <<<
          somalier relate --min-ab 0.2 ${sep=' ' somalier_counts} 
    >>>

        output {
          File somalier_pairs = "somalier.pairs.tsv"
          File somalier_samples = "somalier.samples.tsv"
          File somalier_html = "somalier.html"
        }

        runtime {
        disks: "local-disk 10 HDD"
        memory: "2 GB"
        docker: "docker.io/brentp/somalier:latest"
        preemptible: preemptible_count
    }
  }
workflow somalier_relate_workflow {
  call somalier_relate
  }
