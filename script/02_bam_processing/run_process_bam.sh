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

QC_DIR="${PROJECT_ROOT}/qc"

mkdir -p "$QC_DIR"

SAMPLE_ID="${1:-}"

if [[ -z "$SAMPLE_ID" ]]; then
    echo "ERROR: SAMPLE_ID is required."
    echo "Usage: bash run_process_bam.sh <SAMPLE_ID>"
    exit 1
fi

INPUT_BAM="${BAM_DIR}/${SAMPLE_ID}.coordsorted.bam"
FILTER_BAM="${BAM_DIR}/${SAMPLE_ID}.filter.bam"
RMDUP_BAM="${BAM_DIR}/${SAMPLE_ID}.rmdup.bam"
METRICS_FILE="${QC_DIR}/${SAMPLE_ID}.rmDups.metrics.txt"
FLAGSTAT_FILE="${QC_DIR}/${SAMPLE_ID}.rmdup.stats"

if [[ ! -f "$INPUT_BAM" ]]; then
    echo "ERROR: Input BAM not found: $INPUT_BAM"
    exit 1
fi

CHRS=$(samtools view -H "$INPUT_BAM" | grep "^@SQ" | cut -f2 | sed 's/SN://' | grep -v "chrM")

samtools view -b -f 2 -q "$MAPQ_MIN" "$INPUT_BAM" $CHRS > "$FILTER_BAM"

picard -Xmx48g MarkDuplicates \
    -I "$FILTER_BAM" \
    -O "$RMDUP_BAM" \
    -REMOVE_DUPLICATES true \
    -METRICS_FILE "$METRICS_FILE"

samtools index "$RMDUP_BAM"
samtools flagstat "$RMDUP_BAM" > "$FLAGSTAT_FILE"

rm -f "$FILTER_BAM"
