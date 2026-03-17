#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 12:00:00
#SBATCH --mem=40GB
#SBATCH --array=1-249%50
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/b2b_paired_%A_%a.log

# Environment
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools

# --- Path Definitions ---
BAM_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam"
OUT_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam_to_bed"
mkdir -p "$OUT_DIR"

# 1. 收集 BAM，排除 IgG / nAb
BAM_LIST=($(find "$BAM_DIR" -maxdepth 1 -name "*rmdup*.bam" | grep -viE "IgG|nAb" | sort))

if [ ${#BAM_LIST[@]} -eq 0 ]; then
    echo "ERROR: No valid BAM files found."
    exit 1
fi

# 2. 当前任务文件
if [ "$SLURM_ARRAY_TASK_ID" -gt "${#BAM_LIST[@]}" ]; then
    echo "Task ID $SLURM_ARRAY_TASK_ID exceeds BAM list size. Exiting."
    exit 0
fi

CURRENT_BAM="${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}"
BASE_NAME=$(basename "$CURRENT_BAM" .bam)

TMP_BAM="${OUT_DIR}/${BASE_NAME}.tmp.name.bam"
FILTERED_BAM="${OUT_DIR}/${BASE_NAME}.tmp.filtered.bam"
OUT_BED="${OUT_DIR}/${BASE_NAME}.bed"

echo "Processing paired-end sample: $BASE_NAME"

# 3. 按 read name 排序
samtools sort -n -@ 4 -o "$TMP_BAM" "$CURRENT_BAM"

# 4. 过滤为更标准的 paired-end 主比对 (无需二次排序，view 会完美继承 name-sorted 顺序)
# -f 0x2    : proper pair
# -F 0x904  : 去掉 unmapped(0x4), secondary(0x100), supplementary(0x800)
samtools view -@ 4 -bh -f 0x2 -F 0x904 "$TMP_BAM" > "$FILTERED_BAM"

# 5. 转成标准 BED
bedtools bamtobed -i "$FILTERED_BAM" > "$OUT_BED.raw"

# 6. 保留标准 6 列 BED，并智能剥离 bedtools 添加的 /1 和 /2
awk 'BEGIN{OFS="\t"}
{
    # 取出第 4 列的名字，并用 sub 替换掉结尾的 /1 或 /2
    curr_name = $4
    sub("/[12]$", "", curr_name)
    curr_chr = $1

    # 如果当前行的处理后名字和染色体，等于上一行，说明找到了完美的 pair
    if (curr_name == prev_name && curr_chr == prev_chr) {
        # 为了让 MAnorm2 识别，输出时把名字强制统一 (去除了 /1 /2 的版本)
        $4 = curr_name
        
        # 顺便把上一行的名字也统一替换掉再输出
        split(prev_line, p_arr, "\t")
        p_arr[4] = curr_name
        print p_arr[1], p_arr[2], p_arr[3], p_arr[4], p_arr[5], p_arr[6]
        
        print $0
        
        # 配对成功后清空记录，防止出现 3 条同名 read 的极端情况
        prev_name = ""
    } else {
        # 如果不匹配，把当前行作为新的“待匹配”记录存下来
        prev_line = $0
        prev_name = curr_name
        prev_chr = curr_chr
    }
}' "$OUT_BED.raw" > "$OUT_BED"

# 7. 清理中间文件
rm -f "$TMP_BAM" "$FILTERED_BAM" "$OUT_BED.raw"

echo "Successfully converted $BASE_NAME to paired-end BED for profile_bins --paired."
