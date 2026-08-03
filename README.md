# bulk-rna-seq-pipeline

WDL pipelines for bulk RNA-seq processing, built for HTAN (Human Tumor Atlas
Network) studies. Runs once per sample (alignment, quantification, QC, sample
identity, HLA typing, TCR repertoire profiling, and optional germline variant
calling) and once per cohort (aggregating every sample's outputs together).
Downstream cohort-level QC reporting on the aggregated outputs lives in the
sibling repo [`htanBU-RNAseqQC`](https://github.com/htan-pipelines/htanBU-RNAseqQC).

## Pipeline architecture

```
per-sample:  pipeline/RNA_seq_pipeline.wdl        (run once per sample)
                    |
                    +-- RNA quantification, QC, and sample identity
                    |     FASTQC, STAR, RSEM, RNA-SeQC2, RSeQC TIN, samtools,
                    |     somalier extract, arcasHLA genotype  ->  createSE.wdl
                    |     ->  per-sample gene/isoform SummarizedExperiment (.rds)
                    |
                    +-- Germline SNP/indel calling (GATK RNA-seq best practices)
                    |     SplitNCigarReads -> BaseRecalibrator -> ApplyBQSR ->
                    |     HaplotypeCaller -> MergeVCFs -> VariantFiltration
                    |
                    +-- TCR / immune repertoire profiling (TCR_workflow/)
                          TRUST4, MiXCR
                    |
cohort-wide: Aggregation/aggregate.wdl            (run once per cohort)
                    |
                    somalier_relate -> somalier_final, arcasHLA_merge,
                    combine_se  ->  cohort SummarizedExperiment,
                    somalier.pairs.tsv, genotypes.tsv
                    |
             *** htanBU-RNAseqQC (downstream QC report) ***
```

Only the first arm of the per-sample pipeline (RNA quantification/QC/identity)
and the aggregation outputs feed `htanBU-RNAseqQC` — see
["What feeds htanBU-RNAseqQC"](#what-feeds-htanbu-rnaseqqc) below. The germline
variant-calling and TCR arms are independent analysis tracks that run as part
of the same per-sample workflow but produce outputs (VCFs, TCR/BCR clonotypes)
outside the QC report's scope.

## Repo layout

```
bulk-rna-seq-pipeline/
├── pipeline/
│   └── RNA_seq_pipeline.wdl       # current per-sample entry point
├── Aggregation/
│   └── aggregate.wdl              # current cohort-wide entry point
├── TCR_workflow/
│   ├── tcr_workflow.wdl           # TRUST4 + MiXCR sub-workflow
│   ├── TRUST.wdl
│   └── mixcr.wdl
├── script/                        # R scripts run inside the aggregation docker image
│   ├── createSE.R                 #   builds the per-sample SummarizedExperiment
│   ├── combine_se.R                #   merges per-sample SEs into the cohort SE
│   └── somalier_final_function.R  #   post-processes somalier.pairs.tsv
├── docker/                        # Dockerfiles for some of the custom images
│   ├── star/  rsem/  rseqc/  fastqc/
│   └── pathoscope/                #   present but not called by any current WDL
├── *.wdl                          # individual task WDLs called by the workflows
│   above (FASTQC, RSEQC_TIN, somalier.wdl, arcasHLA_genotype.wdl,
│   createSE.wdl, combine_se.wdl, the GATK germline-calling tasks, etc.) --
│   star_francois.wdl / rsem_francois.wdl / rsem_reference_francois.wdl are the
│   actual STAR/RSEM tasks used by pipeline/RNA_seq_pipeline.wdl (not the plain
│   star.wdl/rsem.wdl names you might expect -- those aren't present; STAR/RSEM
│   are instead imported from GTEx's Firecloud methods in most of the legacy
│   top-level workflows below, but pipeline/RNA_seq_pipeline.wdl uses its own
│   local copies)
└── (legacy, see below)
    workflow_rnaseq_pipeline.wdl, workflow_rnaseq_pipeline_new.wdl,
    workflow_rnaseq_pipeline_TRUST.wdl, rnaseq_pipeline.wdl,
    rnaseq_pipeline_new.wdl, RNA_seq_pipeline_updated.wdl, combine_se_old.wdl,
    rnaseq_aggregate.wdl
```

### Legacy files

The root-level `workflow_rnaseq_pipeline*.wdl`, `rnaseq_pipeline*.wdl`,
`RNA_seq_pipeline_updated.wdl`, `combine_se_old.wdl`, and `rnaseq_aggregate.wdl`
files are earlier iterations of this pipeline (all last touched in 2020–2021)
that predate the current `pipeline/` and `Aggregation/` structure. None of them
import everything `pipeline/RNA_seq_pipeline.wdl` does — most are missing
arcasHLA genotyping and/or TCR profiling, and `rnaseq_aggregate.wdl` predates
the somalier/arcasHLA-aware `Aggregation/aggregate.wdl`. They're kept for
history but are not maintained — use **`pipeline/RNA_seq_pipeline.wdl`** and
**`Aggregation/aggregate.wdl`** as your entry points, not these.

## Per-sample pipeline: `pipeline/RNA_seq_pipeline.wdl`

Workflow `rnaseq_pipeline_workflow`, run once per sample. All three arms below
share the same STAR alignment (and read-group construction) as their common
starting point, then branch independently.

### 1. RNA quantification, QC, and sample identity

The arm `htanBU-RNAseqQC` actually consumes:

| Task | What it does | Output used downstream |
|---|---|---|
| `ReadGroup` | Builds the `@RG` line passed to STAR | — |
| `FASTQC` | Per-read QC on both mates | `fastqc_*` metrics |
| `star` (`star_francois.wdl`) | Genome + transcriptome alignment | genome BAM, transcriptome BAM, STAR log |
| `markduplicates` | Marks PCR/optical duplicates (GTEx GATK4 method) | deduplicated BAM (used for `rnaseqc2`) |
| `RSEQC_TIN` | Transcript Integrity Number + `samtools stats` | `TIN_` metrics, `samtools_` metrics |
| `rsem_reference` (task) + `rsem` (`rsem_francois.wdl`) | Builds a per-sample RSEM index from `refFasta`/`annotationsGTF`, then quantifies | gene- and isoform-level counts/TPM/FPKM |
| `rnaseqc2` (GTEx Firecloud method) | RNA-SeQC2 QC metrics | `rnaseqc_` metrics |
| `somalier_extract` (`somalier.wdl`) | Per-sample genotype fingerprint from known-sites VCF | `<prefix>.somalier` (fed into `Aggregation/aggregate.wdl`) |
| `arcasHLA_extract` + `arcasHLA_genotype` (`arcasHLA_genotype.wdl`) | HLA typing from RNA reads (genes A, B, C, DPB1, DQB1, DQA1, DRB1) | per-sample genotype JSON (fed into `Aggregation/aggregate.wdl`) |
| `createSE` (`createSE.wdl`, runs `script/createSE.R`) | Combines all of the above into one object per sample | `<sample>_Gene_Expression.rds`, `<sample>_Isoform_Expression.rds` |

### 2. Germline SNP/indel calling (GATK RNA-seq variant-calling best practices)

`gtfToCallingIntervals` → `SplitNCigarReads` → `BaseRecalibrator` → `ApplyBQSR`
→ `ScatterIntervalList` → `HaplotypeCaller` (scattered across intervals) →
`MergeVCFs` → `VariantFiltration`. Standard GATK4 RNA-seq germline calling
(split reads at intron boundaries, recalibrate, call variants, apply RNA-seq
specific hard filters). Produces a filtered per-sample VCF; not consumed by
`htanBU-RNAseqQC`.

### 3. TCR / immune repertoire profiling (`TCR_workflow/tcr_workflow.wdl`)

- **`TRUST`** (TRUST4) — assembles and annotates TCR/BCR sequences directly
  from the BAM against an IMGT reference.
- **`MiXCR`** — independent TCR/BCR repertoire reconstruction from the raw
  FASTQs (requires a MiXCR license file, plus `species`/`material` params).

Both write per-sample clonotype/report files; not consumed by
`htanBU-RNAseqQC` — a separate track for immune-repertoire analyses.

## Cohort-wide aggregation: `Aggregation/aggregate.wdl`

Workflow `aggregation_workflow`, run once across all samples in a cohort,
after every sample has finished the per-sample pipeline above:

| Task | What it does | Output |
|---|---|---|
| `somalier_relate` (`somalier_relate.wdl`) | Pairwise relatedness across every sample's `.somalier` fingerprint | `somalier.pairs.tsv`, `somalier.samples.tsv`, `somalier.html` |
| `somalier_final` (`somalier_final.wdl`, runs `script/somalier_final_function.R`) | Post-processes `somalier.pairs.tsv` against the cohort's sample/participant ID list | `somalier.final.tsv` |
| `arcasHLA_merge` (`arcasHLA_merge.wdl`) | Merges every sample's arcasHLA genotype call | `genotypes.tsv` |
| `combine_se_write_json` (`combine_se.wdl`, runs `script/combine_se.R`) | Merges every sample's gene/isoform `SummarizedExperiment` (keeping shared `colData` and only genes/isoforms common to all samples) | `<prefix>_Gene_Expression.rds`, `<prefix>_Isoform_Expression.rds` |

## What feeds `htanBU-RNAseqQC`

The downstream QC report needs exactly four objects, all produced above:

| Input | Produced by |
|---|---|
| Aggregated `SummarizedExperiment` (`<prefix>_Gene_Expression.rds`) | `Aggregation/aggregate.wdl` → `combine_se.wdl` |
| `somalier.pairs.tsv` | `Aggregation/aggregate.wdl` → `somalier_relate.wdl` |
| `genotypes.tsv` | `Aggregation/aggregate.wdl` → `arcasHLA_merge.wdl` |
| Your own per-sample metadata sheet (sample/patient IDs, tissue type, site, RIN, DV200, etc.) | Not produced by this pipeline — your own sample-tracking sheet |

## Required reference inputs

Supplied once per run of `pipeline/RNA_seq_pipeline.wdl` (typically the same
across all samples in a cohort):

- `refFasta` / `refFastaIndex` / `refDict` — reference genome FASTA + index + sequence dictionary
- `annotationsGTF` — gene annotation GTF (used to build the RSEM index and the GATK calling intervals)
- `gene_bed` / `rseqc_gene_bed` — RSeQC gene-model BED file for the TIN calculation
- `known_indels_sites_VCF` — sites VCF passed to `somalier extract`
- `dbSnpVcf` / `dbSnpVcfIndex`, `knownVcfs` / `knownVcfsIndices` — germline-calling arm only
- MiXCR license file, `species`, `material` — TCR arm (`MiXCR`) only
- IMGT reference FASTA — TCR arm (`TRUST`) only

## Docker images

Most alignment/quantification tasks pin a specific image directly in the WDL:
`star` (`star_francois.wdl`) and `rsem_reference`/`rsem` (`rsem_francois.wdl`,
`rsem_reference_francois.wdl`) use `gcr.io/broad-cga-francois-gtex/gtex_rnaseq`
(versions V9–V11); `somalier_extract`/`somalier_relate` use
`docker.io/brentp/somalier`; `createSE`, `combine_se`, and `somalier_final`
(the R-script tasks) use `docker.io/htanpipelines/aggregation`.

A number of other tasks — `ReadGroup`, `FASTQC`, `RSEQC_TIN`, every task in the
germline-calling arm, `arcasHLA_extract`/`arcasHLA_genotype`/`arcasHLA_merge`,
and `TRUST`/`MiXCR` — declare `docker` (or `rseqc_docker`/`fastqc_docker`) as a
plain WDL input with no default, rather than pinning an image in the task
itself. These are WDL draft-2 style task inputs that aren't threaded through
`pipeline/RNA_seq_pipeline.wdl`'s own top-level `workflow` inputs, so you set
them directly in your inputs JSON using the fully-qualified name, e.g.
`rnaseq_pipeline_workflow.RSEQC_TIN.rseqc_docker`. `docker/` in this repo has
Dockerfiles for a few of these (`star`, `rsem`, `rseqc`, `fastqc`) if you need
to build your own; `docker/pathoscope/` is present but not called by any
current WDL.

## Citation

See [`CITATION.cff`](CITATION.cff).
