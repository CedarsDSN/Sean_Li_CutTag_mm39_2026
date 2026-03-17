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


# 接收命令行参数，例如：sbatch generate_bw.sh CPS1
CPS_ID=$1

# 环境配置
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools

# 路径定义
bam_dir="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam"
sf_results_root="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/sf_calculation_Chipseqspikefree/CTK27ac/sf_results"
blacklist="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/reference/mm39.excluderanges.bed"
out_root="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bigWig_outputs"

mkdir -p ${out_root}/${CPS_ID}

sf_file="${sf_results_root}/${CPS_ID}_no_input/${CPS_ID}_no_input_SF.txt"

if [[ ! -f "$sf_file" ]]; then
    echo "错误: 找不到文件 $sf_file"
    exit 1
fi


echo "正在处理组别: ${CPS_ID}"
echo "读取 SF 文件: ${sf_file}"

# 读取 SF 文件，跳过第一行表头
sed 1d "$sf_file" | while read -r line; do
    # 提取 ID (第一列) 和 SF (第七列)
    BAM_NAME=$(echo "$line" | awk '{print $1}')
    SF_VAL=$(echo "$line" | awk '{print $7}')

    # 获取该 BAM 去重后的比对 reads 总数
    # idxstats 输出：染色体名 长度 比对数 未比对数
    total_mapped=$(samtools idxstats "${bam_dir}/${BAM_NAME}" | grep -vE 'chrM|MT' | awk '{s+=$3} END {print s}')
    # 计算综合 Scale Factor: (SF * 1,000,000) / total_mapped
    # 这使得结果既经过了背景校正，又具备了 CPM 的物理含义
    final_scale=$(awk "BEGIN {print 15000000 / ($total_mapped * $SF_VAL)}")
    echo "样本: $BAM_NAME | SF: $SF_VAL | Total Reads: $total_mapped | Final Scale: $final_scale"

    output_bw="${out_root}/${CPS_ID}/${BAM_NAME%.bam}.${CPS_ID}.sf.bw"
    output_bg="${out_root}/${CPS_ID}/${BAM_NAME%.bam}.${CPS_ID}.sf.bedGraph"

# 1. 生成 BigWig (用于 IGV 快速查看)
    bamCoverage \
    --bam "${bam_dir}/${BAM_NAME}" \
    --outFileName "${output_bw}" \
    --outFileFormat bigwig \
    --scaleFactor "${final_scale}" \
    --blackListFileName "${blacklist}" \
    --binSize 10 \
    --extendReads \
    --ignoreForNormalization chrM \
    --numberOfProcessors 10 \
    --normalizeUsing None

# 2. 生成 BedGraph (用于 bedtools 运算或差异分析)
    bamCoverage \
    --bam "${bam_dir}/${BAM_NAME}" \
    --outFileName "${output_bg}" \
    --outFileFormat bedgraph \
    --scaleFactor "${final_scale}" \
    --blackListFileName "${blacklist}" \
    --binSize 10 \
    --extendReads \
    --ignoreForNormalization chrM \
    --numberOfProcessors 10 \
    --normalizeUsing None
done

echo "${CPS_ID} 所有 BigWig 生成完毕。"



