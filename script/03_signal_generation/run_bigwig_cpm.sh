#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH -p defq
#SBATCH -t 80:00:00
#SBATCH --mem=150GB
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=yizhou.wang@cshs.org
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/%x_%j.log
#SBATCH --array=1-249

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools

OUT_DIR="${PROJECT_ROOT}/bw_bedgraph_cpm"

mkdir -p "$OUT_DIR"

BAM_LIST=($(find "$BAM_DIR" -maxdepth 1 -name "*.rmdup.bam" | sort))

if [[ ${#BAM_LIST[@]} -eq 0 ]]; then
    echo "ERROR: No rmdup BAM files found in $BAM_DIR"
    exit 1
fi

if [[ "${SLURM_ARRAY_TASK_ID}" -gt "${#BAM_LIST[@]}" ]]; then
    echo "Task ID ${SLURM_ARRAY_TASK_ID} exceeds BAM list size. Exiting."
    exit 0
fi

CURRENT_BAM="${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}"
BASE_NAME=$(basename "$CURRENT_BAM")
OUTPUT_BW="${OUT_DIR}/${BASE_NAME%.bam}.cpm.bw"

echo "Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Processing: $BASE_NAME"

bamCoverage \
    --bam "$CURRENT_BAM" \
    --outFileName "$OUTPUT_BW" \
    --outFileFormat bigwig \
    --normalizeUsing CPM \
    --binSize 10 \
    --extendReads \
    --ignoreForNormalization chrM \
    --blackListFileName "$BLACKLIST_MM39" \
    --numberOfProcessors 8 \
    --minMappingQuality "$MAPQ_MIN"

echo "Sample $BASE_NAME done."
