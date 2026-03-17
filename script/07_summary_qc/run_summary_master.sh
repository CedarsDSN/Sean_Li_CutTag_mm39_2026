#!/bin/bash

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh

RESULT_DIR="${MASTER_RESULT_DIR}"
COUNT_DIR="${MASTER_COUNT_DIR}"
CONSENSUS_DIR="${CPS_DIR}"
PCA_OUTPUT_DIR="${PCA_DIR}"
META_FILE="${METADATA_CURRENT}"

# --------------------------------------------------
# Helper: get marker by CPS
# --------------------------------------------------
get_marker_by_cps() {
    local target_cps="$1"
    awk -F',' -v target_cps="$target_cps" '
        NR==1 {next}
        $1 == target_cps {
            gsub(/\r/, "", $NF)
            gsub(/^[ \t]+|[ \t]+$/, "", $NF)
            print $NF
            exit
        }
    ' "$META_FILE"
}

# --------------------------------------------------
# Helper: get marker by comparison id
# --------------------------------------------------
get_marker_by_comp() {
    local target_comp="$1"
    awk -F',' -v target_comp="$target_comp" '
        NR==1 {next}
        $2 == target_comp {
            gsub(/\r/, "", $NF)
            gsub(/^[ \t]+|[ \t]+$/, "", $NF)
            print $NF
            exit
        }
    ' "$META_FILE"
}

# --------------------------------------------------
# Build marker list
# --------------------------------------------------
MARKERS=$(awk -F',' 'NR>1 {gsub(/\r/,"",$NF); gsub(/^[ \t]+|[ \t]+$/,"",$NF); print $NF}' "$META_FILE" | sort -u)
NUM_MARKERS=$(echo "$MARKERS" | sed '/^$/d' | wc -l)

echo "Detected markers:"
echo "$MARKERS"
echo "------------------------------------------"

# ==================================================
# 1. Aggregate summary/filter/dist in RESULT_DIR
# ==================================================
cd "$RESULT_DIR" || exit 1

rm -f All_Comparisons_Summary.csv All_Filter_Stats.csv All_Chromosome_Dist.csv

first_summary=$(ls CPS*_Comp*_summary.csv 2>/dev/null | head -n 1 || true)
if [[ -n "$first_summary" ]]; then
    head -n 1 "$first_summary" > All_Comparisons_Summary.csv
    awk 'FNR>1' CPS*_Comp*_summary.csv | sort -t, -k1,1n >> All_Comparisons_Summary.csv
else
    echo "WARNING: No summary CSV files found."
fi

first_filter=$(ls CPS*_Comp*_filter_stats.csv 2>/dev/null | head -n 1 || true)
if [[ -n "$first_filter" ]]; then
    head -n 1 "$first_filter" > All_Filter_Stats.csv
    awk 'FNR>1' CPS*_Comp*_filter_stats.csv | sort -t, -k1,1n >> All_Filter_Stats.csv
else
    echo "WARNING: No filter_stats CSV files found."
fi

first_dist=$(ls CPS*_Comp*_dist.csv 2>/dev/null | head -n 1 || true)
if [[ -n "$first_dist" ]]; then
    head -n 1 "$first_dist" > All_Chromosome_Dist.csv
    awk 'FNR>1' CPS*_Comp*_dist.csv | sort -t, -k1,1n >> All_Chromosome_Dist.csv
else
    echo "WARNING: No chromosome distribution CSV files found."
fi

# --------------------------------------------------
# Organize comparison-level result files by marker/CPS
#    manorm2_master_results/<marker>/<CPS>/
# --------------------------------------------------
for f in CPS*_Comp*; do
    [[ -e "$f" ]] || continue

    cps=$(echo "$f" | cut -d'_' -f1)
    comp_id=$(echo "$f" | sed -E 's/^CPS[0-9]+_Comp([0-9]+)_.*/\1/')

    marker=$(get_marker_by_comp "$comp_id")
    [[ -z "$marker" ]] && marker="UnknownMarker"

    mkdir -p "$RESULT_DIR/$marker/$cps"
    mv "$f" "$RESULT_DIR/$marker/$cps"/
done

# If only one marker exists, move aggregate outputs + QC_Plots into that marker folder
if [[ "$NUM_MARKERS" -eq 1 ]]; then
    ONLY_MARKER=$(echo "$MARKERS" | head -n 1)
    mkdir -p "$RESULT_DIR/$ONLY_MARKER"

    [[ -f All_Comparisons_Summary.csv ]] && mv All_Comparisons_Summary.csv "$RESULT_DIR/$ONLY_MARKER"/
    [[ -f All_Filter_Stats.csv ]] && mv All_Filter_Stats.csv "$RESULT_DIR/$ONLY_MARKER"/
    [[ -f All_Chromosome_Dist.csv ]] && mv All_Chromosome_Dist.csv "$RESULT_DIR/$ONLY_MARKER"/

    if [[ -d QC_Plots ]]; then
        mv QC_Plots "$RESULT_DIR/$ONLY_MARKER"/
    fi
fi

# ==================================================
# 2. Organize consensus peaks by marker only
#    consensus_peaks/<marker>/CPS*_consensus.bed
#    consensus_peaks/<marker>/merging_manifest.log
# ==================================================
if [[ -d "$CONSENSUS_DIR" ]]; then
    # Move CPS consensus files
    for f in "$CONSENSUS_DIR"/CPS*_consensus.bed; do
        [[ -e "$f" ]] || continue

        fname=$(basename "$f")
        cps=$(echo "$fname" | sed -E 's/^(CPS[0-9]+)_consensus\.bed/\1/')

        marker=$(get_marker_by_cps "$cps")
        [[ -z "$marker" ]] && marker="UnknownMarker"

        mkdir -p "$CONSENSUS_DIR/$marker"
        mv "$f" "$CONSENSUS_DIR/$marker"/
    done

    # Split merging_manifest.log by marker
    MANIFEST_FILE="${CONSENSUS_DIR}/merging_manifest.log"
    if [[ -f "$MANIFEST_FILE" ]]; then
        header=$(head -n 1 "$MANIFEST_FILE")

        awk -F',' 'NR>1 {
            marker=$2
            gsub(/\r/, "", marker)
            gsub(/^[ \t]+|[ \t]+$/, "", marker)
            print $0 >> "'"$CONSENSUS_DIR"'/" marker "/merging_manifest.tmp"
        }' "$MANIFEST_FILE"

        for marker in $MARKERS; do
            mkdir -p "$CONSENSUS_DIR/$marker"
            if [[ -f "$CONSENSUS_DIR/$marker/merging_manifest.tmp" ]]; then
                {
                    echo "$header"
                    cat "$CONSENSUS_DIR/$marker/merging_manifest.tmp"
                } > "$CONSENSUS_DIR/$marker/merging_manifest.log"
                rm -f "$CONSENSUS_DIR/$marker/merging_manifest.tmp"
            fi
        done

        rm -f "$MANIFEST_FILE"
    fi
else
    echo "WARNING: Consensus peak directory not found: $CONSENSUS_DIR"
fi

# ==================================================
# 3. Organize master count matrices and logs by marker only
#    manorm2_master_counts/<marker>/CPS*_master_counts_profile_bins.xls
#    manorm2_master_counts/<marker>/CPS*_master_counts_profile_bins_log.txt
# ==================================================
if [[ -d "$COUNT_DIR" ]]; then
    for f in "$COUNT_DIR"/CPS*_master_counts_profile_bins.xls "$COUNT_DIR"/CPS*_master_counts_profile_bins_log.txt; do
        [[ -e "$f" ]] || continue

        fname=$(basename "$f")
        cps=$(echo "$fname" | sed -E 's/^(CPS[0-9]+)_master_counts_profile_bins(_log\.txt|\.xls)/\1/')

        marker=$(get_marker_by_cps "$cps")
        [[ -z "$marker" ]] && marker="UnknownMarker"

        mkdir -p "$COUNT_DIR/$marker"
        mv "$f" "$COUNT_DIR/$marker"/
    done
else
    echo "WARNING: Master count directory not found: $COUNT_DIR"
fi

# ==================================================
# 4. Organize PCA outputs by marker only
#    PCA_master/<marker>/CPS*_PCA.pdf
# ==================================================
if [[ -d "$PCA_OUTPUT_DIR" ]]; then
    for f in "$PCA_OUTPUT_DIR"/CPS*_PCA.pdf; do
        [[ -e "$f" ]] || continue

        fname=$(basename "$f")
        cps=$(echo "$fname" | sed -E 's/^(CPS[0-9]+)_PCA\.pdf/\1/')

        marker=$(get_marker_by_cps "$cps")
        [[ -z "$marker" ]] && marker="UnknownMarker"

        mkdir -p "$PCA_OUTPUT_DIR/$marker"
        mv "$f" "$PCA_OUTPUT_DIR/$marker"/
    done
else
    echo "WARNING: PCA output directory not found: $PCA_OUTPUT_DIR"
fi

echo "------------------------------------------"
echo "Summary aggregation and final output organization completed."
echo "Results      : $RESULT_DIR"
echo "Consensus    : $CONSENSUS_DIR"
echo "Master counts: $COUNT_DIR"
echo "PCA          : $PCA_OUTPUT_DIR"
echo "------------------------------------------"
