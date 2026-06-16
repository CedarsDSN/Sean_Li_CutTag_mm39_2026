#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 12:00:00
#SBATCH --mem=40GB
#SBATCH --array=1-249%50
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/b2b_paired_%A_%a.log

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools

OUT_DIR="${PROJECT_ROOT}/bam_to_bed"
mkdir -p "$OUT_DIR"

# =========================================================
# Use blacklist-filtered BAMs from the new pipeline
# Exclude IgG / nAb / CTnAb controls
# =========================================================
mapfile -t BAM_LIST < <(find "$BAM_DIR" -maxdepth 1 -name "*.rmdup.blfilter.bam" \
    | grep -viE "IgG|nAb|CTnAb" \
    | sort)

if [[ ${#BAM_LIST[@]} -eq 0 ]]; then
    echo "ERROR: No valid .rmdup.blfilter.bam files found."
    exit 1
fi

if [[ -z "${SLURM_ARRAY_TASK_ID:-}" ]]; then
    echo "ERROR: SLURM_ARRAY_TASK_ID is not set."
    exit 1
fi

if [[ "${SLURM_ARRAY_TASK_ID}" -gt "${#BAM_LIST[@]}" ]]; then
    echo "Task ID ${SLURM_ARRAY_TASK_ID} exceeds BAM list size. Exiting."
    exit 0
fi

CURRENT_BAM="${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}"
BASE_NAME=$(basename "$CURRENT_BAM" .bam)

TMP_BAM="${OUT_DIR}/${BASE_NAME}.tmp.name.bam"
FILTERED_BAM="${OUT_DIR}/${BASE_NAME}.tmp.filtered.bam"
RAW_BED="${OUT_DIR}/${BASE_NAME}.raw.bed"
OUT_BED_TMP="${OUT_DIR}/${BASE_NAME}.tmp.bed"
OUT_BED="${OUT_DIR}/${BASE_NAME}.bed"

echo "Processing paired-end sample: $BASE_NAME"
echo "Input BAM: $CURRENT_BAM"
echo "Output BED: $OUT_BED"

# =========================================================
# Sort by read name for paired-end conversion
# =========================================================
samtools sort -n -@ 4 -o "$TMP_BAM" "$CURRENT_BAM"

# Keep proper pairs; remove unmapped/secondary/supplementary/duplicate flags if any remain
samtools view -@ 4 -bh -f 0x2 -F 0x904 "$TMP_BAM" > "$FILTERED_BAM"

# Convert BAM to BED6, one line per read end
bedtools bamtobed -i "$FILTERED_BAM" > "$RAW_BED"

# =========================================================
# Reconstruct proper paired BED records
# Output remains two consecutive BED lines per read pair,
# suitable for profile_bins --paired
# =========================================================
awk 'BEGIN{OFS="\t"}
{
    curr_name = $4
    sub("/[12]$", "", curr_name)
    curr_chr = $1

    if (curr_name == prev_name && curr_chr == prev_chr) {
        $4 = curr_name

        split(prev_line, p_arr, "\t")
        p_arr[4] = curr_name

        print p_arr[1], p_arr[2], p_arr[3], p_arr[4], p_arr[5], p_arr[6]
        print $0

        prev_name = ""
        prev_chr = ""
        prev_line = ""
    } else {
        prev_line = $0
        prev_name = curr_name
        prev_chr = curr_chr
    }
}' "$RAW_BED" > "$OUT_BED_TMP"

# =========================================================
# Keep only complete pairs
# =========================================================
awk 'BEGIN{OFS="\t"}
{
    curr_name = $4
    curr_chr = $1

    if (curr_name == prev_name && curr_chr == prev_chr) {
        print prev_line
        print $0
        prev_name = ""
        prev_chr = ""
        prev_line = ""
    } else {
        prev_line = $0
        prev_name = curr_name
        prev_chr = curr_chr
    }
}' "$OUT_BED_TMP" > "$OUT_BED"

rm -f "$TMP_BAM" "$FILTERED_BAM" "$RAW_BED" "$OUT_BED_TMP"

echo "Successfully converted $BASE_NAME to paired-end BED for profile_bins --paired."
