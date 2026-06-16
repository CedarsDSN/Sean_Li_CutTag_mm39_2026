# Step 7: BAM to Paired BED Conversion

## Purpose

The current quantification stage uses `profile_bins --paired`, which requires paired BED records rather than BAM input. This step converts the final blacklist-filtered BAM files into paired-end BED files with standardized mate names.

## Script

```text
script/04_quantification/run_bam_to_bed.sh
```

## Inputs

The script searches:

```text
${PROJECT_ROOT}/bam
```

for:

```text
*.rmdup.blfilter.bam
```

Controls matching `IgG`, `nAb`, or `CTnAb` are excluded.

## Processing Logic

For each BAM selected by the SLURM array task, the script:

1. sorts the BAM by read name
2. keeps proper pairs and removes unmapped, secondary, and supplementary alignments
3. converts BAM to BED6 using `bedtools bamtobed`
4. strips `/1` and `/2` mate suffixes from read names
5. keeps only complete read pairs with matching name and chromosome
6. removes temporary intermediate files

## Core Commands

```bash
samtools sort -n -@ 4 -o "$TMP_BAM" "$CURRENT_BAM"

samtools view -@ 4 -bh -f 0x2 -F 0x904 "$TMP_BAM" > "$FILTERED_BAM"

bedtools bamtobed -i "$FILTERED_BAM" > "$RAW_BED"
```

The AWK pairing logic then standardizes read names and writes two consecutive BED lines per valid read pair. This format is suitable for:

```bash
profile_bins --paired
```

## Outputs

Paired BED files are written to:

```text
${PROJECT_ROOT}/bam_to_bed/<SAMPLE_ID>.rmdup.blfilter.bed
```

## Downstream Role

These paired BED files are used by both marker-specific quantification branches:

- CTK4me1 `profile_bins` on CPS consensus bins
- CTK27ac `profile_bins` on MACS3 per-sample summits

This conversion step should be completed before submitting either marker's quantification jobs.
