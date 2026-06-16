# Step 8: Marker-Specific Quantification with profile_bins

## Purpose

This step converts processed CUT&Tag fragments and marker-specific peak definitions into tabular count matrices for downstream edgeR analysis.

The current workflow uses `profile_bins` in two marker-specific ways:

- CTK4me1: quantify over SEACR-derived CPS consensus bins
- CTK27ac: quantify around MACS3 per-sample summits

The output matrices contain genomic coordinates, read counts, and occupancy information for the samples included in each CPS.

## Active Metadata

Most current scripts read:

```text
script/metadata_form/Metadata_Comparison.csv
```

The metadata columns are:

```text
Concensus_peak,comp,group1,group2,histone_marker
```

The scripts use this file to determine:

- which CPS IDs should be processed
- which marker branch each CPS belongs to
- which groups and replicate sample names should be included
- which comparison rows will later be tested by edgeR

## CTK4me1 Quantification

Scripts:

```text
script/04_quantification/CTK4me1/submit_profile_bins_all_CPS_CTK4me1.sh
script/04_quantification/CTK4me1/run_profile_bins_one_CPS_CTK4me1.sh
```

For each CTK4me1 CPS, the script builds a manifest containing:

- sample name
- sanitized label
- sample-level SEACR peak file
- paired BED read file

Inputs:

```text
${PROJECT_ROOT}/consensus_peaks/CTK4me1/<CPS>_consensus.bed
${PROJECT_ROOT}/seacr_peak_calling/CTK4me1/<sample>.0.01.stringent.bed
${PROJECT_ROOT}/bam_to_bed/<sample>.rmdup.blfilter.bed
script/reference/mm39.excluderanges.bed
```

The active `profile_bins` call is:

```bash
profile_bins \
  --bins="${BINS_FILE}" \
  --peaks="${PEAKS}" \
  --reads="${READS}" \
  --labs="${LABS}" \
  --paired \
  --filter="${BLACKLIST_BED}" \
  -n "${OUT_DIR}/${CPS}_seacr_consensus"
```

Output:

```text
${PROJECT_ROOT}/quantification/CTK4me1/<CPS>_seacr_consensus_profile_bins.xls
```

## CTK27ac Quantification

Scripts:

```text
script/04_quantification/CTK27ac/submit_profile_bins_all_CPS_CTK27ac.sh
script/04_quantification/CTK27ac/run_profile_bins_one_CPS_CTK27ac.sh
```

For each CTK27ac CPS, the script builds a manifest containing:

- sample name
- sanitized label
- MACS3 narrowPeak file
- MACS3 summit file
- paired BED read file

Inputs:

```text
${PROJECT_ROOT}/macs3_peak_calls/CTK27ac/<sample>/<sample>_peaks.narrowPeak
${PROJECT_ROOT}/macs3_peak_calls/CTK27ac/<sample>/<sample>_summits.bed
${PROJECT_ROOT}/bam_to_bed/<sample>.rmdup.blfilter.bed
script/reference/mm39.excluderanges.bed
```

The active `profile_bins` call is:

```bash
profile_bins \
  --peaks="${PEAKS}" \
  --summits="${SUMMITS}" \
  --reads="${READS}" \
  --labs="${LABS}" \
  --paired \
  --typical-bin-size 2000 \
  --filter="${BLACKLIST_BED}" \
  -n "${OUT_DIR}/${CPS}_macs3_per_sample_summit"
```

Output:

```text
${PROJECT_ROOT}/quantification/CTK27ac/<CPS>_macs3_per_sample_summit_profile_bins.xls
```

## Important Current-Code Note

At the time of this documentation update, the checked-in `Metadata_Comparison.csv` contains CTK4me1 rows. CTK27ac scripts also read `Metadata_Comparison.csv` in the current code. Therefore, before running CTK27ac quantification, confirm that CTK27ac rows are present in the active metadata file, or update the CTK27ac scripts to read `Metadata_CTK27ac_Comparison.csv`.

## Downstream Role

The quantification matrices are the direct inputs to edgeR differential analysis:

```text
script/05_differential_analysis/CTK4me1/run_edgeR_one_comparison_CTK4me1.R
script/05_differential_analysis/CTK27ac/run_edgeR_one_comparison_CTK27ac.R
```
