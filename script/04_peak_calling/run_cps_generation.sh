#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 24:00:00
#SBATCH --mem=64GB
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/consensus_peak_%j.log

set -eo pipefail

source /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/config/project_config.sh
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh

conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

CSV_FILE="${METADATA_CURRENT}"
DIRECTORY_PATH="${PROJECT_ROOT}/seacr_peak_calling"
OUT_DIR="${PROJECT_ROOT}/consensus_peaks"
MANIFEST="${OUT_DIR}/merging_manifest.log"

mkdir -p "$OUT_DIR"

echo "CPS_ID,Marker,Merged_Files" > "$MANIFEST"

echo "Starting metadata-driven CPS generation..."
echo "Metadata file: $CSV_FILE"
echo "SEACR peak directory: $DIRECTORY_PATH"

tail -n +2 "$CSV_FILE" | cut -d, -f1 | sort | uniq | while read -r CPS; do

    UNION_FILE="${OUT_DIR}/${CPS}_union.bed"
    MERGED_FILE="${OUT_DIR}/${CPS}_consensus.bed"
    file_list=""

    MARKER=$(grep "^${CPS}," "$CSV_FILE" | head -n 1 | awk -F',' '{print $5}' | tr -d '\r' | xargs)

    echo "------------------------------------------"
    echo "Processing CPS: $CPS | Target marker: $MARKER"

    > "$UNION_FILE"

    SAMPLES=$(grep "^${CPS}," "$CSV_FILE" | awk -F',' '{print $3,$4}' | tr ';' '\n' | tr ' ' '\n' | sort -u)

    for sname in $SAMPLES; do
        sname=$(echo "$sname" | tr -d '\r' | xargs)

        if [[ -z "$sname" ]]; then
            continue
        fi

        # Match target sample + target marker + SEACR stringent peak output
        # Current maintained SEACR naming is:
        #   <sample>.0.01.stringent.bed
        # The wildcard keeps this robust as long as the file still ends in .stringent.bed
        MATCH_FILES=$(ls "${DIRECTORY_PATH}"/${sname}*${MARKER}*.stringent.bed 2>/dev/null | grep -viE "IgG|nAb|CTnAb")

        if [[ -n "$MATCH_FILES" ]]; then
            for M_FILE in $MATCH_FILES; do
                fname=$(basename "$M_FILE")
                echo "  Merging file: $fname"
                cat "$M_FILE" >> "$UNION_FILE"
                file_list="${file_list}${fname}; "
            done
        else
            echo "  [WARNING] No SEACR peak file found for sample: $sname with marker: $MARKER"
        fi
    done

    if [[ -s "$UNION_FILE" ]]; then
        echo "  Running bedtools sort and merge..."
        bedtools sort -i "$UNION_FILE" | bedtools merge -i - > "$MERGED_FILE"

        COUNT=$(wc -l < "$MERGED_FILE")
        echo "  Success: $COUNT consensus peaks created for $CPS"

        echo "${CPS},${MARKER},${file_list}" >> "$MANIFEST"
        rm -f "$UNION_FILE"
    else
        echo "  [ERROR] No data collected for $CPS. Check sample names, marker names, and SEACR output files."
    fi
done

echo "------------------------------------------"
echo "Workflow finished. Manifest saved to: $MANIFEST"
