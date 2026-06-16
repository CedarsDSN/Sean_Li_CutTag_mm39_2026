#!/bin/bash
# Pre-check script to verify if SEACR peak files exist for each metadata entry

# --- Path Definitions ---
CSV_FILE="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/Metadata_CTK27ac_Comparison.csv"
DIRECTORY_PATH="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/seacr_stringent_001"

echo "Checking Metadata vs. Peak Files..."
echo "Metadata File: $CSV_FILE"
echo "Peak Directory: $DIRECTORY_PATH"
echo "------------------------------------------"

# Counters for summary
TOTAL_SAMPLES=0
MISSING_SAMPLES=0

# Extract all unique sample names mentioned in group1 and group2
# This handles comma/semicolon separation and whitespace
ALL_SAMPLES=$(tail -n +2 "$CSV_FILE" | awk -F',' '{print $3,$4}' | tr ';' '\n' | tr ' ' '\n' | sort -u)

for sname in $ALL_SAMPLES; do
    # Remove carriage returns and leading/trailing spaces
    sname=$(echo "$sname" | tr -d '\r' | xargs)
    if [[ -z "$sname" ]]; then continue; fi
    
    ((TOTAL_SAMPLES++))

    # Pattern matching based on your file: WT-Uro-m-mtND6-CTK27ac-1.rmdup.01.stringent.bed
    # We use a wildcard (*) to bridge the gap between sample name and suffix
    MATCH_FILE=$(ls ${DIRECTORY_PATH}/${sname}*.01.stringent.bed 2>/dev/null | head -n 1)

    if [[ -f "$MATCH_FILE" ]]; then
        echo "[OK] Found: $(basename "$MATCH_FILE")"
    else
        echo "[MISSING] No file for sample ID: '$sname'"
        ((MISSING_SAMPLES++))
    fi
done

echo "------------------------------------------"
echo "Check Summary:"
echo "Total unique samples in Metadata: $TOTAL_SAMPLES"
echo "Missing files: $MISSING_SAMPLES"

if [ $MISSING_SAMPLES -eq 0 ]; then
    echo "STATUS: SUCCESS. All files are ready for consensus merging."
else
    echo "STATUS: WARNING. Please fix the missing files or update the CSV names."
fi
