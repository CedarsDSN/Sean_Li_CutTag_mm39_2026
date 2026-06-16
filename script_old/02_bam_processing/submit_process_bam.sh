#!/bin/bash

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh

SAMPLES=$(ls "$BAM_DIR"/*.coordsorted.bam | xargs -n 1 basename | sed 's/.coordsorted.bam//')

for SAMPLE in $SAMPLES
do
    echo "Submitting processing job for: $SAMPLE"
    sbatch --job-name="proc_$SAMPLE" "${BAM_PROCESS_DIR}/run_process_bam.sh" "$SAMPLE"
done
