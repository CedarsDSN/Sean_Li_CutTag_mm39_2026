#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 12:00:00
#SBATCH --mem=40GB
#SBATCH --array=1-250%50
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/seacr_bg_%A_%a.log

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools

OUT_DIR="${PROJECT_ROOT}/seacr_bedgraph"
CHROMSIZES="/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/GRCm39.chrom.sizes"

mkdir -p "$OUT_DIR"

# Collect all rmdup BAMs. Control libraries may also be converted here if desired
# for QC/reference purposes. Formal target peak calling is performed later in
# control-free SEACR mode.
BAM_LIST=($(find "$BAM_DIR" -maxdepth 1 -name "*rmdup*.bam" | sort))

if [[ ${#BAM_LIST[@]} -eq 0 ]]; then
    echo "ERROR: No valid BAM files found in $BAM_DIR"
    exit 1
fi

if [[ "${SLURM_ARRAY_TASK_ID}" -gt "${#BAM_LIST[@]}" ]]; then
    echo "Task ID ${SLURM_ARRAY_TASK_ID} exceeds BAM list size. Exiting."
    exit 0
fi

CURRENT_BAM="${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}"
BASE_NAME=$(basename "$CURRENT_BAM" .bam)

TMP_BAM="${OUT_DIR}/${BASE_NAME}.name_sorted.bam"
BEDPE_FILE="${OUT_DIR}/${BASE_NAME}.bedpe"
CLEAN_BEDPE="${OUT_DIR}/${BASE_NAME}.clean.bedpe"
FRAG_BED="${OUT_DIR}/${BASE_NAME}.fragments.bed"
OUT_BG="${OUT_DIR}/${BASE_NAME}.seacr.bedgraph"

echo "=================================================="
echo "Starting SEACR bedGraph generation for: $BASE_NAME"
echo "=================================================="

echo "1. Sorting BAM by read name..."
samtools sort -n -@ 4 -o "$TMP_BAM" "$CURRENT_BAM"

echo "2. Converting to BEDPE..."
bedtools bamtobed -bedpe -i "$TMP_BAM" > "$BEDPE_FILE"

echo "3. Filtering fragments and creating fragment BED..."
awk -v max_frag="$FRAG_MAX" '$1==$4 && $6>$2 && ($6-$2)<max_frag {print $0}' "$BEDPE_FILE" > "$CLEAN_BEDPE"

cut -f 1,2,6 "$CLEAN_BEDPE" | sort -k1,1 -k2,2n -k3,3n > "$FRAG_BED"

echo "4. Generating final bedGraph with genomecov..."
bedtools genomecov -bg -i "$FRAG_BED" -g "$CHROMSIZES" > "$OUT_BG"

echo "5. Cleaning intermediate files..."
rm -f "$TMP_BAM" "$BEDPE_FILE" "$CLEAN_BEDPE" "$FRAG_BED"

echo "Finished processing $BASE_NAME successfully."
echo "Output saved to: $OUT_BG"
