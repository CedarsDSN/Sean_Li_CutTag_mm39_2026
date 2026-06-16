# Step 5: CTK27ac Peak Calling with MACS3

## Purpose

The current CTK27ac branch uses MACS3 for narrow peak calling. This differs from the CTK4me1 branch, which uses SEACR and CPS consensus peak generation.

CTK27ac peaks are called directly from the final filtered BAM files:

```text
*.rmdup.blfilter.bam
```

## Scripts

```text
script/03_peak_calling/CTK27ac/submit_macs3_callpeak_CTK27ac.sh
script/03_peak_calling/CTK27ac/run_macs3_callpeak_CTK27ac.sh
```

## Inputs

The submit script searches:

```bash
${PROJECT_ROOT}/bam
```

for:

```text
*CTK27ac*.rmdup.blfilter.bam
```

## MACS3 Command

The active command is:

```bash
macs3 callpeak \
  -t "$BAM_FILE" \
  -f BAMPE \
  -g 2654621783 \
  -n "$SAMPLE" \
  --outdir "${OUT_DIR}/${SAMPLE}" \
  -q 0.05 \
  --call-summits
```

## Outputs

Per-sample MACS3 outputs are written to:

```text
${PROJECT_ROOT}/macs3_peak_calls/CTK27ac/<SAMPLE_ID>/
```

The downstream quantification script expects:

```text
<SAMPLE_ID>_peaks.narrowPeak
<SAMPLE_ID>_summits.bed
```

## Downstream Role

The CTK27ac `profile_bins` stage uses both the narrowPeak and summit files:

- narrowPeak files provide sample-specific peak calls
- summit files define the local peak centers for per-sample summit-based quantification
- paired BED files provide the fragment-level read evidence

The CTK27ac branch does not currently generate CPS consensus BED files before quantification. Instead, quantification is performed using MACS3 per-sample summit inputs.
