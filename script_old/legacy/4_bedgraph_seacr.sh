#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 12:00:00
#SBATCH --mem=40GB
#SBATCH --array=1-250%50
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/seacr_bg_%A_%a.log

# Environment
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools

# --- Path Definitions ---
BAM_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam"
OUT_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/seacr_bedgraph"

# ！！！极其重要：你需要一个 mm39 染色体长度文件 ！！！
# 如果你没有这个文件，可以在跑这个脚本前在终端运行下面这行命令生成一个：
# fetchChromSizes mm39 > /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/mm39.chrom.sizes
CHROMSIZES="/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/GRCm39.chrom.sizes"

mkdir -p "$OUT_DIR"

# 1. 收集 BAM (这次不能排除 IgG，因为 SEACR 必须用 IgG)
BAM_LIST=($(find "$BAM_DIR" -maxdepth 1 -name "*rmdup*.bam" | sort))

if [ ${#BAM_LIST[@]} -eq 0 ]; then
    echo "ERROR: No valid BAM files found."
    exit 1
fi

if [ "$SLURM_ARRAY_TASK_ID" -gt "${#BAM_LIST[@]}" ]; then
    echo "Task ID $SLURM_ARRAY_TASK_ID exceeds BAM list size. Exiting."
    exit 0
fi

CURRENT_BAM="${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}"
BASE_NAME=$(basename "$CURRENT_BAM" .bam)

# 定义中间文件与输出文件
TMP_BAM="${OUT_DIR}/${BASE_NAME}.name_sorted.bam"
BEDPE_FILE="${OUT_DIR}/${BASE_NAME}.bedpe"
CLEAN_BEDPE="${OUT_DIR}/${BASE_NAME}.clean.bedpe"
FRAG_BED="${OUT_DIR}/${BASE_NAME}.fragments.bed"
OUT_BG="${OUT_DIR}/${BASE_NAME}.seacr.bedgraph"

echo "=================================================="
echo "Starting SEACR bedgraph generation for: $BASE_NAME"
echo "=================================================="

# 步骤 1: Name-sort BAM (bedtools -bedpe 的必须前提)
echo "1. Sorting BAM by read name..."
samtools sort -n -@ 4 -o "$TMP_BAM" "$CURRENT_BAM"

# 步骤 2: 提取配对的 BEDPE 格式
echo "2. Converting to BEDPE..."
bedtools bamtobed -bedpe -i "$TMP_BAM" > "$BEDPE_FILE"

# 步骤 3 & 4 & 5: 完全复刻 SEACR 官方 Tutorial 的三步走逻辑
echo "3. Filtering fragments < 1000bp and creating unified fragment BED..."
awk '$1==$4 && $6-$2 < 1000 {print $0}' "$BEDPE_FILE" > "$CLEAN_BEDPE"

# 提取 chr(1), start(2), end(6) 并按坐标排序
cut -f 1,2,6 "$CLEAN_BEDPE" | sort -k1,1 -k2,2n -k3,3n > "$FRAG_BED"

# 生成最终的 BedGraph
echo "4. Generating final BedGraph using genomecov..."
bedtools genomecov -bg -i "$FRAG_BED" -g "$CHROMSIZES" > "$OUT_BG"

# 步骤 6: 空间清理 (只保留最终的 .bedgraph，其余几 GB 的中间文件全部删掉)
echo "5. Cleaning up massive intermediate files..."
rm -f "$TMP_BAM" "$BEDPE_FILE" "$CLEAN_BEDPE" "$FRAG_BED"

echo "Finished processing $BASE_NAME successfully!"
echo "Output saved to: $OUT_BG"
