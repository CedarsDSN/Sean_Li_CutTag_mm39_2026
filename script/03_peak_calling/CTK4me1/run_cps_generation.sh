#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 24:00:00
#SBATCH --mem=64GB
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/logs/consensus_peak_CTK4me1_%j.log

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

CSV_FILE="${METADATA_CURRENT}"
DIRECTORY_PATH="${PROJECT_ROOT}/seacr_peak_calling/CTK4me1"
OUT_DIR="${PROJECT_ROOT}/consensus_peaks/CTK4me1"
MANIFEST="${OUT_DIR}/merging_manifest.log"

mkdir -p "$OUT_DIR"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "ERROR: Metadata file not found: $CSV_FILE"
    exit 1
fi

if [[ ! -d "$DIRECTORY_PATH" ]]; then
    echo "ERROR: SEACR peak directory not found: $DIRECTORY_PATH"
    exit 1
fi

echo "CPS_ID,Marker,Merged_Files" > "$MANIFEST"

echo "Starting metadata-driven CPS generation for CTK4me1..."
echo "Metadata file: $CSV_FILE"
echo "SEACR peak directory: $DIRECTORY_PATH"
echo "Output directory: $OUT_DIR"

# only use CTK4me1 CPS
CPS_LIST=$(awk -F',' 'NR>1 && $5=="CTK4me1" {print $1}' "$CSV_FILE" | tr -d '\r' | sort -u)

for CPS in $CPS_LIST; do

    UNION_FILE="${OUT_DIR}/${CPS}_union.bed"
    MERGED_FILE="${OUT_DIR}/${CPS}_consensus.bed"
    file_list=""

    echo "------------------------------------------"
    echo "Processing CPS: $CPS | Target marker: CTK4me1"

    > "$UNION_FILE"

    # collect all groups from group1 and group2, split by ;
    SAMPLES=$(awk -F',' -v cps="$CPS" '
        NR>1 && $1==cps && $5=="CTK4me1" {
            print $3
            print $4
        }
    ' "$CSV_FILE" | tr ';' '\n' | tr -d '\r' | sed 's/^ *//;s/ *$//' | grep -v '^$' | sort -u)

    for sname in $SAMPLES; do
        if [[ -z "$sname" ]]; then
            continue
        fi

        # match current SEACR naming:
        #   <sample>-CTK4me1-1.0.01.stringent.bed
        #   <sample>-CTK4me1-2.0.01.stringent.bed
        MATCH_FILES=$(find "$DIRECTORY_PATH" -maxdepth 1 -type f \
            -name "${sname}-CTK4me1-*.stringent.bed" \
            | grep -viE "IgG|nAb|CTnAb" \
            | sort)

        if [[ -n "$MATCH_FILES" ]]; then
            while read -r M_FILE; do
                [[ -z "$M_FILE" ]] && continue
                fname=$(basename "$M_FILE")
                echo "  Merging file: $fname"
                cat "$M_FILE" >> "$UNION_FILE"
                file_list="${file_list}${fname}; "
            done <<< "$MATCH_FILES"
        else
            echo "  [WARNING] No SEACR peak file found for sample: $sname"
        fi
    done

    if [[ -s "$UNION_FILE" ]]; then
        echo "  Running bedtools sort and merge..."
        bedtools sort -i "$UNION_FILE" | bedtools merge -i - > "$MERGED_FILE"

        COUNT=$(wc -l < "$MERGED_FILE")
        echo "  Success: $COUNT consensus peaks created for $CPS"

        echo "${CPS},CTK4me1,${file_list}" >> "$MANIFEST"
        rm -f "$UNION_FILE"
    else
        echo "  [ERROR] No data collected for $CPS. Check sample names and SEACR output files."
        rm -f "$UNION_FILE"
    fi
done

echo "------------------------------------------"
echo "Workflow finished. Manifest saved to: $MANIFEST"
