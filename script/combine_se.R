library(SummarizedExperiment)
library(jsonlite)

#' Function to combine SummarizedExperiment (SE) RDS files. 
#' cbind_se combines rds files with matching data (rowData of each rds file)
#' cbind_se_alternate combines rds files after it matches data (rowData of each rds file)

cbind_overall <- function(gene_list) {
  cbind_se <- function(gene_list) {
    temp <- readRDS(gene_list[1])
    for (i in gene_list[-1]) {
      file <- readRDS(i)
      temp <- SummarizedExperiment::cbind(temp, file)
    }
    return(temp)
  }

  cbind_se_alternate <- function(gene_list) {
    temp <- readRDS(gene_list[1])
    for (i in gene_list[-1]) {
      file <- readRDS(i)
      rowData(file) <- rowData(temp)
      temp <- SummarizedExperiment::cbind(temp, file)
    }
    return(temp)
  }

  if (inherits(try(cbind_se(gene_list)), "try-error")) {
    output <- cbind_se_alternate(gene_list)
  } else {
    output <- cbind_se(gene_list)
  }
  
  return(output)
}

# Read arguments
args <- commandArgs(trailingOnly = TRUE)
json_file <- args[1]  # JSON file containing inputs

# Load JSON
input_data <- fromJSON(json_file)

# Extract values from JSON
prefix <- input_data$prefix
somalier_final <- read.delim(input_data$somalier_final_output, header = TRUE, stringsAsFactors = FALSE)
genotypes <- read.delim(input_data$genotype_tsv, header = TRUE, stringsAsFactors = FALSE)

# Process Gene Expression SE files
gene_se <- input_data$gene_se
gene_combined <- cbind_overall(gene_se)
gene_combined@colData@listData[["Somalier"]] <- somalier_final
gene_combined@colData@listData[["Genotypes"]] <- genotypes

# Save Gene Expression output
saveRDS(gene_combined, paste0(prefix, "_Gene_Expression.rds"))

# Process Isoform Expression SE files
iso_se <- input_data$iso_se
iso_combined <- cbind_overall(iso_se)
iso_combined@colData@listData[["Somalier"]] <- somalier_final
iso_combined@colData@listData[["Genotypes"]] <- genotypes

# Save Isoform Expression output
saveRDS(iso_combined, paste0(prefix, "_Isoform_Expression.rds"))