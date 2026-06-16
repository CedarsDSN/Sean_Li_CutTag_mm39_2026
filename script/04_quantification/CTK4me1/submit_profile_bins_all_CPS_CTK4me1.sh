#!/bin/bash
set -eo pipefail

PROJECT_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39
METADATA_FILE="${PROJECT_ROOT}/script/metadata_form/Metadata_Comparison.csv"
RUN_SCRIPT="${PROJECT_ROOT}/script/04_quantification/CTK4me1/run_profile_bins_one_CPS_CTK4me1.sh"

if [[ ! -f "$METADATA_FILE" ]]; then
    echo "ERROR: Metadata file not found: $METADATA_FILE"
    exit 1
fi

if [[ ! -f "$RUN_SCRIPT" ]]; then
    echo "ERROR: Run script not found: $RUN_SCRIPT"
    exit 1
fi

N=$(awk -F',' 'NR>1 && $5=="CTK4me1" {print $1}' "$METADATA_FILE" | tr -d '\r' | sort -u | wc -l)

if [[ "$N" -eq 0 ]]; then
    echo "ERROR: No CTK4me1 CPS found in metadata."
    exit 1
fi

echo "Submitting ${N} CTK4me1 CPS quantification jobs..."
sbatch --array=1-"$N" "$RUN_SCRIPT"
