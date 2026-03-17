#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 12:00:00
#SBATCH --mem=20GB
#SBATCH --array=1-250%50
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=yizhou.wang@cshs.org
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/seacr_%A_%a.log

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

BG_DIR="${PROJECT_ROOT}/seacr_bedgraph"
OUT_DIR="${PROJECT_ROOT}/seacr_peak_calling"
SEACR_EXEC="/common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env/bin/SEACR_1.3.sh"

mkdir -p "$OUT_DIR"

# Exclude negative-control libraries from the formal target peak-calling loop
BG_LIST=($(find "$BG_DIR" -maxdepth 1 -name "*.seacr.bedgraph" | grep -viE "IgG|nAb" | sort))

if [[ ${#BG_LIST[@]} -eq 0 ]]; then
    echo "ERROR: No valid bedGraph files found in $BG_DIR"
    exit 1
fi

if [[ "${SLURM_ARRAY_TASK_ID}" -gt "${#BG_LIST[@]}" ]]; then
    echo "Task ID ${SLURM_ARRAY_TASK_ID} exceeds file list size. Exiting safely."
    exit 0
fi

CURRENT_BG="${BG_LIST[$((SLURM_ARRAY_TASK_ID-1))]}"
BASE_NAME=$(basename "$CURRENT_BG" .seacr.bedgraph)
OUTPUT_PREFIX="${OUT_DIR}/${BASE_NAME}.${SEACR_THRESHOLD}"

echo "Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Peak calling: $BASE_NAME"

bash "$SEACR_EXEC" \
    "$CURRENT_BG" \
    "$SEACR_THRESHOLD" \
    non \
    "$SEACR_MODE" \
    "$OUTPUT_PREFIX"

echo "$BASE_NAME peak calling done."
