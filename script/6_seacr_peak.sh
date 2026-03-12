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

# 环境配置
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

# 路径定义
bg_dir="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/seacr_bedgraph"
out_dir="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/seacr_stringent_001"
seacr_exec="/common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env/bin/SEACR_1.3.sh"

mkdir -p $out_dir

# 1. 获取所有的 BedGraph 文件列表 (排除 IgG 和 nAb 对照样本，避免浪费算力)
BG_LIST=($(find "$bg_dir" -maxdepth 1 -name "*.seacr.bedgraph" | grep -viE "IgG|nAb" | sort))

if [ ${#BG_LIST[@]} -eq 0 ]; then
    echo "ERROR: No valid bedgraph files found."
    exit 1
fi

# 2. 数组越界保护 (防止 Array ID 大于实际文件数量)
if [ "$SLURM_ARRAY_TASK_ID" -gt "${#BG_LIST[@]}" ]; then
    echo "Task ID $SLURM_ARRAY_TASK_ID exceeds file list size. Exiting safely."
    exit 0
fi

# 3. 根据任务索引获取当前文件
current_bg=${BG_LIST[$((SLURM_ARRAY_TASK_ID-1))]}
# 干净地剥离后缀，保留样本核心名字
base_name=$(basename "$current_bg" .rmdup.seacr.bedgraph)

# 定义输出前缀
output_prefix="${out_dir}/${base_name}.01"

echo "Task ID: $SLURM_ARRAY_TASK_ID"
echo "Peak Calling: $base_name"

# 4. 运行 SEACR
# 参数解释:
# $current_bg: 输入的、符合 SEACR 要求的全片段 BedGraph
# 0.01: 阈值 (提取 Top 1% 经验分布背景)
# non: 不使用 IgG 做 Control，直接依据 0.01 阈值截断
# stringent: 严格模式
bash $seacr_exec \
    $current_bg \
    0.01 \
    non \
    stringent \
    $output_prefix

echo "$base_name Peak Calling Done."
