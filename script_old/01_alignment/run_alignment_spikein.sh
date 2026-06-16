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

GENOME_AMP="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/old/Spikein_indices/Amp_pbluescript/Amp_index/Amp_pBlue"
GENOME_ECOLI="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/old/Spikein_indices/EcoliK12_index/EcoliK12Index/EcoliK12"
BAM_SPIKEIN_DIR="${PROJECT_ROOT}/bam_spike"

mkdir -p "$BAM_SPIKEIN_DIR"

SAMPLE_ID="${1:-}"

if [[ -z "$SAMPLE_ID" ]]; then
    echo "ERROR: SAMPLE_ID is required."
    echo "Usage: bash alignment_spike.sh <SAMPLE_ID>"
    exit 1
fi

R1="${FASTQ_DIR}/${SAMPLE_ID}_R1.fastq.gz"
R2="${FASTQ_DIR}/${SAMPLE_ID}_R2.fastq.gz"

AMP_LOG="${BAM_SPIKEIN_DIR}/${SAMPLE_ID}_amp_bowtie2.log"
ECOLI_LOG="${BAM_SPIKEIN_DIR}/${SAMPLE_ID}_ecoli_bowtie2.log"
AMP_BAM="${BAM_SPIKEIN_DIR}/${SAMPLE_ID}.amp.bam"
ECOLI_BAM="${BAM_SPIKEIN_DIR}/${SAMPLE_ID}.ecoli.bam"

if [[ ! -f "$R1" ]]; then
    echo "ERROR: R1 FASTQ not found: $R1"
    exit 1
fi

if [[ ! -f "$R2" ]]; then
    echo "ERROR: R2 FASTQ not found: $R2"
    exit 1
fi

bowtie2 \
    --very-sensitive-local \
    --no-overlap \
    --no-dovetail \
    --no-mixed \
    --no-discordant \
    --phred33 \
    -I 10 \
    -X 700 \
    -x "$GENOME_AMP" \
    -1 "$R1" \
    -2 "$R2" \
    2> "$AMP_LOG" | \
samtools view -bS - > "$AMP_BAM"

bowtie2 \
    --very-sensitive-local \
    --no-overlap \
    --no-dovetail \
    --no-mixed \
    --no-discordant \
    --phred33 \
    -I 10 \
    -X 700 \
    -x "$GENOME_ECOLI" \
    -1 "$R1" \
    -2 "$R2" \
    2> "$ECOLI_LOG" | \
samtools view -bS - > "$ECOLI_BAM"
