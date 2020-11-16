
#Cromwell version 52


import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/somalier.wdl" as somalier_extract_wdl
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/somalier_relate.wdl" as somalier_relate_wdl
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/combineVCF.wdl" as combineVCF_wdl
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/VCFtools.wdl" as VCFtools_wdl

workflow full_somalier_workflow {

    
    Array[File] VCF_files
    String prefix
    
    File refFasta
    Array[File] knownVcfs
    Array[File] knownVcfsIndices

    String somalier_docker
    
    Int preemptible_count


    call combineVCF_wdl.combineVCF{
        input: prefix=prefix, vcf_list = VCF_files, ref_fasta=refFasta
    }     
    call VCFtools_wdl.VCFtools {
        input: prefix=prefix, vcf_input = combineVCF.combined_vcf_output
    }
    call somalier_extract_wdl.extract {
        input: input_known_indel_sites_VCF=knownVcfs, ref_fasta=refFasta, input_vcf=combineVCF.combined_vcf_output, prefix=prefix
    }
    call somalier_relate_wdl.relate{
        input: input_vcf=combineVCF.combined_vcf_output, ped_input=VCFtools.ped_file
    }


}