#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 08:00:00
#SBATCH --mem=32GB
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/logs/CTK27ac_macs3_callpeak_%A_%a.log

set -eo pipefail

PROJECT_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39
BAM_DIR="${PROJECT_ROOT}/bam"
OUT_DIR="${PROJECT_ROOT}/macs3_peak_calls/CTK27ac"

source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

TASK_ID="${SLURM_ARRAY_TASK_ID:-}"
if [[ -z "$TASK_ID" ]]; then
    echo "ERROR: SLURM_ARRAY_TASK_ID is not set"
    exit 1
fi

BAM_FILE=$(find "$BAM_DIR" -maxdepth 1 -name "*CTK27ac*.rmdup.blfilter.bam" | sort | sed -n "${TASK_ID}p")
if [[ -z "$BAM_FILE" ]]; then
    echo "ERROR: no BAM file found for task ID ${TASK_ID}"
    exit 1
fi

BASE=$(basename "$BAM_FILE")
SAMPLE=${BASE%.rmdup.blfilter.bam}

mkdir -p "${OUT_DIR}/${SAMPLE}"

TMP_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/tmp
TMP_DIR="${TMP_ROOT}/macs3_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
mkdir -p "$TMP_ROOT"
mkdir -p "$TMP_DIR"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cd "$TMP_DIR"

echo "Running MACS3 for sample: ${SAMPLE}"
echo "Input BAM: ${BAM_FILE}"
echo "Output dir: ${OUT_DIR}/${SAMPLE}"
echo "Temp dir: ${TMP_DIR}"

macs3 callpeak \
  -t "$BAM_FILE" \
  -f BAMPE \
  -g 2654621783 \
  -n "$SAMPLE" \
  --outdir "${OUT_DIR}/${SAMPLE}" \
  -q 0.05 \
  --call-summits

echo "Finished: ${SAMPLE}"
