# Step 7: Consensus Peak Set (CPS) Generation

## Overview

Peak calling (Step 6) identifies enriched regions independently for each individual sample. Because biological variation, sequencing depth, and local peak shape can vary across samples, the exact genomic boundaries of an enriched region often differ slightly between replicates and between comparison-relevant samples.



For downstream quantitative analysis (for example, MAnorm2-based counting and differential testing), overlapping but misaligned peak intervals cannot be compared directly. Instead, we must first define a unified, non-overlapping genomic feature space within each analysis group. This unified master catalog of enriched regions is referred to here as the **Consensus Peak Set (CPS)**.

Importantly, in this project, each CPS is metadata-defined rather than simply replicate-defined. That is, each CPS is constructed by grouping all relevant samples assigned to the same comparison framework and histone marker, then merging their per-sample SEACR peaks into a single non-redundant feature set.

---

## Metadata-Driven Execution

Because this project includes multiple histone markers (for example, CTK27ac, CTK4me1, CTK4me3, and CTK27me3) and many distinct biological sample groups, CPS generation was implemented using a strictly metadata-driven strategy.

Instead of hardcoding sample names into the script, a single metadata file, `Metadata_Comparison.csv`, is used to define:

* The CPS ID
* The relevant biological group names to include
* The associated histone marker for that CPS

This design allows the same script to be reused across analyses by modifying only the contents of the metadata file, without changing script logic or file naming conventions.

### Execution Command

```bash
# Define paths
OUT_DIR="path/to/consensus_peaks"
MANIFEST="${OUT_DIR}/merge_manifest.csv"
CSV_FILE="path/to/Metadata_Comparison.csv"
DIRECTORY_PATH="path/to/seacr_stringent_001"

mkdir -p "$OUT_DIR"

# Header for the manifest log
echo "CPS_ID,Marker,Merged_Files" > "$MANIFEST"

# Extract unique CPS IDs from metadata
tail -n +2 "$CSV_FILE" | cut -d, -f1 | sort | uniq | while read CPS; do

    UNION_FILE="${OUT_DIR}/${CPS}_union.bed"
    MERGED_FILE="${OUT_DIR}/${CPS}_consensus.bed"
    file_list=""

    # 1. Extract the marker assigned to this CPS
    MARKER=$(grep "^${CPS}," "$CSV_FILE" | head -n 1 | awk -F',' '{print $5}' | tr -d '\r' | xargs)

    > "$UNION_FILE"

    # 2. Extract all group names participating in this CPS
    SAMPLES=$(grep "^${CPS}," "$CSV_FILE" | awk -F',' '{print $3,$4}' | tr ';' '\n' | tr ' ' '\n' | sort -u)

    for sname in $SAMPLES; do
        sname=$(echo "$sname" | tr -d '\r' | xargs)
        if [[ -z "$sname" ]]; then
            continue
        fi

        # 3. Match sample name + marker, while excluding negative controls
        MATCH_FILES=$(ls ${DIRECTORY_PATH}/${sname}*${MARKER}*.stringent.bed 2>/dev/null | grep -viE "IgG|nAb")

        if [[ -n "$MATCH_FILES" ]]; then
            for M_FILE in $MATCH_FILES; do
                fname=$(basename "$M_FILE")
                cat "$M_FILE" >> "$UNION_FILE"
                file_list="${file_list}${fname}; "
            done
        fi
    done

    # 4. Sort and merge into final CPS feature set
    if [ -s "$UNION_FILE" ]; then
        bedtools sort -i "$UNION_FILE" | bedtools merge -i - > "$MERGED_FILE"

        # Record provenance
        echo "${CPS},${MARKER},${file_list}" >> "$MANIFEST"
        rm -f "$UNION_FILE"
    fi
done 
```

---

## Key Design Rationale

### 1. Unified feature space for downstream counting and differential analysis
Downstream tools such as MAnorm2 require a master count matrix in which each row represents one genomic feature, and each column represents one sample. This is only possible if all samples assigned to the same analytical context are projected onto the same genomic coordinate system. By merging overlapping per-sample peak intervals into a single CPS, we avoid representing the same local enrichment signal as multiple overlapping feature rows in the downstream count matrix.

### 2. Metadata-defined CPS construction
In this workflow, CPS construction is not limited to simple replicate consensus. Instead, each CPS is defined by the comparison metadata and may include all samples relevant to a particular analysis group within a specific histone marker. This makes CPS generation reproducible, scalable across many comparisons, and adaptable without rewriting scripts.

### 3. Union-and-merge strategy rather than strict intersection



The CPS is generated using a union-and-merge strategy:
* All relevant per-sample peak files are concatenated.
* Overlapping intervals are merged into one non-redundant region.

This differs from a strict intersection-based consensus, in which only peaks shared by all samples would be retained. The union-and-merge strategy is more appropriate here because it preserves the full candidate regulatory landscape needed for downstream count-based comparison, while still collapsing redundant overlap structure.

### 4. Strict marker segregation
Different histone modifications have different genomic distributions and biological interpretations. For example, CTK27ac and CTK4me1 often mark different regulatory states and can differ substantially in peak breadth and genomic localization. For this reason, CPS generation is performed separately for each marker. The script dynamically extracts the marker assignment from `Metadata_Comparison.csv` and ensures that only peak files from the matching histone mark are merged into the same CPS. This prevents biologically meaningless mixing of different epigenetic signal types.

### 5. Systematic exclusion of negative controls
Negative control tracks such as IgG and nAb are intentionally excluded from CPS construction. The CPS is intended to represent target-specific enriched regions rather than background signal structure. In this project, control libraries were used primarily for QC and visualization reference, not for defining the target-region feature universe.

### 6. Manifest generation for reproducibility
Large CUT&Tag projects can become difficult to audit if the provenance of each merged peak set is not tracked explicitly. Therefore, the script automatically generates a `merge_manifest.csv` file recording the CPS ID, the marker, and the exact per-sample `.stringent.bed` files included in the union step. This provides file-level provenance for each generated CPS and helps ensure reproducibility and traceability.

---

## Output

This workflow produces two main outputs:

1. **Consensus BED files (`*_consensus.bed`)**: These files define the unified genomic feature space for each metadata-defined, marker-specific CPS.
2. **Merge manifest (`merge_manifest.csv`)**: This file records which individual SEACR peak files were merged to produce each CPS.

These consensus BED files are then used in the next step as the genomic templates for generating the master counts matrix.

### Key Take-Home Message

The Consensus Peak Set (CPS) is a metadata-defined, marker-specific, union-merged genomic feature set that provides a unified coordinate framework for downstream sample quantification and differential analysis.

By deriving CPS files directly from `Metadata_Comparison.csv`, this workflow remains scalable, reproducible, and easy to update: new comparison schemes can be implemented simply by editing the metadata contents, without changing the underlying script.
