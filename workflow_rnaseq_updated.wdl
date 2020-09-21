
import "https://api.firecloud.org/ga4gh/v1/tools/broadinstitute_gtex:star_v1-0_BETA/versions/7/plain-WDL/descriptor" as star_wdl
import "https://api.firecloud.org/ga4gh/v1/tools/broadinstitute_gtex:markduplicates_v1-0_BETA/versions/5/plain-WDL/descriptor" as markduplicates_wdl
import "https://api.firecloud.org/ga4gh/v1/tools/broadinstitute_gtex:rsem_v1-0_BETA/versions/5/plain-WDL/descriptor" as rsem_wdl
import "https://api.firecloud.org/ga4gh/v1/tools/broadinstitute_gtex:rnaseqc2_v1-0_BETA/versions/2/plain-WDL/descriptor" as rnaseqc_wdl


workflow rnaseq_pipeline_workflow {

    File refFasta
    File refFastaIndex
    File refDict
    
    String prefix
    File gene_bed
    String? gatk4_docker_override
    String gatk4_docker = select_first([gatk4_docker_override, "broadinstitute/gatk:latest"])
    String? gatk_path_override
    String gatk_path = select_first([gatk_path_override, "/gatk/gatk"])
    String? star_docker_override
    String star_docker = select_first([star_docker_override, "quay.io/humancellatlas/secondary-analysis-star:v0.2.2-2.5.3a-40ead6e"])

    Array[File] knownVcfs
    Array[File] knownVcfsIndices

    File dbSnpVcf
    File dbSnpVcfIndex

    Int? minConfidenceForVariantCalling

    ## Optional user optimizations
    Int? haplotypeScatterCount
    Int scatterCount = select_first([haplotypeScatterCount, 6])



    call FASTQC.FASTQC{
        input: prefix=prefix
    }     
    call star_wdl.star {
        input: prefix=prefix
    }
    call markduplicates_wdl.markduplicates {
        input: input_bam=2ndpass.bam_file, prefix=prefix
    }
    call reseqc_TIN.rseqc_TIN {
        input: bam_input = star.bam_file, gene_bed = gene_bed, prefix=prefix
    }
    call rsem_wdl.rsem {
        input: transcriptome_bam=2ndpass.transcriptome_bam, prefix=prefix
    }

    call rnaseqc_wdl.rnaseqc2 {
        input: bam_file=markduplicates.bam_file, prefix=prefix
    }
     
    call gtfToCallingIntervals {
        input:
            gtf = annotationsGTF,
            ref_dict = refDict,
            preemptible_count = preemptible_count,
            gatk_path = gatk_path,
            docker = gatk4_docker
    }

    call SplitNCigarReads {
        input:
            input_bam = MarkDuplicates.output_bam,
            input_bam_index = MarkDuplicates.output_bam_index,
            base_name = prefix + ".split",
            ref_fasta = refFasta,
            ref_fasta_index = refFastaIndex,
            ref_dict = refDict,
            interval_list = gtfToCallingIntervals.interval_list,
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }


    call BaseRecalibrator {
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

    call ApplyBQSR {
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


    call ScatterIntervalList {
        input:
            interval_list = gtfToCallingIntervals.interval_list,
            scatter_count = scatterCount,
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }


    scatter (interval in ScatterIntervalList.out) {
        call HaplotypeCaller {
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

    call MergeVCFs {
        input:
            input_vcfs = HaplotypeCallerOutputVcf,
            input_vcfs_indexes =  HaplotypeCallerOutputVcfIndex,
            output_vcf_name = prefix + ".g.vcf.gz",
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }
    
    call VariantFiltration {
        input:
            input_vcf = MergeVCFs.output_vcf,
            input_vcf_index = MergeVCFs.output_vcf_index,
            base_name = prefix + ".variant_filtered.vcf.gz",
            ref_fasta = refFasta,
            ref_fasta_index = refFastaIndex,
            ref_dict = refDict,
            preemptible_count = preemptible_count,
            docker = gatk4_docker,
            gatk_path = gatk_path
    }

}

