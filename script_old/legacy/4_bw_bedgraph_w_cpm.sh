#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH -p defq
#SBATCH -t 80:00:00
#SBATCH --mem=150GB
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=yizhou.wang@cshs.org
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/%x_%j.log
#SBATCH --array=1-249

source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools

bam_dir="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam"
blacklist="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/reference/mm39.excluderanges.bed"
out_root="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bw_bedgraph_cpm"

mkdir -p $out_root

BAM_LIST=($(ls ${bam_dir}/*.rmdup.bam))

# 2. 根据当前的子任务索引 ($SLURM_ARRAY_TASK_ID) 获取对应的 BAM 文件
# 注意：数组索引从 0 开始，所以要减 1
current_bam=${BAM_LIST[$((SLURM_ARRAY_TASK_ID-1))]}
base_name=$(basename "$current_bam")
output_bg="${out_root}/${base_name%.bam}.cpm.bedGraph"

echo "Taks ID: $SLURM_ARRAY_TASK_ID"
echo "processing: $base_name"


bamCoverage \
    --bam "$current_bam" \
    --outFileName "$output_bg" \
    --outFileFormat bigwig \
    --normalizeUsing CPM \
    --binSize 10 \
    --extendReads \
    --ignoreForNormalization chrM \
    --blackListFileName "$blacklist" \
    --numberOfProcessors 8 \
    --minMappingQuality 10

echo "sample $base_name done"


