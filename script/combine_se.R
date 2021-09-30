library(SummarizedExperiment) 

args <- commandArgs(trailingOnly = TRUE)
#load in arguments
prefix<-args[1]
somalier_final<-read.delim(args[2],header=F,stringsAsFactors = F)
gene_se<-args[3]
gene_se<-strsplit(gene_se, split=',')
gene_se<-unlist(gene_se, use.names = FALSE)

for (i in gene_se) {
    file<-readRDS(i)
    temp<-c(temp, file)
}

`temp`@colData@listData[["Somalier"]]<-somalier_final

saveRDS(temp, paste0(prefix, "_Gene_Expression.rds"))

iso_se<-args[4]
iso_se<-strsplit(iso_se, split=',')
iso_se<-unlist(gene_se, use.names = FALSE)

for j in iso_se {
    file<-readRDS(j)
    temp2<-c(temp2, file)
}

`temp2`@colData@listData[["Somalier"]]<-somalier_final

saveRDS(temp2, paste0(prefix, "_Isoform_Expression.rds"))
