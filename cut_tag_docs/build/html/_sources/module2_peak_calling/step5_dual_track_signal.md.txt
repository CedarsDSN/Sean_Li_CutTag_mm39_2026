# Step 5: Dual-Track Signal Generation

## Overview

A critical, yet often overlooked, aspect of CUT&Tag analysis is that genome-browser visualization and peak calling require different signal representations, even when they originate from the same aligned BAM files. To address this, we implemented a Dual-Track Signal Generation strategy: 

1. **Human-readable track**: Normalized, moderately smoothed `BigWig` files optimized for visual inspection in IGV.
2. **Machine-readable track**: Raw, exact-resolution, strictly filtered `BedGraph` files optimized for the SEACR peak caller.

This separation is intentional: browser tracks are designed for human interpretation of local signal patterns, whereas SEACR requires a raw fragment-level signal landscape for accurate thresholding and peak boundary detection.

---

## Track 1: Human-Readable Signals (BigWig for IGV)

For browser-based visualization, we want tracks that are easy to compare across libraries with different sequencing depths and sufficiently smooth to reduce meaningless base-level noise. For this purpose, we generate CPM-normalized BigWig files using `deepTools bamCoverage`.

### Example Command

```bash
# Define paths
bam_dir="path/to/bams"
out_root="path/to/bigwigs"
blacklist="path/to/mm39.excluderanges.bed"

current_bam=${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}
base_name=$(basename "$current_bam")
output_bw="${out_root}/${base_name%.bam}.cpm.bw"

bamCoverage \
  --bam "$current_bam" \
  --outFileName "$output_bw" \
  --outFileFormat bigwig \
  --normalizeUsing CPM \
  --binSize 10 \
  --extendReads \
  --ignoreForNormalization chrM \
  --blackListFileName "$blacklist" \
  --numberOfProcessors 8 \
  --minMappingQuality 10
```

### Rationale

* **`--normalizeUsing CPM`**: Scales coverage by library size (counts per million mapped reads), making browser tracks more comparable across samples with different sequencing depths. These tracks are intended for visualization of local signal patterns, not for formal differential inference.
* **`--binSize 10`**: Aggregates signal in 10 bp windows, which reduces visual noise and substantially decreases file size, making IGV browsing more responsive.
* **`--extendReads`**: Produces a smoother approximation of fragment-level coverage for visualization. This is useful for browser inspection, but these extended tracks are not used for peak calling.
* **`--ignoreForNormalization chrM`**: Excludes mitochondrial reads from library-size normalization, since extremely high mitochondrial signal can distort CPM scaling.
* **`--blackListFileName`**: Suppresses known high-signal artifact regions in the mm39 genome for cleaner visual interpretation.

> **Important Note:** These CPM-normalized BigWig files are used *only* for browser visualization. Formal differential analysis is performed separately using the MAnorm2 framework on count matrices, not on the BigWig tracks.

---

## Track 2: Machine-Readable Signals (BedGraph for SEACR)

SEACR requires raw fragment pileup profiles rather than normalized or smoothed browser tracks. Therefore, we generate a separate signal representation specifically for peak calling.

### Why not use the browser BigWig/BedGraph for SEACR?

1. **Binning alters signal structure**: A binned track (for example, `binSize 10`) coarsens the signal landscape and can blur short true zero-signal gaps between adjacent enriched regions. SEACR relies on the exact structure of contiguous signal blocks separated by genuine zeros, so binned tracks are not appropriate inputs.
2. **Normalization changes the empirical signal distribution**: SEACR is designed to operate on raw fragment pileup profiles. Library-size normalization or smoothing changes the signal distribution on which SEACR's thresholding strategy is based.
3. **Exact fragment boundaries matter**: For CUT&Tag, we want SEACR to see the true paired-end fragment coordinates rather than visually smoothed or extended signal approximations.

### Exact fragment-level BedGraph generation for SEACR

To preserve true fragment structure, we follow a fragment-based workflow that converts paired-end BAM files into exact fragment intervals and then computes base-resolution coverage.

```bash
# Define paths & references
CHROMSIZES="path/to/mm39.chrom.sizes"

CURRENT_BAM="${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}"
BASE_NAME=$(basename "$CURRENT_BAM" .bam)

TMP_BAM="${OUT_DIR}/${BASE_NAME}.name_sorted.bam"
BEDPE_FILE="${OUT_DIR}/${BASE_NAME}.bedpe"
CLEAN_BEDPE="${OUT_DIR}/${BASE_NAME}.clean.bedpe"
FRAG_BED="${OUT_DIR}/${BASE_NAME}.fragments.bed"
OUT_BG="${OUT_DIR}/${BASE_NAME}.seacr.bedgraph"

# 1. Name-sort BAM (required for bedtools bamtobed -bedpe)
samtools sort -n -@ 4 -o "$TMP_BAM" "$CURRENT_BAM"

# 2. Convert paired-end BAM to BEDPE
bedtools bamtobed -bedpe -i "$TMP_BAM" > "$BEDPE_FILE"

# 3. Retain only biologically plausible fragments:
# - both mates on the same chromosome ($1==$4)
# - positive fragment length ($6>$2)
# - fragment size < 1000 bp
awk '$1==$4 && $6>$2 && ($6-$2)<1000 {print $0}' "$BEDPE_FILE" > "$CLEAN_BEDPE"

# 4. Extract outer fragment coordinates and sort for genomecov
cut -f 1,2,6 "$CLEAN_BEDPE" | sort -k1,1 -k2,2n -k3,3n > "$FRAG_BED"

# 5. Generate exact fragment pileup BedGraph
bedtools genomecov -bg -i "$FRAG_BED" -g "$CHROMSIZES" > "$OUT_BG"

# 6. Clean up large intermediate files
rm -f "$TMP_BAM" "$BEDPE_FILE" "$CLEAN_BEDPE" "$FRAG_BED"
```

### Rationale

* **Name-sorted BAM**: `bedtools bamtobed -bedpe` requires name-sorted paired-end alignments so that mate information can be reconstructed correctly.
* **Same-chromosome filtering (`$1==$4`)**: Removes discordant inter-chromosomal pairs that typically represent mapping artifacts or anomalous fragments rather than genuine local chromatin fragments.
* **Positive fragment length (`$6>$2`)**: Ensures valid fragment coordinates before downstream coverage calculation.
* **Fragment size filter (`($6-$2)<1000`)**: Removes unusually large fragments, which are generally more consistent with background, mapping artifacts, or anomalous long-range events than bona fide CUT&Tag chromatin fragments.
* **Coordinate sorting before genomecov**: Ensures that `bedtools genomecov` receives properly ordered intervals for stable and reproducible coverage generation.
* **`bedtools genomecov -bg`**: Produces an exact fragment-pileup BedGraph without smoothing or library-size normalization, preserving the native signal structure required by SEACR.

> **Important Note:** Unlike the browser BigWig tracks, these SEACR input BedGraph files are generated from the raw filtered fragment set and are not library-size normalized or visually smoothed.

---

## Practical Distinction Between the Two Track Types

| Feature | Track 1: Human-Readable | Track 2: Machine-Readable |
| :--- | :--- | :--- |
| **Output format** | `BigWig` | `BedGraph` |
| **Primary use** | IGV / genome browser visualization | SEACR peak calling |
| **Normalized** | Yes (CPM) | No |
| **Smoothed/Binned** | Yes (`binSize 10`, read extension) | No (Exact base-resolution) |
| **Used for differential inference** | No | Indirectly, through called peaks |

### Key Take-Home Message

The same aligned BAM files are intentionally transformed into two different signal products for two different purposes:
1. **CPM-normalized BigWig tracks** for human interpretation in genome browsers.
2. **Raw fragment-level BedGraph tracks** for SEACR peak calling.

This dual-track strategy ensures that browser visualization remains interpretable and efficient, while peak calling remains mathematically faithful to the underlying CUT&Tag fragment structure.
