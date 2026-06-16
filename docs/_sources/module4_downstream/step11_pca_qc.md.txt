# Step 11: PCA QC from edgeR-Normalized Counts

## Purpose

PCA is used as a sample-level quality-control and exploratory analysis step. It is not a formal differential-enrichment test.

The current PCA scripts use the same `profile_bins` count matrices used by edgeR, apply edgeR filtering and TMM normalization, convert counts to logCPM, and generate PCA plots for each CPS.

## Scripts

```text
script/06_summary_qc/CTK4me1/run_edgeR_PCA_all_CPS_CTK4me1.R
script/06_summary_qc/CTK27ac/run_edgeR_PCA_all_CPS_CTK27ac.R
```

## Inputs

CTK4me1 matrices:

```text
${PROJECT_ROOT}/quantification/CTK4me1/CPS*_seacr_consensus_profile_bins.xls
```

CTK27ac matrices:

```text
${PROJECT_ROOT}/quantification/CTK27ac/CPS*_macs3_per_sample_summit_profile_bins.xls
```

## PCA Workflow

For each CPS matrix, the script:

1. reads the `profile_bins` output table
2. removes chrM, chrUn, and random chromosomes
3. detects all `.read_cnt` columns
4. derives group labels from sample names
5. builds an edgeR `DGEList`
6. filters rows with `filterByExpr`
7. normalizes with edgeR TMM
8. computes logCPM with a prior count of 2
9. selects the top 2000 most variable retained peaks
10. runs PCA with `prcomp`
11. writes PC1-vs-PC2, PC1-vs-PC3, and PC2-vs-PC3 plots to PDF

## Minimum Feature Requirement

The current scripts require at least 2000 retained peaks after `filterByExpr`.

If fewer than 2000 peaks remain for a CPS, PCA for that CPS is skipped with a warning.

## Outputs

```text
${PROJECT_ROOT}/PCA_edgeR/CTK4me1/<CPS>_edgeR_PCA.pdf
${PROJECT_ROOT}/PCA_edgeR/CTK27ac/<CPS>_edgeR_PCA.pdf
```

Each PDF contains:

- PC1 vs PC2
- PC1 vs PC3
- PC2 vs PC3

## Interpretation

Use these plots to inspect:

- replicate consistency
- group-level clustering
- broad tissue, sex, genotype, or treatment structure
- possible outliers
- CPS-specific differences in global signal structure

PCA should be interpreted alongside alignment QC, BAM processing metrics, edgeR filter statistics, and the biological design encoded in the metadata.
