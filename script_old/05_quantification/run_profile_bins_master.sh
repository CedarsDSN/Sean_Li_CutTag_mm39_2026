#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 04:00:00
#SBATCH --mem=32GB
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/manorm2_counts_%A_%a.log

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

CSV_FILE="${METADATA_CURRENT}"
BED_DIR="${PROJECT_ROOT}/bam_to_bed"
PEAK_DIR="${PROJECT_ROOT}/consensus_peaks"
OUT_DIR="${PROJECT_ROOT}/manorm2_master_counts"
RAW_PEAK_DIR="${PROJECT_ROOT}/seacr_peak_calling"

mkdir -p "$OUT_DIR"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "ERROR: Metadata file not found: $CSV_FILE"
    exit 1
fi

# Build ordered unique CPS list from metadata
mapfile -t CPS_LIST < <(tail -n +2 "$CSV_FILE" | cut -d, -f1 | sort -u)

if [[ ${#CPS_LIST[@]} -eq 0 ]]; then
    echo "ERROR: No CPS IDs found in metadata."
    exit 1
fi

TASK_ID="${SLURM_ARRAY_TASK_ID:-}"

if [[ -z "$TASK_ID" ]]; then
    echo "ERROR: SLURM_ARRAY_TASK_ID is not set."
    echo "This script is intended to be run via sbatch array."
    exit 1
fi

if [[ "$TASK_ID" -gt "${#CPS_LIST[@]}" ]]; then
    echo "Task ID $TASK_ID exceeds CPS list size ${#CPS_LIST[@]}. Exiting safely."
    exit 0
fi

CPS="${CPS_LIST[$((TASK_ID-1))]}"

echo "=================================================="
echo "Task ID: $TASK_ID"
echo "Processing CPS: $CPS"
echo "=================================================="

marker=$(grep "^${CPS}," "$CSV_FILE" | head -n 1 | awk -F',' '{print $5}' | tr -d '\r' | xargs)

if [[ -z "$marker" ]]; then
    echo "ERROR: Could not determine marker for CPS: $CPS"
    exit 1
fi

CONSENSUS_PEAK="${PEAK_DIR}/${CPS}_consensus.bed"

if [[ ! -f "$CONSENSUS_PEAK" ]]; then
    echo "ERROR: Consensus peak file not found: $CONSENSUS_PEAK"
    exit 1
fi

declare -a all_reads
declare -a all_labs
declare -a all_peaks

# Collect all samples participating in this CPS
SAMPLES=$(grep "^${CPS}," "$CSV_FILE" | awk -F',' '{print $3,$4}' | tr ';' '\n' | tr ' ' '\n' | tr -d '\r' | sed '/^$/d' | sort -u)

for sname in $SAMPLES; do
    READ_FILES=$(ls "${BED_DIR}"/${sname}*${marker}*.bed 2>/dev/null | grep -viE "IgG|nAb|CTnAb" || true)

    if [[ -z "$READ_FILES" ]]; then
        echo "[WARNING] No paired BED found for sample: $sname with marker: $marker"
        continue
    fi

    for f in $READ_FILES; do
        lab_name=$(basename "$f" | sed 's/\.bed$//')
        # Must match current maintained SEACR naming
        raw_p="${RAW_PEAK_DIR}/${lab_name}.${SEACR_THRESHOLD}.stringent.bed"

        if [[ -f "$raw_p" ]]; then
            all_reads+=("$f")
            all_peaks+=("$raw_p")

            lab_name_clean=$(echo "$lab_name" | sed 's/-/_/g')
            all_labs+=("$lab_name_clean")
        else
            echo "[WARNING] Raw peak not found for $lab_name: $raw_p"
        fi
    done
done

if [[ ${#all_reads[@]} -eq 0 ]]; then
    echo "ERROR: No valid read/peak pairs collected for CPS: $CPS"
    exit 1
fi

READ_ARG=$(IFS=,; echo "${all_reads[*]}")
LAB_ARG=$(IFS=,; echo "${all_labs[*]}")
PEAK_ARG=$(IFS=,; echo "${all_peaks[*]}")

echo "Marker: $marker"
echo "Consensus peak: $CONSENSUS_PEAK"
echo "Number of read files: ${#all_reads[@]}"
echo "Output prefix: ${OUT_DIR}/${CPS}_master_counts"

profile_bins \
    --bins="$CONSENSUS_PEAK" \
    --paired \
    --peaks="$PEAK_ARG" \
    --reads="$READ_ARG" \
    --labs="$LAB_ARG" \
    -n "${OUT_DIR}/${CPS}_master_counts"

echo "CPS $CPS profile_bins completed successfully."
