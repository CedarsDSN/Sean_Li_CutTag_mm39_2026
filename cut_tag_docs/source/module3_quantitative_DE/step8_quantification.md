# Step 8: Master Counts Matrix Generation

## Overview

To perform quantitative comparisons across multiple conditions, we must translate processed paired-end alignments into a structured numerical format. For each CPS, the goal of this step is to generate a **Master Counts Matrix** in which each row represents one genomic interval from the marker-specific Consensus Peak Set (CPS), each column represents one biological sample, and each cell records the corresponding fragment-level signal.



A separate master counts matrix is generated for each CPS. Together, these matrices provide the quantitative foundation for downstream normalization and differential enrichment analysis.

We use the `profile_bins` module from the **MAnorm2** suite to construct these matrices.

---

## Prerequisite: Paired-End BED Conversion and Read-Name Standardization

Because CUT&Tag signal is most appropriately represented at the fragment level rather than the individual read-end level, quantification should be performed using paired-end fragment coordinates whenever possible.

Accordingly, `profile_bins` is run in `--paired` mode. This mode does not accept BAM files directly in the same way as many standard counting tools; instead, it requires paired BED input with perfectly matched mate names.

A practical complication arises because `bedtools bamtobed` appends `/1` and `/2` suffixes to read names, whereas MAnorm2 `profile_bins --paired` expects the two mates of a fragment to have identical read names. Therefore, before matrix generation, aligned BAM files must be converted into paired BED files with standardized mate names.

In this workflow, this conversion is handled using a Slurm array script.

### Example Command Sequence

```bash
# Define paths
BAM_DIR="path/to/bam"
OUT_DIR="path/to/bam_to_bed"
mkdir -p "$OUT_DIR"

# 1. Collect BAM files, explicitly excluding IgG / nAb controls
BAM_LIST=($(find "$BAM_DIR" -maxdepth 1 -name "*rmdup.bam" | grep -viE "IgG|nAb" | sort))

CURRENT_BAM="${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}"
BASE_NAME=$(basename "$CURRENT_BAM" .bam)

TMP_BAM="${OUT_DIR}/${BASE_NAME}.tmp.name.bam"
FILTERED_BAM="${OUT_DIR}/${BASE_NAME}.tmp.filtered.bam"
OUT_BED="${OUT_DIR}/${BASE_NAME}.bed"

# 2. Sort BAM by read name (required for pairing logic)
samtools sort -n -@ 4 -o "$TMP_BAM" "$CURRENT_BAM"

# 3. Retain only high-confidence proper pairs
# -f 0x2   : keep properly paired alignments
# -F 0x904 : remove unmapped (0x4), secondary (0x100), supplementary (0x800)
samtools view -@ 4 -bh -f 0x2 -F 0x904 "$TMP_BAM" > "$FILTERED_BAM"

# 4. Convert to BED
bedtools bamtobed -i "$FILTERED_BAM" > "$OUT_BED.raw"

# 5. Strip /1 and /2 suffixes and enforce exact mate-name pairing
awk 'BEGIN{OFS="\t"}
{
    curr_name = $4
    sub("/[12]$", "", curr_name)
    curr_chr = $1
    
    if (curr_name == prev_name && curr_chr == prev_chr) {
        $4 = curr_name
        split(prev_line, p_arr, "\t")
        p_arr[4] = curr_name
        print p_arr[1], p_arr[2], p_arr[3], p_arr[4], p_arr[5], p_arr[6]
        print $0
        prev_name = ""
    } else {
        prev_line = $0
        prev_name = curr_name
        prev_chr = curr_chr
    }
}' "$OUT_BED.raw" > "$OUT_BED"

# 6. Clean up intermediate files
rm -f "$TMP_BAM" "$FILTERED_BAM" "$OUT_BED.raw"
```

### Rationale

* **Name-sorted BAM**: The pairing logic depends on mates being encountered consecutively. Therefore, BAM files must first be sorted by read name.
* **Proper-pair filtering (`-f 0x2 -F 0x904`)**: Only high-confidence paired alignments are retained. This removes unmapped, secondary, and supplementary alignments that would otherwise distort fragment quantification.
* **Read-name suffix stripping**: `bedtools bamtobed` appends `/1` and `/2` to mate names. These suffixes must be removed because `profile_bins --paired` requires identical mate names for the two reads belonging to the same fragment.
* **Exact mate pairing**: The AWK step standardizes mate names and ensures that only properly paired records with matching names and chromosomes are passed forward into the final BED file.
* **Control exclusion**: Negative control libraries (IgG/nAb) are excluded from BED generation because the master matrix is intended to quantify target-specific fragment enrichment across CPS intervals.

---

## Metadata-Driven Matrix Generation

Manually constructing `profile_bins` commands for dozens of samples would be highly error-prone. Therefore, we reuse the same metadata-driven logic established in Step 7.

A single metadata file, `Metadata_Comparison.csv`, defines:
1. The CPS identifier
2. The biological groups participating in that CPS
3. The associated histone marker

Using this file, the script dynamically associates the correct CPS BED file (Step 7), paired BED files (generated above), and original sample-specific SEACR peak files (Step 6). This ensures that quantification is reproducible, scalable, and fully synchronized with the comparison design.

### Example Command Sequence

```bash
# Define paths
OUT_DIR="path/to/count_matrices"
CSV_FILE="path/to/Metadata_Comparison.csv"
PEAK_DIR="path/to/consensus_peaks"      # Output from Step 7
BED_DIR="path/to/bam_to_bed"            # Paired BED files generated above
RAW_PEAK_DIR="path/to/seacr_peaks"      # Output from Step 6

mkdir -p "$OUT_DIR"

declare -A cps_samples
declare -A cps_marker

# 1. Aggregate all samples based on metadata
while IFS=, read -r CPS comp group1 group2 marker; do
    CPS=$(echo "$CPS" | xargs)
    marker=$(echo "$marker" | xargs)
    
    G1_SAMPLES=$(echo "$group1" | tr ';' ' ' | xargs)
    G2_SAMPLES=$(echo "$group2" | tr ';' ' ' | xargs)

    cps_samples["$CPS"]="${cps_samples["$CPS"]} $G1_SAMPLES $G2_SAMPLES"
    cps_marker["$CPS"]="$marker"
done < <(tail -n +2 "$CSV_FILE")

# 2. Iterate through each unique CPS
for CPS in "${!cps_samples[@]}"; do
    marker="${cps_marker[$CPS]}"
    CONSENSUS_PEAK="${PEAK_DIR}/${CPS}_consensus.bed"
    
    all_reads=()
    all_labs=()
    all_peaks=()

    UNIQUE_SAMPLES=$(echo "${cps_samples[$CPS]}" | tr ' ' '\n' | grep -v '^$' | sort -u)

    for sname in $UNIQUE_SAMPLES; do
        READ_FILES=$(ls ${BED_DIR}/${sname}*${marker}*.bed 2>/dev/null | grep -viE "IgG|nAb")

        for f in $READ_FILES; do
            lab_name=$(basename "$f" | sed 's/\.rmdup\.bed//')
            raw_p="${RAW_PEAK_DIR}/${lab_name}.rmdup.01.stringent.bed"

            if [ -f "$raw_p" ]; then
                all_reads+=("$f")
                all_peaks+=("$raw_p")

                # Replace hyphens with underscores for downstream R compatibility
                lab_name_clean=$(echo "$lab_name" | sed 's/-/_/g')
                all_labs+=("$lab_name_clean")
            else
                echo "### [ERROR] Raw peak not found for $lab_name: $raw_p" >&2
            fi
        done
    done

    if [ ${#all_reads[@]} -eq 0 ]; then
        echo "### [SKIP] No valid files found for CPS: $CPS" >&2
        continue
    fi

    READ_ARG=$(IFS=,; echo "${all_reads[*]}")
    LAB_ARG=$(IFS=,; echo "${all_labs[*]}")
    PEAK_ARG=$(IFS=,; echo "${all_peaks[*]}")

    # 3. Execute MAnorm2 profile_bins
    profile_bins \
        --bins="$CONSENSUS_PEAK" \
        --paired \
        --peaks="$PEAK_ARG" \
        --reads="$READ_ARG" \
        --labs="$LAB_ARG" \
        -n "${OUT_DIR}/${CPS}_master_counts"
done
```

---

## Key Parameter Rationale

### `--bins=$CONSENSUS_PEAK`
This argument defines the genomic feature space for quantification. Each row of the resulting master matrix corresponds exactly to one interval in the CPS BED file generated in Step 7. Because quantification is performed separately for each CPS, each output matrix is tied to one marker-specific consensus peak set.

### `--paired`
This flag is crucial for CUT&Tag fragment counting. Rather than counting single read ends, `profile_bins` treats identically named paired reads as one contiguous DNA fragment. This allows quantification to reflect the full fragment footprint rather than isolated read endpoints.

### `--peaks=$PEAK_ARG`
By supplying the original sample-specific SEACR peak files alongside the paired BED files, `profile_bins` appends an occupancy annotation for each sample and each CPS interval.

This occupancy value is binary (`1` or `0`) and indicates whether the CPS interval overlaps the original sample-specific peak set for that sample. **Importantly, this is not a re-called peak status on the CPS intervals themselves; rather, it records overlap with the original Step 6 peak calls.** This occupancy information is later used as one component of downstream feature filtering, together with count-based and variability-based criteria.

### Label sanitization (`sed 's/-/_/g'`)
Sample names often contain hyphens. When imported into R, hyphens in column names can be interpreted as subtraction operators and may break downstream parsing or formula-based analysis. Therefore, sample labels are sanitized by replacing hyphens with underscores before matrix generation. The original raw filenames remain traceable through the metadata structure and upstream file naming.

---

## Output

For each CPS group, this workflow produces one master tab-separated text file: `*_master_counts_profile_bins.xls`

Each file contains:
1. The genomic coordinates of each CPS interval.
2. The fragment-level counts for every biological sample.
3. The binary occupancy status (`0` or `1`) for every sample.

These CPS-specific master matrices serve as the definitive formatted input for statistical normalization and differential enrichment analysis in **Step 9**.

### Key Take-Home Message

This step converts metadata-defined CPS regions and processed paired-end CUT&Tag fragments into structured quantitative matrices suitable for downstream analysis. 

The resulting master matrix is not just a count table: it also preserves sample-specific occupancy information from the original SEACR peak calls, making it possible to combine fragment abundance and peak-support evidence in subsequent filtering and differential analysis.
