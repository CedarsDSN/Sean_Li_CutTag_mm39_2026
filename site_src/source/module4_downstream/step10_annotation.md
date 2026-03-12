# Step 10: Genomic Annotation (ChIPseeker)

## Overview

After identifying differentially enriched genomic intervals in Step 9, an essential downstream step is to translate these coordinates into biologically interpretable information. This involves assigning each interval to its genomic context (for example, Promoter, Intron, or Distal Intergenic) and linking it to nearby genes.

We performed this annotation using the `ChIPseeker` R package. However, rather than relying on generic precompiled annotation resources, we used a customized, reference-matched annotation strategy to ensure maximal internal consistency with the genome annotation framework used throughout the workflow.

---

## Custom Annotation References

A common pitfall in genomic annotation workflows is the use of generic reference databases that do not exactly match the annotation release used during alignment, peak calling, and downstream analysis. This can lead to inconsistent feature assignment, avoidable gene-symbol mapping loss, and biologically irrelevant annotations.

To avoid these issues, we used the same curated GENCODE-derived reference resources established during Step 1:

1. **Custom TxDb (`mm39_vM38_pc_lnc_miRNA.sqlite`)**  
   A transcript database generated directly from the filtered GENCODE vM38 GTF used in this project. This ensures that genomic context assignments are made relative to the same curated feature universe used throughout the analysis.

2. **Custom Gene Map (`GENCODE_vM38_GeneMap.rds`)**  
   A direct Ensembl-to-gene-symbol mapping table derived from the exact same GTF. This provides highly consistent symbol mapping within the same annotation framework and reduces version-mismatch-related mapping loss.

As a result, all promoter, intron, intergenic, nearest-gene, and flanking-gene assignments are defined relative to a project-specific annotation reference rather than a generic external package.

---

## Core Annotation Workflow

The core annotation logic is applied directly to the differential result coordinates (`final_res`) produced in Step 9.

A simplified implementation is shown below:

```r
library(ChIPseeker)
library(GenomicRanges)
library(GenomicFeatures)

# Load custom references
txdb <- loadDb("/path/to/mm39_vM38_pc_lnc_miRNA.sqlite")
gene_map <- readRDS("/path/to/GENCODE_vM38_GeneMap.rds")

# Convert differential intervals to GRanges
peaks_gr <- GRanges(
  seqnames = final_res$chrom,
  ranges = IRanges(final_res$start, final_res$end)
)
mcols(peaks_gr) <- final_res[, 4:ncol(final_res)]

# Annotate genomic context
peakAnno <- annotatePeak(
  peaks_gr,
  tssRegion = c(-3000, 3000),
  TxDb = txdb,
  overlap = "all",
  addFlankGeneInfo = TRUE,
  flankDistance = 3000
)

# Convert to data frame and flatten list-columns
res_df <- as.data.frame(peakAnno)
res_df[] <- lapply(
  res_df,
  function(x) if (is.list(x)) sapply(x, paste, collapse = ";") else x
)

# Normalize Ensembl IDs and map to gene symbols
res_df$geneId <- gsub("\\..*", "", res_df$geneId)
res_df$SYMBOL <- gene_map$SYMBOL[match(res_df$geneId, gene_map$geneId)]
```

---

## Key Algorithmic Rationale

### 1. Annotation is performed directly on the differential intervals

Rather than generating a separate annotation object and linking it later, annotation is applied directly to the genomic intervals that were statistically tested in Step 9. This produces a single integrated result table containing both statistical output and biological interpretation.

This design simplifies downstream visualization, enrichment analysis, and manual result review.

### 2. Flanking-gene reporting for broader regulatory interpretation

We set:

- `addFlankGeneInfo = TRUE`
- `flankDistance = 3000`

This allows the workflow to record not only the nearest annotated gene, but also nearby flanking genes within a defined local window. This is particularly useful for regulatory marks such as H3K27ac or H3K4me1, where a differential region may be associated with more than one plausible nearby target.

### 3. List-column flattening for safe export

When flanking-gene reporting or multi-feature overlap is enabled, `ChIPseeker` may return list-based columns rather than plain scalar values. These structures are not directly compatible with standard table export.

To resolve this, all list-columns are flattened into semicolon-separated character strings before writing the final output table. As a result, the final annotation table remains both human-readable and export-safe.

Some annotation-related columns may therefore contain multiple semicolon-delimited values rather than a single entry.

### 4. Ensembl version suffix stripping

GENCODE gene identifiers frequently include version suffixes (for example, `ENSMUSG00000000001.4`). Many downstream tools and mapping utilities expect the base Ensembl gene ID without the suffix.

Therefore, version suffixes are removed before symbol mapping:

```r
res_df$geneId <- gsub("\\..*", "", res_df$geneId)
```

This improves compatibility with downstream enrichment tools and simplifies external cross-reference.

### 5. Direct mapping through the custom gene map

Rather than relying on a generic annotation-conversion function, gene symbols are assigned by direct matching against the custom `GENCODE_vM38_GeneMap.rds` table derived from the same GTF used to build the TxDb.

Because both resources originate from the same annotation source, this provides the most internally consistent Ensembl-to-symbol mapping possible within the workflow.

---

## Output

This annotation step appends multiple biologically informative fields to the final differential result table, including:

- **`annotation`**  
  The genomic context assigned by `ChIPseeker` (for example, `Promoter (<=1kb)`, `Intron`, `Distal Intergenic`)

- **`distanceToTSS`**  
  The distance to the nearest transcription start site, as reported by `ChIPseeker`

- **`geneId`**  
  The normalized Ensembl gene identifier with version suffix removed

- **`SYMBOL`**  
  The mapped gene symbol obtained through the custom gene map

- **flanking / overlapping gene-related fields**  
  Additional gene identifiers or transcript identifiers, which may contain multiple semicolon-delimited entries when more than one relevant feature is present

In the full exported result tables, these annotation fields are retained alongside the statistical output from Step 9, together with comparison-level metadata such as:

- `Comparison_ID`
- `CPS`
- `Histone_Mark`

These fully annotated tables are directly ready for downstream volcano-plot labeling, GO/pathway enrichment, and integration with external expression datasets.

---

## Key Take-Home Message

The annotation workflow is designed to maximize biological interpretability while preserving full consistency with the custom reference framework used throughout the project.

By annotating differential intervals directly with a custom GENCODE-matched TxDb and gene map, the final result tables become immediately suitable for:

- locus-level interpretation
- pathway and GO analysis
- cross-modal integration with RNA-seq or other omics data

without requiring a separate post hoc annotation pipeline.

