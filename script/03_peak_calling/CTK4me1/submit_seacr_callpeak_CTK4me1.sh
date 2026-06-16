#!/bin/bash
set -eo pipefail

PROJECT_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39
BG_DIR="${PROJECT_ROOT}/seacr_bedgraph/CTK4me1"
RUN_SCRIPT="${PROJECT_ROOT}/script/03_peak_calling/CTK4me1/run_seacr_peak_calling_CTK4me1.sh"

if [[ ! -d "$BG_DIR" ]]; then
    echo "ERROR: BG_DIR does not exist: $BG_DIR"
    exit 1
fi

if [[ ! -f "$RUN_SCRIPT" ]]; then
    echo "ERROR: Run script not found: $RUN_SCRIPT"
    exit 1
fi

N=$(find "$BG_DIR" -maxdepth 1 -name "*.seacr.bedgraph" | grep -viE "IgG|nAb" | wc -l)

if [[ "$N" -eq 0 ]]; then
    echo "ERROR: No valid CTK4me1 seacr bedGraph files found in $BG_DIR"
    exit 1
fi

echo "Submitting ${N} CTK4me1 SEACR jobs..."
sbatch --array=1-"$N"%50 "$RUN_SCRIPT"
