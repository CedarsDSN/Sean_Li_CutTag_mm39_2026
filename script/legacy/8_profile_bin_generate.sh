#!/bin/bash

# --- 1. 路径定义 ---
#CSV_FILE="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/Metadata_CTK27ac_Comparison.csv"
#CSV_FILE="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/Metadata_CTK4me1_Comparison.csv"
CSV_FILE="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/Metadata_CTK27ac_CPS13.csv"
BED_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam_to_bed"
PEAK_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/consensus_peaks"
OUT_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/manorm2_master_counts"
RAW_PEAK_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/seacr_stringent_001"

mkdir -p $OUT_DIR

# --- 2. 核心逻辑：利用关联数组按 CPS 收集并去重样本 ---
declare -A cps_samples
declare -A cps_marker

# 提取并汇总所有样本
while IFS=, read -r CPS comp group1 group2 marker; do
    CPS=$(echo "$CPS" | xargs)
    marker=$(echo "$marker" | xargs)
    group1=$(echo "$group1" | xargs)
    group2=$(echo "$group2" | xargs)

    # 把分号替换为空格，并将该行的样本追加到对应的 CPS 集合中
    G1_SAMPLES=$(echo "$group1" | tr ';' ' ')
    G2_SAMPLES=$(echo "$group2" | tr ';' ' ')

    cps_samples["$CPS"]="${cps_samples["$CPS"]} $G1_SAMPLES $G2_SAMPLES"
    cps_marker["$CPS"]="$marker"
done < <(tail -n +2 "$CSV_FILE")

# --- 3. 遍历每个唯一的 CPS，生成专属命令行 ---
for CPS in "${!cps_samples[@]}"; do
    marker="${cps_marker[$CPS]}"

    # 这里的 CONSENSUS_PEAK 就是你要 count 的目标区域
    CONSENSUS_PEAK="${PEAK_DIR}/${CPS}_consensus.bed"

    all_reads=()
    all_labs=()
    all_peaks=()

    # 对该 CPS 下收集到的所有样本进行极其严格的【去重】
    UNIQUE_SAMPLES=$(echo "${cps_samples[$CPS]}" | tr ' ' '\n' | grep -v '^$' | sort -u)

    for sname in $UNIQUE_SAMPLES; do
        # 匹配 Paired-end BED 文件
        READ_FILES=$(ls ${BED_DIR}/${sname}*${marker}*.bed 2>/dev/null | grep -viE "IgG|nAb")

        for f in $READ_FILES; do
            # 提取 Label: 假设文件名为 Uro-xxf-CTK27ac-1.rmdup.bed
            lab_name=$(basename "$f" | sed 's/\.rmdup\.bed//')
            # 如果你的成对 BED 没有 .rmdup，只需要 .bed 结尾，可以用下面这行代替上面那行：
            # lab_name=$(basename "$f" | sed 's/\.bed//')

            # 匹配该样本对应的 SEACR 原始 Peak 文件 (用于生成 0/1 Occupancy 状态)
            raw_p="${RAW_PEAK_DIR}/${lab_name}.rmdup.01.stringent.bed"

            if [ -f "$raw_p" ]; then
                all_reads+=("$f")

                # 将横杠替换成下划线，保证 R 语言读取列名时极其清爽
                lab_name=$(echo "$lab_name" | sed 's/-/_/g')
                all_labs+=("$lab_name")

                all_peaks+=("$raw_p")
            else
                # 打印到 stderr，不污染标准输出的命令行
                echo "### [ERROR] Raw peak not found for $lab_name: $raw_p" >&2
            fi
        done
    done

    if [ ${#all_reads[@]} -eq 0 ]; then
        echo "### [SKIP] No valid files found for CPS: $CPS" >&2
        continue
    fi

    # 构造逗号分隔的参数
    READ_ARG=$(IFS=,; echo "${all_reads[*]}")
    LAB_ARG=$(IFS=,; echo "${all_labs[*]}")
    PEAK_ARG=$(IFS=,; echo "${all_peaks[*]}")

    # --- 4. 打印最终命令 ---
    # 🌟 核心修改：加回了 --bins=$CONSENSUS_PEAK，配合 --paired 发挥最强威力 🌟
    echo "profile_bins --bins=$CONSENSUS_PEAK --paired --peaks=$PEAK_ARG --reads=$READ_ARG --labs=$LAB_ARG -n ${OUT_DIR}/${CPS}_master_counts"

done
