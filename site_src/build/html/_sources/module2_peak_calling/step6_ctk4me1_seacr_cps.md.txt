# Step 6: CTK4me1 SEACR Peak Calling and CPS Generation

## Purpose

The current CTK4me1 branch uses SEACR peak calling followed by metadata-driven CPS consensus peak generation.

This branch is separate from CTK27ac, which uses MACS3.

## Scripts

```text
script/03_peak_calling/CTK4me1/submit_seacr_callpeak_CTK4me1.sh
script/03_peak_calling/CTK4me1/run_seacr_peak_calling_CTK4me1.sh
script/03_peak_calling/CTK4me1/run_cps_generation.sh
```

## SEACR Inputs

The SEACR script expects bedGraph files in:

```text
${PROJECT_ROOT}/seacr_bedgraph/CTK4me1
```

with this pattern:

```text
*.seacr.bedgraph
```

Control-like files matching `IgG` or `nAb` are excluded.

## SEACR Parameters

SEACR settings are configured in:

```text
script/config/project_config.sh
```

Current values:

```bash
SEACR_THRESHOLD="0.01"
SEACR_MODE="stringent"
```

The active SEACR call is:

```bash
bash "$SEACR_EXEC" \
    "$CURRENT_BG" \
    "$SEACR_THRESHOLD" \
    non \
    "$SEACR_MODE" \
    "$OUTPUT_PREFIX"
```

## SEACR Outputs

Sample-level CTK4me1 peaks are written to:

```text
${PROJECT_ROOT}/seacr_peak_calling/CTK4me1
```

Expected downstream naming:

```text
<sample>-CTK4me1-<replicate>.0.01.stringent.bed
```

## CPS Consensus Peak Generation

After sample-level SEACR peak calling, `run_cps_generation.sh` creates one consensus peak set per CPS.

The script reads the active metadata file:

```text
metadata_form/Metadata_Comparison.csv
```

For each CTK4me1 CPS, it:

1. collects all groups appearing in `group1` and `group2`
2. expands semicolon-separated group names
3. finds all matching CTK4me1 replicate SEACR peak files
4. concatenates the matching peak intervals
5. sorts and merges them with bedtools

## CPS Outputs

Consensus peaks are written to:

```text
${PROJECT_ROOT}/consensus_peaks/CTK4me1/<CPS>_consensus.bed
```

A merge manifest is also written:

```text
${PROJECT_ROOT}/consensus_peaks/CTK4me1/merging_manifest.log
```

## Downstream Role

The CTK4me1 quantification script uses each `<CPS>_consensus.bed` file as the `--bins` feature universe for `profile_bins`.

These CPS consensus intervals define the rows of the CTK4me1 count matrix used by edgeR.
