#!/usr/bin/env Rscript
#input = rnaseqc ouptut
#tinfile = RSEQC_TIN output text file
#gene_file= RSEM output
#isoform_file = RSEM output
#sample.name = name of sample running through the pipeline (should be same as prefix)
create_se <- function(input, tinfile, gtf, gene_file, isoform_file,sample.name) {
  library(biomaRt)
  library(GenomicFeatures)
  library(SummarizedExperiment)  
  
  read.wsv <- function (file, ...) {
    read.table(
      file, header=TRUE, check.names=FALSE, stringsAsFactors=FALSE,
      ...
      )
  }
  
  output <- list()
  #load input file
  data <- read.delim(input, header=FALSE, stringsAsFactors=FALSE)
  #organize data into proper format
  names <- data[,1]
  data <- data.frame(data[,-1], stringsAsFactors = FALSE, row.names = names)
  data <- data.frame(t(data), stringsAsFactors = FALSE)
  data[,2:ncol(data)] <- sapply(data[,2:ncol(data)], as.numeric)
  rownames(data)<-sample.name
  #load in tinfile and add to list
  output[["inputfile"]] <- data
  # Get tab-delimited column names from first line of first file 
  output[["tinfile"]] <- c(readLines(tinfile, n=1), 
                           sapply(tinfile, scan, what="", n=1, sep="\n", skip=1, quiet=TRUE)) # Read tab-delimited contents of second lines of all files
  # Parse the character vector into a data frame
  output[["tinfile"]] <- read.wsv(
    textConnection(output[["tinfile"]]), row.names=1
  )
  # Add a prefix to the column names
  colnames(output[["tinfile"]]) <- gsub(
    "_$", "", gsub("[' \"\\(\\)\\-]", "_", colnames(output[["tinfile"]])))
  
  # Initialize with sample name from input file, then add each table in turn
  SE.colData <- data.frame(row.names=rownames(output[["inputfile"]]))
  for (i in seq_along(output)) {
    SE.colData <- cbind(SE.colData, output[[i]])
  }
  row.names(SE.colData) <- SE.colData[1,1]
  
  # Open connection to Biomart 
  #################################################
  
  # Determine from parameters which Biomart dataset and hostname should be used
  biomart <- list(
    database = "ENSEMBL_MART_ENSEMBL",
    dataset = paste(
      tolower(
        sub("^(.)[^ ]+ (.+)$", "\\1\\2", "Homo sapiens")
      ),
      "gene_ensembl", sep="_"
    )
  )
  # Note: this connection is done in a repeat loop because it doesn't always
  #       work on the first try; a maximum number of attempts is included to
  #       keep it from endlessly looping if Biomart is down
  cat(
    "Opening connection to Biomart",
    with(
      biomart,
      sprintf(
        "(database %s, dataset %s).\n",
        database, dataset
      )
    )
  )
  max.attempts <- 10
  attempt <- 1
  repeat {
    cat(sprintf("Connection attempt #%d of %d...", attempt, max.attempts))
    mart <- try(
      with(biomart, useMart(biomart=database, dataset=dataset)),
      silent=TRUE
    )
    if (inherits(mart, "Mart")) {
      cat("successful.\n")
      break
    }
    cat("\n")
    if (attempt == max.attempts) {
      stop("Could not connect to Biomart after ", max.attempts, " attempts")
    }
    attempt <- attempt + 1
  }
  
  # Create SummarizedExperiment objects 
  ########################################
  
  rsem.filenames <- list(gene_file, isoform_file)
  
  biomart.attributes <- list(
    gene = c('ensembl_gene_id','hgnc_symbol','gene_biotype','description','band','external_gene_name','genedb','transcript_count','entrezgene_id'),
    isoform = c('ensembl_transcript_id','ensembl_gene_id','hgnc_symbol','gene_biotype','transcript_biotype','description','band','external_gene_name','genedb','external_transcript_id','transcript_db_name','entrezgene_id')
  )
  gene.file.name<-paste(sample.name,"_Gene_Expression.rds",sep="")
  isoform.file.name<-paste(sample.name,"_Isoform_Expression.rds",sep="")
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
  
  SE.assays <- list()
  n <- length(rsem.filenames[[type]])
  for (i in seq(n)) {
    cat("Processing", type, "level RSEM output file", i, "of", n, "\r")
    rsem.output <- read.wsv(
      rsem.filenames[[type]][i], row.names=rsem.id.columns[type]
    )
    # Copy each RSEM column (minus any annotation columns) into assay list
    for (j in setdiff(colnames(rsem.output), rsem.annotation.columns)) {
      SE.assays[[j]] <- cbind(SE.assays[[j]], rsem.output[[j]])
    }
    
    cat("\n")
    # Name the rows and columns of each matrix
    SE.assays <- lapply(SE.assays, `rownames<-`, rownames(rsem.output))
    SE.assays <- lapply(SE.assays, `colnames<-`, rownames(SE.colData))
    
    # Retrieve annotation from Biomart
    BM <- getBM(attributes=biomart.attributes[[type]], mart=mart)
    # Collapse by first column (either gene or transcript ID)
    BM <- aggregate(BM[-1], BM[1], unique)
    # Reorder to match order of features from RSEM output
    BM <- BM[match(rownames(SE.assays[[1]]), BM[[1]]), ]
    # Combine Biomart annotation with data from TxDb object
    SE.rowRanges <- switch(type, gene=genes(txdb), isoform=transcripts(txdb))
    mcols(SE.rowRanges) <- c(mcols(SE.rowRanges), BM[-1])
    
    # Assemble variables into a SummarizedExperiment and write to RDS file
    dataset <- SummarizedExperiment(
      assays=SE.assays, colData=DataFrame(SE.colData), rowRanges=SE.rowRanges
    )
    saveRDS(dataset, rds.files[[type]])
  }
}  
