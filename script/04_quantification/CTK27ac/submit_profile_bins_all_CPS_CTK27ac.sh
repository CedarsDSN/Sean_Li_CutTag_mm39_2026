#!/bin/bash
set -eo pipefail

METADATA_FILE=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/metadata_form/Metadata_Comparison.csv
RUN_SCRIPT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/04_quantification/CTK27ac/run_profile_bins_one_CPS_CTK27ac.sh

if [[ ! -f "$METADATA_FILE" ]]; then
    echo "ERROR: Metadata file not found: $METADATA_FILE"
    exit 1
fi

if [[ ! -f "$RUN_SCRIPT" ]]; then
    echo "ERROR: Run script not found: $RUN_SCRIPT"
    exit 1
fi

N=$(Rscript -e '
meta <- read.csv("'"${METADATA_FILE}"'", stringsAsFactors=FALSE, check.names=FALSE)
meta <- meta[meta$histone_marker == "CTK27ac", ]
cps <- sort(unique(meta$Concensus_peak))
cat(length(cps))
')

if [[ -z "$N" || "$N" -lt 1 ]]; then
    echo "ERROR: No CTK27ac CPS found."
    exit 1
fi

echo "Submitting ${N} CTK27ac CPS quantification jobs..."
sbatch --array=1-${N} "$RUN_SCRIPT"
