#!/bin/bash
#SBATCH --job-name=manorm2_counts
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 04:00:00           # 预计每条命令 1-2 小时，给 4 小时足够了
#SBATCH --mem=32GB            # profile_bins 比较吃内存，32G 比较稳
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/manorm2_counts_%A_%a.log

# 环境设置
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

# --- 核心逻辑 ---
# 指定你的任务清单文件
TASK_FILE="profile_bin_CPS13.sh"

# 根据当前的 Array ID 提取对应的行
# sed -n 'Np' 表示提取第 N 行
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$TASK_FILE")

echo "Executing Task ID: $SLURM_ARRAY_TASK_ID"
echo "Command: $LINE"

# 执行该命令
eval "$LINE"

echo "Task $SLURM_ARRAY_TASK_ID completed successfully."
