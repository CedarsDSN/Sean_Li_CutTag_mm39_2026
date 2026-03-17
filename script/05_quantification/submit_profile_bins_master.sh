#!/bin/bash

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh

CSV_FILE="${METADATA_CURRENT}"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "ERROR: Metadata file not found: $CSV_FILE"
    exit 1
fi

mapfile -t CPS_LIST < <(tail -n +2 "$CSV_FILE" | cut -d, -f1 | sort -u)

if [[ ${#CPS_LIST[@]} -eq 0 ]]; then
    echo "ERROR: No CPS IDs found in metadata file: $CSV_FILE"
    exit 1
fi

TARGET="${1:-all}"

if [[ "$TARGET" == "all" ]]; then
    ARRAY_SPEC="1-${#CPS_LIST[@]}"
    echo "Submitting all CPS jobs: $ARRAY_SPEC"
else
    ARRAY_SPEC=""
    for i in "${!CPS_LIST[@]}"; do
        idx=$((i+1))
        cps="${CPS_LIST[$i]}"
        if [[ "$cps" == "$TARGET" ]]; then
            ARRAY_SPEC="$idx"
            break
        fi
    done

    if [[ -z "$ARRAY_SPEC" ]]; then
        echo "ERROR: CPS not found in metadata: $TARGET"
        echo "Available CPS IDs:"
        printf '  %s\n' "${CPS_LIST[@]}"
        exit 1
    fi

    echo "Submitting single CPS job: $TARGET (array index $ARRAY_SPEC)"
fi

sbatch \
  --job-name=manorm2_counts \
  --nodes=1 \
  --ntasks=1 \
  --cpus-per-task=4 \
  -p defq \
  -t 04:00:00 \
  --mem=32GB \
  --array="$ARRAY_SPEC" \
  -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/manorm2_counts_%A_%a.log \
  "${QUANT_DIR}/run_profile_bins_master.sh"
