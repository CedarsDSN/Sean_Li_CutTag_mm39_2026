#!/bin/bash

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh

SAMPLES=$(ls "$FASTQ_DIR"/*_R1.fastq.gz | xargs -n 1 basename | sed 's/_R1.fastq.gz//')

for SAMPLE in $SAMPLES
do
    echo "Submitting sample: $SAMPLE"
    sbatch --job-name="aln_$SAMPLE" "${ALIGNMENT_DIR}/run_alignment.sh" "$SAMPLE"
done
