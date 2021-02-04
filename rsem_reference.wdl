task rsem_reference {

    File fasta_path
    File gtf_path
    File dict_file

    String species="Homo sapiens"
    String ucsc_build="hg38"
    String assembly="GRCh38"
    String ensembl="100"
    String type="base"

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt
    
    String docker



    command {
        

        readarray -t dict_chr < \
            <(grep "^@SQ" ${dict_file} | cut -f2 | sed -r 's/^SN://')
        dict_chr_regex="$(IFS="|"; echo "^(${dict_chr[*]})\t")"
        
        rsem-prepare-reference \
            --gtf <(grepz -P "${dict_chr_regex}" ${gtf_file}) \
            ${fasta_path} ${ucsc_build}

    }

    output {
        File rsem_reference="${ucsc_build}.tar.gz"
    }

    runtime {
        docker: docker
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"
    }
}


workflow rsem_workflow {
    call rsem_reference
}
