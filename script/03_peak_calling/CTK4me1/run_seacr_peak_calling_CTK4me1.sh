#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 12:00:00
#SBATCH --mem=20GB
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=yizhou.wang@cshs.org
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/logs/seacr_CTK4me1_%A_%a.log

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

BG_DIR="${PROJECT_ROOT}/seacr_bedgraph/CTK4me1"
OUT_DIR="${PROJECT_ROOT}/seacr_peak_calling/CTK4me1"
SEACR_EXEC="/common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env/bin/SEACR_1.3.sh"

mkdir -p "$OUT_DIR"

if [[ -z "${SEACR_THRESHOLD:-}" ]]; then
    echo "ERROR: SEACR_THRESHOLD is not set in project_config.sh"
    exit 1
fi

if [[ -z "${SEACR_MODE:-}" ]]; then
    echo "ERROR: SEACR_MODE is not set in project_config.sh"
    exit 1
fi

if [[ ! -d "$BG_DIR" ]]; then
    echo "ERROR: BG_DIR does not exist: $BG_DIR"
    exit 1
fi

if [[ ! -f "$SEACR_EXEC" ]]; then
    echo "ERROR: SEACR executable not found: $SEACR_EXEC"
    exit 1
fi

mapfile -t BG_LIST < <(find "$BG_DIR" -maxdepth 1 -name "*.seacr.bedgraph" | grep -viE "IgG|nAb" | sort)

if [[ ${#BG_LIST[@]} -eq 0 ]]; then
    echo "ERROR: No valid bedGraph files found in $BG_DIR"
    exit 1
fi

TASK_ID="${SLURM_ARRAY_TASK_ID:-}"
if [[ -z "$TASK_ID" ]]; then
    echo "ERROR: SLURM_ARRAY_TASK_ID is not set"
    exit 1
fi

if [[ "$TASK_ID" -gt "${#BG_LIST[@]}" ]]; then
    echo "Task ID ${TASK_ID} exceeds file list size. Exiting safely."
    exit 0
fi

CURRENT_BG="${BG_LIST[$((TASK_ID-1))]}"

# remove both .rmdup and .seacr.bedgraph
BASE_NAME=$(basename "$CURRENT_BG" .rmdup.seacr.bedgraph)

OUTPUT_PREFIX="${OUT_DIR}/${BASE_NAME}.${SEACR_THRESHOLD}"

echo "Task ID: ${TASK_ID}"
echo "Peak calling: $BASE_NAME"
echo "Input bedGraph: $CURRENT_BG"
echo "Output prefix: $OUTPUT_PREFIX"
echo "SEACR threshold: ${SEACR_THRESHOLD}"
echo "SEACR mode: ${SEACR_MODE}"

bash "$SEACR_EXEC" \
    "$CURRENT_BG" \
    "$SEACR_THRESHOLD" \
    non \
    "$SEACR_MODE" \
    "$OUTPUT_PREFIX"

echo "$BASE_NAME peak calling done."
