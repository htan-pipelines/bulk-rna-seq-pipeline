library(SummarizedExperiment)
library(jsonlite)

#' Function to combine SummarizedExperiment (SE) RDS files. 
#' cbind_se combines RDS files with matching data (rowData of each RDS file)
#' cbind_se_alternate combines RDS files after matching data (rowData of each RDS file)

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
json_file <- args[1]  # JSON file containing iso_se, gene_se, and prefix
somalier_final_file <- args[2]  # Separate argument for Somalier final output
genotype_tsv_file <- args[3]    # Separate argument for genotype TSV

# Load JSON
input_data <- fromJSON(json_file)

# Extract values from JSON
prefix <- input_data$prefix

# Convert comma-separated strings to lists if necessary
parse_file_list <- function(file_list) {
  if (is.character(file_list) && grepl(",", file_list)) {
    return(strsplit(file_list, ",")[[1]])
  }
  return(file_list)
}

# Ensure gene_se and iso_se are correctly parsed as lists
gene_se <- parse_file_list(input_data$gene_se)
iso_se <- parse_file_list(input_data$iso_se)

# Load Somalier and genotype data separately
somalier_final <- read.delim(somalier_final_file, header = TRUE, stringsAsFactors = FALSE)
genotypes <- read.delim(genotype_tsv_file, header = TRUE, stringsAsFactors = FALSE)

# Process Gene Expression SE files
gene_combined <- cbind_overall(gene_se)
gene_combined@colData@listData[["Somalier"]] <- somalier_final
gene_combined@colData@listData[["Genotypes"]] <- genotypes

# Save Gene Expression output
saveRDS(gene_combined, paste0(prefix, "_Gene_Expression.rds"))

# Process Isoform Expression SE files
iso_combined <- cbind_overall(iso_se)
iso_combined@colData@listData[["Somalier"]] <- somalier_final
iso_combined@colData@listData[["Genotypes"]] <- genotypes

# Save Isoform Expression output
saveRDS(iso_combined, paste0(prefix, "_Isoform_Expression.rds"))