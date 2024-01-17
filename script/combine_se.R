library(SummarizedExperiment) 

#' This function takes list of SummarizedExperiment (SE) rds files and combines to make one large SE rds file. 
#' cbind_se combines rds files with matching data (rowData of each rds file)
#' cbind_se_alternate combines rds files after it matches data (rowData of each rds file)

cbind_overall <- function(gene_list){
  cbind_se <- function(gene_list){
    temp <-  readRDS(gene_list[1])
    for (i in gene_list[-1]){
      file <- readRDS(i)
      temp <- SummarizedExperiment::cbind(temp, file)
      }
    return(temp)
  }
  cbind_se_alternate <- function(gene_list){
    temp <-  readRDS(gene_list[1])
    for (i in gene_list[-1]){
      file <- readRDS(i)
      rowData(file) <- rowData(temp)
      temp <- SummarizedExperiment::cbind(temp, file) 
      }
    return(temp)
  }
  if(inherits(try(cbind_se(gene_list)), "try-error")){
    output <- cbind_se_alternate(gene_list)
  } else{
    output <- cbind_se(gene_list)
  }
  
}

args <- commandArgs(trailingOnly = TRUE)

#load in arguments
prefix<-args[1]
somalier_final<-read.delim(args[2],header=T,stringsAsFactors = F)
genotypes<-read.delim(args[3],header=T,stringsAsFactors = F)
gene_se<-args[4]
gene_se<-strsplit(gene_se, split=',')
gene_se<-unlist(gene_se, use.names = FALSE)
temp <- cbind_overall(gene_se)
`temp`@colData@listData[["Somalier"]]<-somalier_final
`temp`@colData@listData[["Genotypes"]]<-genotypes


saveRDS(temp, paste0(prefix, "_Gene_Expression.rds"))

iso_se<-args[5]
iso_se<-strsplit(iso_se, split=',')
iso_se<-unlist(iso_se, use.names = FALSE)
temp2 <- cbind_overall(iso_se)
`temp2`@colData@listData[["Somalier"]]<-somalier_final
`temp2`@colData@listData[["Genotypes"]]<-genotypes

saveRDS(temp2, paste0(prefix, "_Isoform_Expression.rds"))