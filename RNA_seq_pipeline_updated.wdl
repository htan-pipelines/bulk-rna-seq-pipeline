
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/FASTQC.wdl" as fastqc
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/RSEQC_TIN.wdl" as rseqc_TIN
import "https://api.firecloud.org/ga4gh/v1/tools/broadinstitute_gtex:star_v1-0_BETA/versions/8/plain-WDL/descriptor" as star_wdl
import "https://api.firecloud.org/ga4gh/v1/tools/broadinstitute_gtex:markduplicates_v1-0_BETA/versions/6/plain-WDL/descriptor" as markduplicates_wdl
import "https://api.firecloud.org/ga4gh/v1/tools/broadinstitute_gtex:rsem_v1-0_BETA/versions/6/plain-WDL/descriptor" as rsem_wdl
import "https://api.firecloud.org/ga4gh/v1/tools/broadinstitute_gtex:rnaseqc2_v1-0_BETA/versions/3/plain-WDL/descriptor" as rnaseqc_wdl
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/gtfToCallingIntervals.wdl" as gtftocallingintervals_wdl
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/SplitNCigarReads.wdl" as splitncigar
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/BaseRecalibrator.wdl" as basecalibrator
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/ApplyBQSR.wdl" as applyBQSR
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/ScatterIntervalList.wdl" as scatterintervallist
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/HaplotypeCaller.wdl" as haplotypecaller
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/MergeVCFs.wdl" as mergeVCF
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/VariantFiltration.wdl" as variantfiltration
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/rsem_reference_francois.wdl" as reference_rsem_wdl
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/ReadGroup.wdl" as readgroup_wdl
import "https://raw.githubusercontent.com/htan-pipelines/bulk-rna-seq-pipeline/master/somalier.wdl" as somalier_extract

workflow rnaseq_pipeline_workflow {

    File refFasta
    File refFastaIndex
    File refDict
    
    String prefix
    String RG_ID
    String library_id
    String platform
    String platform_unit
    String platform_model
    File gene_bed
    String? gatk4_docker_override
    String gatk4_docker = select_first([gatk4_docker_override, "broadinstitute/gatk:latest"])
    String? gatk_path_override
    String gatk_path = select_first([gatk_path_override, "/gatk/gatk"])
   
    Array[File] knownVcfs
    Array[File] knownVcfsIndices

    File dbSnpVcf
    File dbSnpVcfIndex
    File annotationsGTF
    
    Int preemptible_count
    Int? minConfidenceForVariantCalling

    ## Optional user optimizations
    Int? haplotypeScatterCount
    Int scatterCount = select_first([haplotypeScatterCount, 6])
    
    call readgroup_wdl.ReadGroup {
        input: SM=prefix, RG=RG_ID, LB=library_id, PL=platform, PU=platform_unit, PM=platform_model
    }
    call fastqc.FASTQC{
        input: prefix=prefix
    }     
    call star_wdl.star {
        input: prefix=prefix, outSAMattrRGline = ReadGroup.Read_group_line
    }
    call somalier_extract.somalier_extract {
    	input: prefix=prefix, ref_fasta=refFasta, ref_fasta_index=refFastaIndex, input_bam=star.bam_file, input_bam_index=star.bam_index, preemptible_count=preemptible_count
    }
    call markduplicates_wdl.markduplicates {
        input: input_bam=star.bam_file, prefix=prefix
    }
    call rseqc_TIN.RSEQC_TIN {
        input: bam_input = star.bam_file, gene_bed = gene_bed, bam_index = star.bam_index
    }
    
    call rsem_reference {
        input: reference_fasta = refFasta, annotation_gtf = annotationsGTF, prefix =prefix
    }
    
    call rsem_wdl.rsem {
        input: transcriptome_bam=star.transcriptome_bam, prefix=prefix, rsem_reference = rsem_reference.rsem_reference
    }

    call rnaseqc_wdl.rnaseqc2 {
        input: bam_file=markduplicates.bam_file, sample_id=prefix
    }
    call gtftocallingintervals_wdl.gtfToCallingIntervals {
        input:
            gtf = annotationsGTF,
            ref_dict = refDict,
            preemptible_count = preemptible_count,
            gatk_path = gatk_path,
            docker = gatk4_docker
    }
   call DupMark {
	    input:
		input_bam = star.bam_file,
		base_name = prefix + ".dedupped",
		preemptible_count = preemptible_count,
		docker = gatk4_docker,
		gatk_path = gatk_path
	}
    
  call splitncigar.SplitNCigarReads {
        input:
            input_bam = DupMark.output_bam,
            input_bam_index = DupMark.output_bam_index,
            base_name = prefix + ".split",
            ref_fasta = refFasta,
            ref_fasta_index = refFastaIndex,
            ref_dict = refDict,
            interval_list = gtfToCallingIntervals.interval_list,
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }

    call basecalibrator.BaseRecalibrator {
        input:
            input_bam = SplitNCigarReads.output_bam,
            input_bam_index = SplitNCigarReads.output_bam_index,
            recal_output_file = prefix + ".recal_data.csv",
            dbSNP_vcf = dbSnpVcf,
            dbSNP_vcf_index = dbSnpVcfIndex,
            known_indels_sites_VCFs = knownVcfs,
            known_indels_sites_indices = knownVcfsIndices,
            ref_dict = refDict,
            ref_fasta = refFasta,
            ref_fasta_index = refFastaIndex,
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }

    call applyBQSR.ApplyBQSR {
        input:
            input_bam =  SplitNCigarReads.output_bam,
            input_bam_index = SplitNCigarReads.output_bam_index,
            base_name = prefix + ".aligned.duplicates_marked.recalibrated",
            ref_fasta = refFasta,
            ref_fasta_index = refFastaIndex,
            ref_dict = refDict,
            recalibration_report = BaseRecalibrator.recalibration_report,
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }


    call scatterintervallist.ScatterIntervalList {
        input:
            interval_list = gtfToCallingIntervals.interval_list,
            scatter_count = scatterCount,
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }


    scatter (interval in ScatterIntervalList.out) {
        call haplotypecaller.HaplotypeCaller {
            input:
                input_bam = ApplyBQSR.output_bam,
                input_bam_index = ApplyBQSR.output_bam_index,
                base_name = prefix + ".hc",
                interval_list = interval,
                ref_fasta = refFasta,
                ref_fasta_index = refFastaIndex,
                ref_dict = refDict,
                dbSNP_vcf = dbSnpVcf,
                dbSNP_vcf_index = dbSnpVcfIndex,
                stand_call_conf = minConfidenceForVariantCalling,
                preemptible_count = preemptible_count,
                docker = gatk4_docker,
                gatk_path = gatk_path
        }

        File HaplotypeCallerOutputVcf = HaplotypeCaller.output_vcf
        File HaplotypeCallerOutputVcfIndex = HaplotypeCaller.output_vcf_index
    }

    call mergeVCF.MergeVCFs {
        input:
            input_vcfs = HaplotypeCallerOutputVcf,
            input_vcfs_indexes =  HaplotypeCallerOutputVcfIndex,
            output_vcf_name = prefix + ".g.vcf.gz",
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }
    
    call variantfiltration.VariantFiltration {
        input:
            input_vcf = MergeVCFs.merge_vcf,
            input_vcf_index = MergeVCFs.merge_vcf_index,
            base_name = prefix + ".variant_filtered.vcf.gz",
            ref_fasta = refFasta,
            ref_fasta_index = refFastaIndex,
            ref_dict = refDict,
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }
  }
  
 task rsem_reference {

    File reference_fasta
    File annotation_gtf
    String prefix

    Int memory
    Int disk_space
    Int num_threads
    Int num_preempt

    command {
        mkdir ${prefix} && cd ${prefix}
        rsem-prepare-reference ${reference_fasta} rsem_reference --gtf ${annotation_gtf} --num-threads ${num_threads}
        cd .. && tar -cvzf ${prefix}.tar.gz ${prefix}
    }

    output {
        File rsem_reference = "${prefix}.tar.gz"
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

task DupMark {

 	File input_bam
 	String base_name

  String gatk_path

  String docker
 	Int preemptible_count

 	command <<<
 	    ${gatk_path} \
 	        MarkDuplicates \
 	        --INPUT ${input_bam} \
 	        --OUTPUT ${base_name}.bam  \
 	        --CREATE_INDEX true \
 	        --VALIDATION_STRINGENCY SILENT \
 	        --METRICS_FILE ${base_name}.metrics
 	>>>

 	output {
 		File output_bam = "${base_name}.bam"
 		File output_bam_index = "${base_name}.bai"
 		File metrics_file = "${base_name}.metrics"
 	}

	runtime {
		disks: "local-disk " + sub(((size(input_bam,"GB")+1)*3),"\\..*","") + " HDD"
		docker: docker
		memory: "4 GB"
		preemptible: preemptible_count
	}
}
