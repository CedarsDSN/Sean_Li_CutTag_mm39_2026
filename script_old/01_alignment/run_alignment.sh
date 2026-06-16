#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH -p defq
#SBATCH -t 80:00:00
#SBATCH --mem=64GB
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=yizhou.wang@cshs.org
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/%x_%j.log

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools

mkdir -p "$BAM_DIR"

SAMPLE_ID="${1:-}"

if [[ -z "$SAMPLE_ID" ]]; then
    echo "ERROR: SAMPLE_ID is required."
    echo "Usage: bash alignment.sh <SAMPLE_ID>"
    exit 1
fi

R1="${FASTQ_DIR}/${SAMPLE_ID}_R1.fastq.gz"
R2="${FASTQ_DIR}/${SAMPLE_ID}_R2.fastq.gz"
BAM_OUT="${BAM_DIR}/${SAMPLE_ID}.coordsorted.bam"
LOG_OUT="${BAM_DIR}/${SAMPLE_ID}_bowtie2.log"

if [[ ! -f "$R1" ]]; then
    echo "ERROR: R1 FASTQ not found: $R1"
    exit 1
fi

if [[ ! -f "$R2" ]]; then
    echo "ERROR: R2 FASTQ not found: $R2"
    exit 1
fi

bowtie2 \
    --dovetail \
    --very-sensitive-local \
    -p 10 \
    --no-unal \
    --no-mixed \
    --no-discordant \
    --phred33 \
    -I 10 \
    -X 700 \
    -x "$GENOME_REF" \
    -1 "$R1" \
    -2 "$R2" \
    2> "$LOG_OUT" | \
samtools sort -@ 4 -o "$BAM_OUT" -

samtools index "$BAM_OUT"

