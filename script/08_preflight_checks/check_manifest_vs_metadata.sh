#!/bin/bash

set -eo pipefail

META_FILE="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/metadata_form/Metadata_Comparison.csv"
MANIFEST_FILE="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/consensus_peaks/merging_manifest.log"
PEAK_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/seacr_peak_calling"
SEACR_SUFFIX=".rmdup.0.01.stringent.bed"

if [[ ! -f "$META_FILE" ]]; then
    echo "ERROR: Metadata file not found: $META_FILE"
    exit 1
fi

if [[ ! -f "$MANIFEST_FILE" ]]; then
    echo "ERROR: Manifest file not found: $MANIFEST_FILE"
    exit 1
fi

if [[ ! -d "$PEAK_DIR" ]]; then
    echo "ERROR: Peak directory not found: $PEAK_DIR"
    exit 1
fi

echo "Checking manifest vs metadata..."
echo "Metadata : $META_FILE"
echo "Manifest : $MANIFEST_FILE"
echo "Peak dir  : $PEAK_DIR"
echo "------------------------------------------"

tail -n +2 "$MANIFEST_FILE" | while IFS=, read -r cps_id marker merged_files; do
    cps_id=$(echo "$cps_id" | tr -d '\r' | xargs)
    marker=$(echo "$marker" | tr -d '\r' | xargs)

    echo "Checking $cps_id ($marker)"

    # --------------------------------------
    # Get expected group/sample labels from metadata
    # --------------------------------------
    expected_groups=$(awk -F',' -v cps="$cps_id" -v mk="$marker" '
        NR==1 {next}
        $1 == cps {
            m=$NF
            gsub(/\r/, "", m)
            gsub(/^[ \t]+|[ \t]+$/, "", m)
            if (m == mk) {
                print $3
                print $4
            }
        }
    ' "$META_FILE" \
    | tr ';' '\n' \
    | sed 's/^ *//; s/ *$//' \
    | sed '/^$/d' \
    | sort -u)

    # --------------------------------------
    # Resolve expected actual peak files by searching PEAK_DIR
    # --------------------------------------
    exp_file=$(mktemp)
    : > "$exp_file"

    while IFS= read -r grp; do
        [[ -z "$grp" ]] && continue

        find "$PEAK_DIR" -maxdepth 1 -type f -name "${grp}*${marker}*${SEACR_SUFFIX}" \
            | grep -viE 'IgG|nAb|CTnAb' \
            | xargs -r -n 1 basename \
            >> "$exp_file"
    done <<< "$expected_groups"

    sort -u "$exp_file" -o "$exp_file"

    # --------------------------------------
    # Parse actual manifest files
    # --------------------------------------
    act_file=$(mktemp)

    echo "$merged_files" \
        | tr ';' '\n' \
        | sed 's/^ *//; s/ *$//' \
        | sed '/^$/d' \
        | sort -u \
        > "$act_file"

    # --------------------------------------
    # Compare
    # --------------------------------------
    missing=$(comm -23 "$exp_file" "$act_file" || true)
    extra=$(comm -13 "$exp_file" "$act_file" || true)

    if [[ -z "$missing" && -z "$extra" ]]; then
        echo "  [OK] Manifest matches metadata"
    else
        echo "  [WARNING] Differences found"

        if [[ -n "$missing" ]]; then
            echo "    Missing files:"
            echo "$missing" | sed 's/^/      - /'
        fi

        if [[ -n "$extra" ]]; then
            echo "    Extra files:"
            echo "$extra" | sed 's/^/      - /'
        fi
    fi

    rm -f "$exp_file" "$act_file"
    echo "------------------------------------------"
done
