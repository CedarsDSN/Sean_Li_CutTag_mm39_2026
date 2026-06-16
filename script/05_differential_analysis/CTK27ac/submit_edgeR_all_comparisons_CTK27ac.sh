#!/bin/bash
set -eo pipefail

PROJECT_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39
METADATA_FILE="${PROJECT_ROOT}/script/metadata_form/Metadata_Comparison.csv"
RUN_SCRIPT="${PROJECT_ROOT}/script/05_differential_analysis/CTK27ac/run_edgeR_one_comparison_CTK27ac.slurm"

if [[ ! -f "$METADATA_FILE" ]]; then
    echo "ERROR: Metadata file not found: $METADATA_FILE"
    exit 1
fi

if [[ ! -f "$RUN_SCRIPT" ]]; then
    echo "ERROR: Run script not found: $RUN_SCRIPT"
    exit 1
fi

N=$(awk -F',' 'NR>1 && $5=="CTK27ac" {print $1}' "$METADATA_FILE" | wc -l)

if [[ "$N" -eq 0 ]]; then
    echo "ERROR: No CTK27ac comparisons found in metadata."
    exit 1
fi

echo "Submitting ${N} CTK27ac edgeR comparison jobs..."
sbatch --array=1-"$N" "$RUN_SCRIPT"
