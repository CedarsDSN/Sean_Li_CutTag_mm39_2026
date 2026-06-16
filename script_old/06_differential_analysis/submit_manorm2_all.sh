#!/bin/bash
set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh

META="${METADATA_CURRENT}"
SCRIPT="${DE_DIR}/submit_manorm2_master_count.sh"

N=$(($(wc -l < "$META") - 1))

if [[ "$N" -le 0 ]]; then
    echo "ERROR: No comparison rows found in $META"
    exit 1
fi

echo "Submitting all MAnorm2 comparisons: 1-$N"
sbatch --array=1-"$N" "$SCRIPT"
