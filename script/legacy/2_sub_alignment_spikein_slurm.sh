#!/bin/bash

FASTQ_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/trim_fastqs"
##FASTQ_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/trim_fastqs/batch1"
SCRIPT_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/scripts" # 假设你的 alignment.sh 在这

SAMPLES=$(ls $FASTQ_DIR/*_R1.fastq.gz | xargs -n 1 basename | sed 's/_R1.fastq.gz//')

for SAMPLE in $SAMPLES
do
    echo "Submitting sample: $SAMPLE"
    
    sbatch --job-name="aln_$SAMPLE" ./alignment_spike.sh $SAMPLE
done
