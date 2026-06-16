#!/bin/bash
#SBATCH --job-name=edgeR_CTK4me1
#SBATCH --time=24:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -p defq
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/logs/edgeR_CTK4me1_%A_%a.log
#SBATCH -e /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/logs/edgeR_CTK4me1_%A_%a.err

set -eo pipefail

PROJECT_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39
RSCRIPT_FILE="${PROJECT_ROOT}/script/05_differential_analysis/CTK4me1/run_edgeR_one_comparison_CTK4me1.R"

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

if [[ ! -f "$RSCRIPT_FILE" ]]; then
    echo "ERROR: R script not found: $RSCRIPT_FILE"
    exit 1
fi

TASK_ID="${SLURM_ARRAY_TASK_ID:-}"
if [[ -z "$TASK_ID" ]]; then
    echo "ERROR: SLURM_ARRAY_TASK_ID is not set."
    exit 1
fi

echo "=================================================="
echo "Job started: $(date)"
echo "Host: $(hostname)"
echo "Task ID: ${TASK_ID}"
echo "R script: ${RSCRIPT_FILE}"
echo "=================================================="

Rscript "$RSCRIPT_FILE" "$TASK_ID"

echo "=================================================="
echo "Job finished: $(date)"
echo "Task ID: ${TASK_ID}"
echo "=================================================="
