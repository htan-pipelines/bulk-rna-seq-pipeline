#!/usr/bin/env Rscript
#input = rnaseqc output
#tinfile = RSEQC_TIN output text file
#gene_file= RSEM output
#isoform_file = RSEM output
#sample.name = name of sample running through the pipeline (should be same as prefix)
#star_file = STAR output file (log file) 
#/Library/Frameworks/R.framework/Resources/bin/
#Rscript createSE.R PCGA-01-0021-025-20687-01310BX-1031643R.metrics.tsv  PCGA-01-0021-025-20687-01310BX-1031643R.Aligned.sortedByCoord.out.summary.txt gencode.v34.annotation.gtf PCGA-01-0021-025-20687-01310BX-1031643R.rsem.genes.results PCGA-01-0021-025-20687-01310BX-1031643R.rsem.isoforms.results "PCGA-01-0021-025-20687-01310BX-1031643R" PCGA-01-0021-025-20687-01310BX-1031643R.Log.final.out MS-RW-R-1_S8_R1_001_fastqc.zip MS-RW-R-1_S8_R1_001_fastqc.zip PCGA02_10044_2001586_stats.txt
httr::set_config(httr::config(ssl_verifypeer = FALSE, ssl_verifyhost = FALSE)) #Disables SSL verification

create_se <- function(input_file, tinfile, gtf, gene_file, isoform_file, sample_name, star_file, fastqc_1_file,fastqc_2_file, samtools_stats_file) {
  library(biomaRt)
  library(GenomicFeatures)
  library(SummarizedExperiment) 
  library(tidyr)
  library(ngsReports)
  
  read.wsv <- function (file, ...) {
    read.table(
      file, check.names=FALSE, header = TRUE, stringsAsFactors=FALSE,
      ...
      )
  }

  fdl_1 <- FastqcDataList(fastqc_1_file)
  fdl_2 <- FastqcDataList(fastqc_2_file)
  
  output <- list()
 
  #load fastq statistics
  fqcs <- getModule(fdl_1[[1]], "Summary")
  output[["fastqc_R1"]] <- t(fqcs)['Status',]
  names(output[['fastqc_R1']]) <- paste("fastqc_R1",gsub(" ", "_", fqcs$Category),sep = "_")
  output[["fastqc_R1"]]['fastqc_R1_Total_Reads']<- readTotals(fdl_1)$Total_Sequences
  output[["fastqc_R1"]] <-data.frame(as.list(output[['fastqc_R1']]))
  
  fqcs <- getModule(fdl_2[[1]], "Summary")
  output[["fastqc_R2"]] <- t(fqcs)['Status',]
  names(output[['fastqc_R2']]) <- paste("fastqc_R2",gsub(" ", "_", fqcs$Category),sep = "_")
  output[["fastqc_R2"]]['fastqc_R2_Total_Reads']<- readTotals(fdl_2)$Total_Sequences
  output[["fastqc_R2"]] <-data.frame(as.list(output[['fastqc_R2']]))
  
  #load samtools stats
  data <- readLines(samtools_stats_file)
  sn <- grep("^SN",data, value=TRUE)
  sn <- separate(data.frame(sn),col=1, into=c("ID", "Name","Value"), sep="\t")[,-1]
  sn$Name <- gsub(":", "", sn$Name)
  
  output[['samtools_stats']] <- t(sn)['Value',]
  names(output[['samtools_stats']]) <- paste("samtools",gsub(" ", "_", sn$Name),sep = "_")
  output[["samtools_stats"]] <-data.frame(as.list(output[['samtools_stats']]))
  
  
  #load input file
  data <- read.delim(input_file, header=FALSE, stringsAsFactors=FALSE)
  #print(dim(data))
  #print(rownames(data))
  #organize data into proper format
  names <- data[,1]
  data <- data.frame(data[,-1], stringsAsFactors = FALSE, row.names = names)
  data <- data.frame(t(data), stringsAsFactors = FALSE)
  data[,2:ncol(data)] <- sapply(data[,2:ncol(data)], as.numeric)
  rownames(data)<-sample_name
  #print(dim(data))
  #print(rownames(data))
  #load in tinfile and add to list
  output[["inputfile"]] <- data
  colnames(output[["inputfile"]]) <- paste(
    "rnaseqc", colnames(output[["inputfile"]]),sep="_")

  # Get tab-delimited column names from first line of first file 
  output[["tinfile"]] <- c(readLines(tinfile, n=1), 
                           sapply(tinfile, scan, what="", n=1, sep="\n", skip=1, quiet=TRUE)) # Read tab-delimited contents of second lines of all files
  # Parse the character vector into a data frame
  output[["tinfile"]] <- read.wsv(
    textConnection(output[["tinfile"]]), row.names=1
  )
  #print(output[["tinfile"]])
  # Add a prefix to the column names
  colnames(output[["tinfile"]]) <- gsub(
    "_$", "", gsub("[' \"\\(\\)\\-]", "_", colnames(output[["tinfile"]])))
  
  star <- read.delim(star_file,header=F,stringsAsFactors = F)
  #print(star)
  #remove unnecessary rows
  star <- star[-c(1:4,7,22,27,34),]
  star.names <- star[,1]
  star <- data.frame(star[,-1], stringsAsFactors = FALSE, row.names = star.names)
  star <- data.frame(t(star), stringsAsFactors = FALSE)
  colnames(star)<-c("STAR_total_reads","STAR_avg_input_read_length","STAR_uniquely_mapped","STAR_uniquely_mapped_percent","STAR_avg_mapped_read_length","STAR_num_splices","STAR_num_annotated_splices","STAR_num_GTAG_splices","STAR_num_GCAG_splices","STAR_num_ATAC_splices","STAR_num_noncanonical_splices","STAR_mismatch_rate","STAR_deletion_rate","STAR_deletion_length","STAR_insertion_rate","STAR_insertion_length","STAR_multimapped_multiple","STAR_multimapped_multiple_percent","STAR_multimapped_toomany","STAR_multimapped_toomany_percent","STAR_unmapped_multiple","STAR_unmapped_multiple_percent","STAR_unmapped_tooshort","STAR_unmapped_tooshort_percent","STAR_unmapped_other","STAR_unmapped_other_percent","STAR_chimeric","STAR_chimeric_percent")
  #print(star)
  output[["starfile"]]<-star
  #print(output)
  #Initialize with sample name from input file, then add each table in turn
  SE.colData <- data.frame(row.names=rownames(output[["inputfile"]]))
  for (i in seq_along(output)) {
    SE.colData <- cbind(SE.colData, output[[i]])
  }
  print(rownames(SE.colData))

  # Create SummarizedExperiment objects 
  ########################################
  
  rsem.filenames <- list(gene=gene_file, isoform=isoform_file)
  
  biomart.attributes <- list(
    gene = c('ensembl_gene_id','hgnc_symbol','gene_biotype','description','band','external_gene_name','transcript_count','entrezgene_id'),
    isoform = c('ensembl_transcript_id','ensembl_gene_id','hgnc_symbol','gene_biotype','transcript_biotype','description','band','external_gene_name','external_transcript_name','external_transcript_source_name','entrezgene_id')
  )
  gene.file.name<-paste(sample_name,"_Gene_Expression.rds",sep="")
  isoform.file.name<-paste(sample_name,"_Isoform_Expression.rds",sep="")
  rds.files <- c(gene=gene.file.name, isoform=isoform.file.name)
  
  # RSEM output columns related to gene/isoform-level annotation
  rsem.annotation.columns <- c(
    "gene_id", "transcript_id(s)", "length", "effective_length"
  )
  # Names of RSEM output columns holding gene/isoform IDs
  rsem.id.columns <- c(gene="gene_id", isoform="transcript_id")
  
  # Create a TxDb object from the GTF file; this will be used to populate the
  # rowRanges of the SummarizedExperiment objects
  txdb <- makeTxDbFromGFF(gtf)
  # listEnsemblArchives() Ensembl 108 Oct 2022 https://oct2022.archive.ensembl.org current version/release 108 
  ensembl = useEnsembl(biomart="ensembl", dataset="hsapiens_gene_ensembl", version = "108")

  for (type in c("gene", "isoform")) {
  SE.assays <- list()
  n <- length(rsem.filenames[[type]])
  for (i in seq(n)) {
    print(paste("Processing", type, "level RSEM output file", i, "of", n))
    rsem.output <- read.wsv(
      rsem.filenames[[type]][i], row.names=rsem.id.columns[type]
    )
    # Copy each RSEM column (minus any annotation columns) into assay list
    for (j in setdiff(colnames(rsem.output), rsem.annotation.columns)) {
      SE.assays[[j]] <- as.matrix(rsem.output[[j]])
    }
    
    # Name the rows and columns of each matrix
    SE.assays <- lapply(SE.assays, `rownames<-`, rownames(rsem.output))
    SE.assays <- lapply(SE.assays, `colnames<-`, rownames(SE.colData))
    
    BM <- getBM(attributes=biomart.attributes[[type]],  mart = ensembl)
      
    # Collapse by first column (either gene or transcript ID)
    BM <- aggregate(BM[-1], BM[1], unique)
    # Reorder to match order of features from RSEM output
    BM <- BM[match(substr(rownames(SE.assays[[1]]),1,15), BM[[1]]), ]
    # Combine Biomart annotation with data from TxDb object
    SE.rowRanges <- switch(type, gene=genes(txdb), isoform=transcripts(txdb))
    mcols(SE.rowRanges) <- c(mcols(SE.rowRanges), BM[-1])
    
    # Assemble variables into a SummarizedExperiment and write to RDS file
    dataset <- SummarizedExperiment(
      assays=SE.assays, colData=DataFrame(SE.colData), rowRanges=SE.rowRanges
    )
    print(rownames(dataset@colData))
    saveRDS(dataset, rds.files[[type]])
   }
  }
}  
args <- commandArgs(trailingOnly = TRUE)
create_se(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10])