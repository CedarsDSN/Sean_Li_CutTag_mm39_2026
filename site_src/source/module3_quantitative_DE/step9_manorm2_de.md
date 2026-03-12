# Step 9: Differential Enrichment Analysis (MAnorm2)

## Overview

With the master counts matrices generated in Step 8, we can now perform a quantitative comparison of chromatin enrichment between biological conditions. Because CUT&Tag data can exhibit substantial variability in both signal intensity and peak occupancy structure, robust filtering, normalization, and variance modeling are essential before formal statistical testing.

To perform differential enrichment analysis, we used the `MAnorm2` R package. MAnorm2 is designed for the quantitative comparison of groups of chromatin profiling samples and provides model-based normalization and variance estimation well suited for CUT&Tag-style enrichment data.

In this workflow, differential testing is performed within the CPS-defined feature space established in Step 7 and quantified in Step 8. Thus, all comparisons are conducted on a shared, non-redundant set of genomic intervals rather than on sample-specific peak boundaries.



To ensure robustness across heterogeneous comparison groups, the analysis script was designed to perform:
* Strict pre-filtering of noisy intervals
* Conservative normalization-anchor selection
* Primary parametric mean-variance fitting with fallback only when true convergence fails
* Direct genomic annotation of the final differential results using `ChIPseeker`

---

## Execution Strategy

The full MAnorm2 workflow is implemented as an automated R script executed through a Slurm array, with each task corresponding to one comparison entry in `Metadata_Comparison.csv`.

Rather than embedding the full script in the documentation, the key analytical logic is summarized below. The complete implementation is maintained in the project repository.

At a high level, each comparison follows this sequence:
1. Load the CPS-specific master counts matrix
2. Extract the count and occupancy columns corresponding to the two comparison groups
3. Apply multi-tier feature filtering
4. Normalize the two groups using a conservative shared anchor set
5. Fit the mean-variance relationship
6. Perform differential testing
7. Annotate the resulting intervals with genomic context and nearest-gene information
8. Export comparison-specific result tables and summary statistics

---

## Key Algorithmic Rationale

### 1. Three-Tier Feature Filtering

Before differential testing, low-information and unstable regions are removed to reduce noise and lessen the multiple-testing burden. The filtering strategy consists of three layers:

#### a. Basic count-volume filter
Intervals in the bottom 10% of total fragment counts across the two comparison groups are removed. This step excludes the weakest regions, which are typically dominated by stochastic background signal and contribute little useful statistical information. 

A simplified version of the implementation is:
```R
low_quantile_cutoff <- 0.1
low_cutoff <- quantile(total_sum, low_quantile_cutoff, na.rm = TRUE)
basic_keep <- total_sum > low_cutoff
```

#### b. Quality and variance filter
An interval is retained only if at least one of the two groups shows both:
* A mean count of at least 10
* A coefficient of variation (CV) no greater than 1.0

This requirement removes regions whose apparent signal is driven primarily by unstable or highly scattered observations.
```R
quality_keep <- ((g1_mean >= min_mean_count) & (cv1 <= max_cv)) |
                ((g2_mean >= min_mean_count) & (cv2 <= max_cv))
```

#### c. Occupancy filter
An interval must overlap original sample-specific peak calls in at least two replicates across the two comparison groups combined. 

This is important: the filter is not defined as "at least two replicates within either single group," but rather as a combined occupancy requirement across both groups.
```R
occupancy_keep <- (occ_n_g1 + occ_n_g2) >= min_occ_n
```

Together, these three filters improve the stability of downstream variance modeling and statistical testing.

### 2. Conservative Normalization Anchor Selection

After filtering, between-group normalization is performed using `normBioCond()` in MAnorm2.

Instead of using all retained intervals as normalization anchors, we define a more conservative anchor set consisting only of regions that satisfy all of the following:
* Located on autosomes
* Occupied in every replicate of Group 1
* Occupied in every replicate of Group 2

This excludes sex chromosomes, which may show biologically driven dosage differences, and restricts normalization to highly stable shared regions. These universally occupied autosomal intervals provide a robust anchor set for scaling the two biological conditions to a common baseline.
```R
autosome <- !(data_filtered$chrom %in% c("chrX", "chrY"))
common_peak_idx <- autosome &
                   (occ_n_g1_f == ncol(occ_g1_f)) &
                   (occ_n_g2_f == ncol(occ_g2_f))

conds <- normBioCond(conds, common.peak.regions = common_peak_idx)
```
For reproducibility tracking, the script also records the number and proportion of anchor intervals retained for each comparison.

### 3. Primary Parametric Fitting with Convergence-Based Fallback



A common failure point in model-based chromatin differential analysis is mean-variance curve fitting, especially when replicate numbers are limited or signal dispersion is highly uneven. 

To make the workflow robust, we implemented a convergence-based fitting strategy:
* **Primary model:** Parametric mean-variance fitting
* **Fallback model:** Modified local regression with re-estimated prior degrees of freedom

The parametric model is attempted first because it provides a stable and interpretable fit under well-behaved conditions. Importantly, the script does not switch away from the parametric model merely because warnings are emitted. As long as the MAnorm2 fitting log explicitly reports successful convergence, the parametric fit is retained. 

A simplified version of the implementation is:
```R
fit_log <- capture.output(
  conds_param <- tryCatch(
    fitMeanVarCurve(
      conds,
      method = "parametric",
      occupy.only = TRUE,
      max.iter = 100,
      init.coef = c(0.1, 10)
    ),
    error = function(e) e
  )
)

param_converged <- any(grepl("Converged\\.", fit_log))
```

Only when the parametric fit fails to converge or throws a true fitting error does the workflow fall back to a modified local regression strategy:
```R
conds_local <- tryCatch({
  tmp_conds <- fitMeanVarCurve(
    conds,
    method = "local regression",
    occupy.only = FALSE
  )
  tmp_conds <- estimatePriorDf(
    tmp_conds,
    occupy.only = TRUE
  )
  tmp_conds
}, error = function(e) e)
```
In the final output, the selected fitting method is recorded explicitly for each comparison (for example, `parametric` or `local_allIntervals_rePriorDf`).

### 4. Differential Testing Within the CPS Framework

After normalization and mean-variance estimation, differential testing is performed using `diffTest()` in MAnorm2.
```R
res <- diffTest(conds[[2]], conds[[1]])
final_res <- cbind(data_filtered[, 1:3], res)
```
Each tested interval therefore represents one CPS-defined genomic feature, and the resulting statistics quantify differential enrichment between the two comparison groups within that shared coordinate framework.

This is an important distinction: the analysis is not based on raw sample-specific peak boundaries, but on the unified feature space established earlier in the workflow.

### 5. Direct Genomic Annotation with ChIPseeker



To make the differential output immediately biologically interpretable, the tested intervals are annotated directly within the MAnorm2 workflow using `ChIPseeker` and the custom GENCODE vM38 annotation resources prepared during reference setup.

A simplified annotation block is:
```R
peaks_gr <- GRanges(
  seqnames = final_res$chrom,
  ranges = IRanges(final_res$start, final_res$end)
)

mcols(peaks_gr) <- final_res[, 4:ncol(final_res)]

peakAnno <- annotatePeak(
  peaks_gr,
  tssRegion = c(-3000, 3000),
  TxDb = txdb,
  overlap = "all",
  addFlankGeneInfo = TRUE,
  flankDistance = 3000
)
```
For each differential interval, the final result table includes:
* Genomic annotation category (for example, Promoter, Intron, Distal Intergenic)
* Nearest gene information
* Distance to transcription start site (TSS)
* Gene symbol mapping

In addition, the script appends comparison-level metadata directly into the final result table, including:
* `Comparison_ID`
* `CPS`
* `Histone_Mark`

This makes the exported results immediately traceable across multiple CPS groups and histone-marker analyses.

---

## Output

For each comparison defined in `Metadata_Comparison.csv`, the MAnorm2 workflow produces an annotated differential result table containing:
* CPS interval coordinates
* Normalized group-level statistics
* Differential enrichment statistics (including M-value and significance metrics)
* Genomic context annotations
* Associated gene information
* Comparison metadata (`Comparison_ID`, `CPS`, `Histone_Mark`)

In addition, summary statistics and diagnostic tracking tables are generated to record:
* The number of intervals retained after each filtering stage
* The normalization-anchor counts
* The mean-variance fitting method ultimately used for that comparison
* Marker-aware comparison summaries and chromosome-level directional distributions

These outputs form the definitive basis for downstream biological interpretation and comparison-specific visualization.

### Key Take-Home Message

The differential enrichment analysis workflow is designed not only to test for statistical differences, but also to enforce a high-confidence analytical framework through:
1. CPS-based shared feature definition
2. Reproducibility-aware feature filtering
3. Conservative normalization-anchor selection
4. Convergence-aware mean-variance modeling
5. Immediate biological annotation and metadata-aware result export

This makes the final results substantially more robust and interpretable than a naive count-comparison workflow performed directly on raw per-sample peak files. The full implementation script is maintained in the project repository; only the key analytical logic and representative code blocks are shown here.
