# Aggregation image used by createSE.wdl, combine_se.wdl and somalier_final.wdl.
# The original image was never built from a Dockerfile (its scripts were updated
# with docker commit), so this builds on the last published version, pinned by
# digest, and copies the scripts from script/ on top.
#
# Build from the repo root:
#   docker build --platform linux/amd64 -f docker/aggregation/Dockerfile -t htanpipelines/aggregation:v2 .
FROM htanpipelines/aggregation@sha256:4e26ff4c2d7e158ea461091ec3155276e2fbcddaf7b61bb603975c377b4f28ec

# createSE.wdl calls create_SE.R (with underscore)
COPY script/createSE.R /home/analysis/create_SE.R

# Ensembl 108 BioMart tables read by create_SE.R (see export_biomart_ensembl108.R)
COPY docker/aggregation/BM_gene_ensembl108.rds docker/aggregation/BM_isoform_ensembl108.rds /home/analysis/
