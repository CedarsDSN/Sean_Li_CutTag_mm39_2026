# Step 12: CPS-Level PCA Quality Assessment

## Overview

In addition to formal differential enrichment analysis, it is useful to assess global sample relationships within each CPS-defined feature space. To accomplish this, we performed principal component analysis (PCA) on the CPS-specific master count matrices generated earlier in the workflow.

This PCA step serves as a **global quality-control and sample-structure assessment**, rather than a formal differential test. Its purpose is to visualize how samples cluster within each CPS, identify broad signal patterns, assess replicate consistency, and detect possible outliers or batch-like separations.

Unlike Step 9, this PCA workflow does **not** use comparison-specific `normBioCond()` normalization or the full comparison-specific multi-tier filtering strategy. Instead, it applies a simplified global filtering scheme across all samples within each CPS matrix, followed by MAnorm2-based count normalization and variance-based feature selection.

---

## Execution Strategy

The PCA workflow is implemented as an automated R script that iterates through all CPS-specific master matrices.

At a high level, the workflow performs the following steps for each CPS:

1. Load the CPS-specific master counts matrix  
2. Remove problematic chromosomes and contigs  
3. Apply a simplified global QC filter  
4. Normalize the retained intervals using `MAnorm2::normalize()`  
5. Select the top 2000 most variable CPS intervals  
6. Perform PCA  
7. Export a three-page PDF containing pairwise PC plots

The full implementation is maintained in the project repository; only the key analytical logic is summarized here.

---

## Key Analytical Logic

### 1. Input matrix discovery

All CPS-specific master matrices are collected automatically from the master-count directory:

```r
all_matrix_files <- list.files(
  master_dir,
  pattern = "_master_counts_profile_bins\\.xls$",
  full.names = TRUE
)
```

This ensures that PCA is run systematically across all available CPS matrices without manual file specification.

---

### 2. Removal of problematic chromosomes and contigs

Before PCA, intervals located on `chrM`, `chrUn`, or contigs containing `_random` are removed:

```r
data <- data[!(data$chrom %in% c("chrM", "chrUn")) & !grepl("_random", data$chrom), ]
```

#### Rationale
These regions often behave atypically and can distort global sample-structure visualization. Removing them improves the interpretability of PCA and prevents mitochondrial or poorly assembled contigs from dominating the first principal components.

---

### 3. Simplified global QC filtering

To stabilize the PCA input matrix, we apply a simplified global filtering strategy across all samples within a CPS matrix:

```r
raw_counts <- data[, count_cols]
raw_mean <- rowMeans(raw_counts)
global_occ_sum <- rowSums(data[, occ_cols])

keep_idx <- (raw_mean > 10) & (global_occ_sum >= 2)
data_filtered <- data[keep_idx, ]
```

#### Rationale
An interval is retained only if:

- its mean count across all samples in the CPS matrix is greater than 10
- its total occupancy across all samples is at least 2

This differs from the formal comparison-specific filtering used in Step 9. Here, the goal is not hypothesis testing, but rather construction of a stable global signal matrix suitable for exploratory PCA.

This filtering strategy removes very weak and poorly supported intervals while preserving enough global structure for meaningful sample-level clustering.

---

### 4. MAnorm2-based normalization prior to PCA

After filtering, the retained intervals are normalized using `MAnorm2::normalize()`:

```r
norm_data <- MAnorm2::normalize(data_filtered, count = count_cols, occupancy = occ_cols)
pca_input_full <- norm_data[, count_cols]
```

#### Rationale
This step provides a consistent transformed count matrix for PCA input. However, unlike Step 9, this PCA workflow does **not** perform comparison-specific anchor-based normalization with `normBioCond()`.

Therefore, the PCA plots should be interpreted as a **global exploratory QC visualization**, not as a direct representation of the comparison-specific normalization used for differential enrichment analysis.

---

### 5. Variance-based feature selection

To focus PCA on the most informative regions, only the top 2000 most variable CPS intervals are used:

```r
row_vars <- apply(pca_input_full, 1, var)
top_peaks <- order(row_vars, decreasing = TRUE)[1:2000]
pca_input <- pca_input_full[top_peaks, ]
```

#### Rationale
Using all intervals can dilute the PCA signal with large numbers of invariant or weakly informative features. Restricting the analysis to the top 2000 most variable CPS intervals enriches for the strongest genome-wide sources of variation and improves visualization of sample relationships.

---

### 6. PCA computation

PCA is then performed on the transposed feature matrix:

```r
pca_res <- prcomp(t(pca_input), scale. = FALSE)
```

The percentage of variance explained by each principal component is calculated and used directly in the plot axis labels.

#### Rationale
Samples are treated as observations and CPS intervals as features. PCA therefore summarizes the dominant axes of genome-wide variation across samples within each CPS-defined feature universe.

---

### 7. Sample and group labeling

Sample labels are preserved, and group labels are derived by removing the replicate suffix:

```r
pca_df$Sample <- sample_names
pca_df$Group <- sub("_[0-9]+$", "", pca_df$Sample)
```

#### Rationale
This allows visualization of both:

- individual sample-level replicate structure
- broader group-level clustering patterns

It also makes it easier to identify whether replicate samples cluster together as expected.

---

### 8. Multi-panel PCA reporting

For each CPS, three pairwise PCA plots are generated and written into a single PDF:

- PC1 vs PC2
- PC1 vs PC3
- PC2 vs PC3

Each plot includes:

- colored sample points by group
- direct sample labels using `ggrepel`
- variance-explained percentages in the axis titles

#### Rationale
A single two-dimensional PCA plot may miss important structure contained in the third principal component. Exporting all three pairwise combinations provides a more complete overview of sample relationships and improves outlier detection.

---

## Output

For each CPS matrix, this workflow generates one PDF file:

- `CPS##_PCA.pdf`

Each PDF contains three PCA panels:

1. PC1 vs PC2  
2. PC1 vs PC3  
3. PC2 vs PC3  

These plots are intended for:

- global sample-structure assessment
- replicate consistency inspection
- outlier detection
- broad batch-effect or biological-pattern screening

---

## Key Take-Home Message

This PCA workflow provides a CPS-level exploratory quality-control view of the CUT&Tag dataset by combining:

- simplified global feature filtering
- MAnorm2-based count normalization
- top-variable interval selection
- multi-panel PCA visualization

It is therefore complementary to, but distinct from, the formal differential enrichment analysis performed in Step 9.

