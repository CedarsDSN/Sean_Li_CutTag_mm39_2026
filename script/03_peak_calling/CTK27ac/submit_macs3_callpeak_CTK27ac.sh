#!/bin/bash
set -eo pipefail

BAM_DIR=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam
RUN_SCRIPT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/03_peak_calling/CTK27ac/run_macs3_callpeak_CTK27ac.sh

N=$(find "$BAM_DIR" -maxdepth 1 -name "*CTK27ac*.rmdup.blfilter.bam" | wc -l)

if [[ "$N" -eq 0 ]]; then
    echo "ERROR: No CTK27ac rmdup.blfilter BAM files found in $BAM_DIR"
    exit 1
fi

echo "Submitting ${N} CTK27ac MACS3 jobs..."
sbatch --array=1-"$N" "$RUN_SCRIPT"
