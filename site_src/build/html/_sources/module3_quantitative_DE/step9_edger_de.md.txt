# Step 9: Differential Enrichment Analysis with edgeR

## Purpose

The current maintained differential enrichment analysis uses edgeR, not the older MAnorm2 workflow.

Each SLURM array task runs one metadata-defined comparison. The R script extracts the relevant count and occupancy columns from the CPS-level `profile_bins` matrix, filters testable intervals, fits an edgeR quasi-likelihood GLM, annotates the tested regions, and writes comparison-level result tables.

## Scripts

CTK4me1:

```text
script/05_differential_analysis/CTK4me1/submit_edgeR_all_comparisons_CTK4me1.sh
script/05_differential_analysis/CTK4me1/run_edgeR_one_comparison_CTK4me1.slurm
script/05_differential_analysis/CTK4me1/run_edgeR_one_comparison_CTK4me1.R
```

CTK27ac:

```text
script/05_differential_analysis/CTK27ac/submit_edgeR_all_comparisons_CTK27ac.sh
script/05_differential_analysis/CTK27ac/run_edgeR_one_comparison_CTK27ac.slurm
script/05_differential_analysis/CTK27ac/run_edgeR_one_comparison_CTK27ac.R
```

## Inputs

Metadata:

```text
script/metadata_form/Metadata_Comparison.csv
```

CTK4me1 quantification matrix:

```text
${PROJECT_ROOT}/quantification/CTK4me1/<CPS>_seacr_consensus_profile_bins.xls
```

CTK27ac quantification matrix:

```text
${PROJECT_ROOT}/quantification/CTK27ac/<CPS>_macs3_per_sample_summit_profile_bins.xls
```

Annotation resources:

```text
/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/mm39_vM38_pc_lnc_miRNA.sqlite
/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/GENCODE_vM38_GeneMap.rds
```

## Per-Comparison Logic

For each row in the active metadata file, the edgeR script:

1. reads the relevant CPS quantification matrix
2. matches group1 and group2 count columns
3. matches group1 and group2 occupancy columns
4. builds a count matrix for the current comparison
5. applies `edgeR::filterByExpr`
6. calculates TMM normalization factors with `calcNormFactors`
7. estimates dispersion
8. fits a quasi-likelihood GLM with `glmQLFit`
9. runs `glmQLFTest`
10. annotates regions with ChIPseeker
11. adds gene symbols from the GENCODE gene map
12. writes result, summary, filter-stat, and chromosome-distribution files

## Direction Convention

The current scripts define log fold change as:

```text
Group1 - Group2
```

Direction labels are:

```text
Group1_Higher  if logFC > 0
Group2_Higher  if logFC < 0
No_Change      if logFC == 0
```

This convention matches the output file naming:

```text
<group1>_vs_<group2>
```

## Filtering Note

The scripts calculate both expression-based and occupancy-based filtering statistics. In the current code, the final tested set uses:

```r
keep <- keep_expr
```

The occupancy filter count is still reported in the filter statistics, but it is not currently combined into the final edgeR test set.

## Outputs

Main output directories:

```text
${PROJECT_ROOT}/edgeR_DE_results/CTK4me1
${PROJECT_ROOT}/edgeR_DE_results/CTK27ac
```

Per-comparison outputs include:

```text
<CPS>_Comp<comp>_<marker>_<group1>_vs_<group2>_edgeR_results.txt
<CPS>_Comp<comp>_<marker>_edgeR_summary.csv
<CPS>_Comp<comp>_<marker>_edgeR_filter_stats.csv
<CPS>_Comp<comp>_<marker>_edgeR_dist.csv
```

The full result table contains edgeR statistics, genomic coordinates, ChIPseeker annotation, gene IDs, gene symbols, CPS ID, comparison ID, marker, and direction label.
