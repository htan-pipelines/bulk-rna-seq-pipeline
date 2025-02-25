library(SummarizedExperiment)
library(jsonlite)

##' Function to combine SummarizedExperiment (SE) RDS files. 
#' Combines RDS files by keeping shared metadata (colData) and retains only common gene features (rowData)

aggregate_SE_objects <- function(se_list) {
  # Read first SE object as a template
  se_merged <- readRDS(se_list[1])
  
  for (se_file in se_list[-1]) {
    se_new <- readRDS(se_file)
    
    # Ensure rowData consistency (keep only shared features)
    common_features <- intersect(rownames(se_merged), rownames(se_new))
    if (length(common_features) == 0) {
      stop("No matching gene features found across SE objects. Cannot merge.")
    }
    
    se_merged <- se_merged[common_features, , drop = FALSE]
    se_new <- se_new[common_features, , drop = FALSE]
    
    # Standardize rowData columns
    common_metadata_cols <- intersect(colnames(rowData(se_merged)), colnames(rowData(se_new)))
    rowData(se_merged) <- rowData(se_merged)[, common_metadata_cols, drop = FALSE]
    rowData(se_new) <- rowData(se_new)[, common_metadata_cols, drop = FALSE]
    
    # Merge multiple assays (expected_count, TPM, FPKM)
    assay_list <- c("expected_count", "TPM", "FPKM")
    merged_assays <- list()
    
    for (assay_name in assay_list) {
      if (assay_name %in% names(assays(se_merged)) && assay_name %in% names(assays(se_new))) {
        merged_assays[[assay_name]] <- SummarizedExperiment::cbind(assay(se_merged, assay_name), 
                                                                   assay(se_new, assay_name))
      }
    }
    
    # Standardize colData columns
    common_colData_cols <- intersect(colnames(colData(se_merged)), colnames(colData(se_new)))
    if (length(common_colData_cols) == 0) {
      stop("No common colData columns found across SE objects. Cannot merge.")
    }
    
    # Ensure both colData have the same structure
    colData(se_merged) <- colData(se_merged)[, common_colData_cols, drop = FALSE]
    colData(se_new) <- colData(se_new)[, common_colData_cols, drop = FALSE]
    
    # Merge colData (sample metadata)
    merged_colData <- rbind(colData(se_merged), colData(se_new))
    
    # Create new SE object with multiple assays
    se_merged <- SummarizedExperiment(
      assays = merged_assays,
      rowData = rowData(se_merged),
      colData = merged_colData
    )
  }
  
  return(se_merged)
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
gene_combined <- aggregate_SE_objects(gene_se)
gene_combined@colData@listData[["Somalier"]] <- somalier_final
gene_combined@colData@listData[["Genotypes"]] <- genotypes

# Save Gene Expression output
saveRDS(gene_combined, paste0(prefix, "_Gene_Expression.rds"))

# Process Isoform Expression SE files
iso_combined <- aggregate_SE_objects(iso_se)
iso_combined@colData@listData[["Somalier"]] <- somalier_final
iso_combined@colData@listData[["Genotypes"]] <- genotypes

# Save Isoform Expression output
saveRDS(iso_combined, paste0(prefix, "_Isoform_Expression.rds"))