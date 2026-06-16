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

BAM_LIST=($(find "$BAM_DIR" -maxdepth 1 -name "*rmdup*.bam" | grep -viE "IgG|nAb" | sort))

if [[ ${#BAM_LIST[@]} -eq 0 ]]; then
    echo "ERROR: No valid BAM files found."
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
OUT_BED="${OUT_DIR}/${BASE_NAME}.bed"

echo "Processing paired-end sample: $BASE_NAME"

samtools sort -n -@ 4 -o "$TMP_BAM" "$CURRENT_BAM"

samtools view -@ 4 -bh -f 0x2 -F 0x904 "$TMP_BAM" > "$FILTERED_BAM"

bedtools bamtobed -i "$FILTERED_BAM" > "${OUT_BED}.raw"

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
    } else {
        prev_line = $0
        prev_name = curr_name
        prev_chr = curr_chr
    }
}' "${OUT_BED}.raw" > "$OUT_BED"

rm -f "$TMP_BAM" "$FILTERED_BAM" "${OUT_BED}.raw"

echo "Successfully converted $BASE_NAME to paired-end BED for profile_bins --paired."
