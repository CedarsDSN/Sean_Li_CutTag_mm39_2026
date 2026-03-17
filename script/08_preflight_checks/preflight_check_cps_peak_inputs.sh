#!/bin/bash

set -euo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh

CSV_FILE="${METADATA_CURRENT}"
PEAK_DIR="${PROJECT_ROOT}/seacr_peak_calling"

echo "Checking metadata vs. SEACR peak files..."
echo "Metadata file: $CSV_FILE"
echo "Peak directory: $PEAK_DIR"
echo "------------------------------------------"

TOTAL_EXPECTED=0
FOUND_FILES=0
MISSING_FILES=0

tail -n +2 "$CSV_FILE" | while IFS=, read -r CPS comp group1 group2 marker; do
    CPS=$(echo "$CPS" | tr -d '\r' | xargs)
    comp=$(echo "$comp" | tr -d '\r' | xargs)
    marker=$(echo "$marker" | tr -d '\r' | xargs)

    echo "CPS: $CPS | Comp: $comp | Marker: $marker"

    SAMPLES=$(printf "%s\n%s\n" "$group1" "$group2" | tr ';' '\n' | tr ' ' '\n' | sed '/^$/d' | sort -u)

    for sname in $SAMPLES; do
        sname=$(echo "$sname" | tr -d '\r' | xargs)
        [[ -z "$sname" ]] && continue

        TOTAL_EXPECTED=$((TOTAL_EXPECTED + 1))

        MATCH_FILE=$(ls "${PEAK_DIR}"/${sname}*${marker}*.stringent.bed 2>/dev/null | grep -viE "IgG|nAb|CTnAb" | head -n 1 || true)

        if [[ -f "$MATCH_FILE" ]]; then
            echo "  [OK] Found: $(basename "$MATCH_FILE")"
            FOUND_FILES=$((FOUND_FILES + 1))
        else
            echo "  [MISSING] No SEACR peak file for sample: '$sname' with marker: '$marker'"
            MISSING_FILES=$((MISSING_FILES + 1))
        fi
    done

    echo "------------------------------------------"
done

echo "Preflight Check Summary:"
echo "Total expected sample-marker pairs: $TOTAL_EXPECTED"
echo "Found files: $FOUND_FILES"
echo "Missing files: $MISSING_FILES"

if [[ "$MISSING_FILES" -eq 0 ]]; then
    echo "STATUS: SUCCESS. All required SEACR peak files are present."
else
    echo "STATUS: WARNING. Some required SEACR peak files are missing."
fi
