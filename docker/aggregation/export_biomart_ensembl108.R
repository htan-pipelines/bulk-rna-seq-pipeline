#!/usr/bin/env Rscript
# One-time export of the Ensembl 108 BioMart tables used by createSE.R, so the
# pipeline no longer queries BioMart for every sample.
# Saves the getBM() output already collapsed to one row per gene/transcript ID
# (the step createSE.R used to repeat for every sample) as RDS, so column types
# and NA/empty values are exactly what the old per-sample code produced.
#
# Run inside the existing aggregation image (biomaRt 2.49.4):
#   docker run --rm --platform linux/amd64 -v "$PWD/docker/aggregation:/out" -w /out \
#     --entrypoint Rscript htanpipelines/aggregation@sha256:4e26ff4c2d7e158ea461091ec3155276e2fbcddaf7b61bb603975c377b4f28ec \
#     export_biomart_ensembl108.R

library(biomaRt)

# Ensembl's archive index page now returns JSON, which this biomaRt version
# cannot parse. Release 108 is not the current release, so the lookup is not
# needed; stub it out.
assignInNamespace("listEnsemblArchives", function(...) data.frame(name="Ensembl 116", date="Jun 2026", url="https://jun2026.archive.ensembl.org", version="116", current_release="*"), ns="biomaRt")
ensembl <- useMart(biomart="ENSEMBL_MART_ENSEMBL", dataset="hsapiens_gene_ensembl", host="https://oct2022.archive.ensembl.org")

# Must match the attributes createSE.R expects
biomart.attributes <- list(
  gene = c('ensembl_gene_id','hgnc_symbol','gene_biotype','description','band','external_gene_name','transcript_count','entrezgene_id'),
  isoform = c('ensembl_transcript_id','ensembl_gene_id','hgnc_symbol','gene_biotype','transcript_biotype','description','band','external_gene_name','external_transcript_name','external_transcript_source_name','entrezgene_id')
)

for (type in names(biomart.attributes)) {
  BM <- getBM(attributes=biomart.attributes[[type]], mart=ensembl)
  # Collapse by first column (either gene or transcript ID)
  BM <- aggregate(BM[-1], BM[1], unique)
  out <- paste0("BM_", type, "_ensembl108.rds")
  saveRDS(BM, out)
  print(paste(out, ":", nrow(BM), "rows,", ncol(BM), "columns"))
}
