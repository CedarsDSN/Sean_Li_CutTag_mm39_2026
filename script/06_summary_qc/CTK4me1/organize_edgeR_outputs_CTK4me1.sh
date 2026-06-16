#!/bin/bash

set -eo pipefail

PROJECT_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39
SCRIPT_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script

RESULT_DIR="${PROJECT_ROOT}/edgeR_DE_results/CTK4me1"
QUANT_DIR="${PROJECT_ROOT}/quantification/CTK4me1"
MANIFEST_DIR="${QUANT_DIR}/manifests"
PCA_DIR="${PROJECT_ROOT}/PCA_edgeR/CTK4me1"

# --------------------------------------------------
# 1. Aggregate summary / filter / dist in RESULT_DIR
#    and sort by CPS + Comparison_ID
# --------------------------------------------------
cd "$RESULT_DIR" || exit 1

rm -f All_Comparisons_Summary_edgeR.csv All_Filter_Stats_edgeR.csv All_Chromosome_Dist_edgeR.csv

first_summary=$(ls CPS*_Comp*_edgeR_summary.csv 2>/dev/null | head -n 1 || true)
if [[ -n "$first_summary" ]]; then
    head -n 1 "$first_summary" > All_Comparisons_Summary_edgeR.csv
    awk 'FNR>1' CPS*_Comp*_edgeR_summary.csv | sort -t',' -k2,2V -k1,1n >> All_Comparisons_Summary_edgeR.csv
else
    echo "WARNING: No edgeR summary CSV files found."
fi

first_filter=$(ls CPS*_Comp*_edgeR_filter_stats.csv 2>/dev/null | head -n 1 || true)
if [[ -n "$first_filter" ]]; then
    head -n 1 "$first_filter" > All_Filter_Stats_edgeR.csv
    awk 'FNR>1' CPS*_Comp*_edgeR_filter_stats.csv | sort -t',' -k2,2V -k1,1n >> All_Filter_Stats_edgeR.csv
else
    echo "WARNING: No edgeR filter_stats CSV files found."
fi

first_dist=$(ls CPS*_Comp*_edgeR_dist.csv 2>/dev/null | head -n 1 || true)
if [[ -n "$first_dist" ]]; then
    head -n 1 "$first_dist" > All_Chromosome_Dist_edgeR.csv
    awk 'FNR>1' CPS*_Comp*_edgeR_dist.csv | sort -t',' -k5,5V -k4,4n -k1,1V >> All_Chromosome_Dist_edgeR.csv
else
    echo "WARNING: No edgeR chromosome distribution CSV files found."
fi

# --------------------------------------------------
# 2. Organize comparison-level result files by CPS
# --------------------------------------------------
for f in CPS*_Comp*; do
    [[ -e "$f" ]] || continue
    [[ "$f" == All_* ]] && continue
    cps=$(echo "$f" | cut -d'_' -f1)
    mkdir -p "${RESULT_DIR}/${cps}"
    mv "$f" "${RESULT_DIR}/${cps}/"
done

mkdir -p "${RESULT_DIR}/Summary"
[[ -f All_Comparisons_Summary_edgeR.csv ]] && mv All_Comparisons_Summary_edgeR.csv "${RESULT_DIR}/Summary/"
[[ -f All_Filter_Stats_edgeR.csv ]] && mv All_Filter_Stats_edgeR.csv "${RESULT_DIR}/Summary/"
[[ -f All_Chromosome_Dist_edgeR.csv ]] && mv All_Chromosome_Dist_edgeR.csv "${RESULT_DIR}/Summary/"

if [[ -d "${RESULT_DIR}/edgeR_QC_Plots" ]]; then
    mkdir -p "${RESULT_DIR}/Summary/edgeR_QC_Plots"
    shopt -s nullglob
    for f in "${RESULT_DIR}/edgeR_QC_Plots"/*; do
        mv "$f" "${RESULT_DIR}/Summary/edgeR_QC_Plots/"
    done
    rmdir "${RESULT_DIR}/edgeR_QC_Plots" 2>/dev/null || true
fi

# --------------------------------------------------
# 3. Organize quantification matrices by CPS
# --------------------------------------------------
if [[ -d "$QUANT_DIR" ]]; then
    for f in "${QUANT_DIR}"/CPS*_seacr_consensus_profile_bins.xls \
             "${QUANT_DIR}"/CPS*_seacr_consensus_profile_bins_log.txt; do
        [[ -e "$f" ]] || continue
        fname=$(basename "$f")
        cps=$(echo "$fname" | sed -E 's/^(CPS[0-9]+)_seacr_consensus_profile_bins(_log\.txt|\.xls)/\1/')
        mkdir -p "${QUANT_DIR}/${cps}"
        mv "$f" "${QUANT_DIR}/${cps}/"
    done
else
    echo "WARNING: Quantification directory not found: $QUANT_DIR"
fi

# --------------------------------------------------
# 4. Organize manifests by CPS
# --------------------------------------------------
if [[ -d "$MANIFEST_DIR" ]]; then
    for f in "${MANIFEST_DIR}"/CPS*_CTK4me1_manifest.tsv; do
        [[ -e "$f" ]] || continue
        fname=$(basename "$f")
        cps=$(echo "$fname" | sed -E 's/^(CPS[0-9]+)_CTK4me1_manifest\.tsv/\1/')
        mkdir -p "${QUANT_DIR}/${cps}"
        mv "$f" "${QUANT_DIR}/${cps}/"
    done
    rmdir "$MANIFEST_DIR" 2>/dev/null || true
else
    echo "WARNING: Manifest directory not found: $MANIFEST_DIR"
fi

# --------------------------------------------------
# 5. Organize PCA outputs by CPS
# --------------------------------------------------
if [[ -d "$PCA_DIR" ]]; then
    for f in "${PCA_DIR}"/CPS*_edgeR_PCA.pdf; do
        [[ -e "$f" ]] || continue
        fname=$(basename "$f")
        cps=$(echo "$fname" | sed -E 's/^(CPS[0-9]+)_edgeR_PCA\.pdf/\1/')
        mkdir -p "${PCA_DIR}/${cps}"
        mv "$f" "${PCA_DIR}/${cps}/"
    done
else
    echo "WARNING: PCA directory not found: $PCA_DIR"
fi

echo "------------------------------------------"
echo "edgeR summary aggregation and output organization completed."
echo "Results       : $RESULT_DIR"
echo "Quantification: $QUANT_DIR"
echo "PCA           : $PCA_DIR"
echo "------------------------------------------"
