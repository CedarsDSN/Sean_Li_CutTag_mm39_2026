# 定义路径（请根据你的实际目录微调）
META_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/sf_calculation_Chipseqspikefree/CTK27ac/metaFile"
BAM_LIST_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/sf_calculation_Chipseqspikefree/CTK27ac/bam_list"

echo "开始批量提交 ChIPseqSpikeInFree 任务 (CPS1-12)..."

for i in {1..12}
do
    # 构造文件名
    META="CPS${i}_meta_no_input.txt"
    BAM_LIST="CPS${i}_bam_updated_no_input.txt"
    CPS_ID="CPS${i}_no_input"

    # 检查文件是否存在，防止中途报错
    if [[ -f "$META_DIR/$META" && -f "$BAM_LIST_DIR/$BAM_LIST" ]]; then
        echo "正在提交: $CPS_ID"
        
        sbatch --job-name=SPIKE_$CPS_ID \
               --output=${CPS_ID}_run.log \
               ./Chipseqspikefree.sh $META $BAM_LIST $CPS_ID
    else
        echo "[跳过] $CPS_ID: 找不到指定的 meta 或 bam_list 文件。"
    fi
done

echo "所有任务已尝试提交，请使用 'squeue -u wangyiz' 查看进度。"
