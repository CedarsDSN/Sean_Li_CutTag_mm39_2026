# Step 4: BAM Processing and Filtering

## Purpose

This stage converts coordinate-sorted alignment BAMs into the final filtered BAM files used for downstream peak calling and quantification.

The final downstream BAM suffix is:

```text
.rmdup.blfilter.bam
```

## Scripts

```text
script/02_bam_processing/submit_process_bam.sh
script/02_bam_processing/run_process_bam.sh
```

## Inputs

```text
${PROJECT_ROOT}/bam/<SAMPLE_ID>.coordsorted.bam
```

## Processing Steps

The current script performs:

1. Proper-pair filtering with `samtools view -f 2`.
2. MAPQ filtering using `MAPQ_MIN` from `project_config.sh`.
3. Removal of chrM by dynamically extracting non-mitochondrial chromosome names from the BAM header.
4. Duplicate removal with Picard `MarkDuplicates`.
5. mm39 blacklist filtering with `bedtools intersect -v`.
6. Indexing and `flagstat` QC for the final BAM.

## Current Core Logic

```bash
CHRS=$(samtools view -H "$INPUT_BAM" | grep "^@SQ" | cut -f2 | sed 's/SN://' | grep -v "chrM")

samtools view -b -f 2 -q "$MAPQ_MIN" "$INPUT_BAM" $CHRS > "$FILTER_BAM"

picard -Xmx48g MarkDuplicates \
    -I "$FILTER_BAM" \
    -O "$RMDUP_BAM" \
    -REMOVE_DUPLICATES true \
    -METRICS_FILE "$METRICS_FILE"

bedtools intersect -abam "$RMDUP_BAM" -b "$BLACKLIST_BED" -v > "$BLFILTER_BAM"
```

## Reference Filter

The active blacklist is:

```text
script/reference/mm39.excluderanges.bed
```

## Outputs

Main processed BAM:

```text
${PROJECT_ROOT}/bam/<SAMPLE_ID>.rmdup.blfilter.bam
${PROJECT_ROOT}/bam/<SAMPLE_ID>.rmdup.blfilter.bam.bai
```

QC files:

```text
${PROJECT_ROOT}/qc/<SAMPLE_ID>.rmDups.metrics.txt
${PROJECT_ROOT}/qc/<SAMPLE_ID>.rmdup.stats
${PROJECT_ROOT}/qc/<SAMPLE_ID>.rmdup.blfilter.stats
```

## Downstream Role

The `.rmdup.blfilter.bam` files are the shared starting point for:

- CTK27ac MACS3 peak calling
- CTK4me1 bedGraph/SEACR peak calling branch
- BAM-to-paired-BED conversion for `profile_bins --paired`
