#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 24:00:00
#SBATCH --mem=64GB
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/consensus_peak_%j.log

# Environment Setup
source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

# --- Path Definitions ---
# Fixed the path to your actual CSV file as requested
#CSV_FILE="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/Metadata_CTK27ac_Comparison.csv"
#CSV_FILE="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/Metadata_CTK4me1_Comparison.csv"
CSV_FILE="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/Metadata_CTK27ac_CPS13.csv"
DIRECTORY_PATH="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/seacr_stringent_001"
OUT_DIR="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/consensus_peaks"
MANIFEST="${OUT_DIR}/merging_manifest.log"

mkdir -p $OUT_DIR
# Header for the manifest log to track merged files
echo "CPS_ID,Marker,Merged_Files" > "$MANIFEST"

echo "Starting STRICT Consensus Peak Generation for H3K27ac..."
echo "Metadata: $CSV_FILE"

# Extract unique CPS IDs from the 1st column
tail -n +2 "$CSV_FILE" | cut -d, -f1 | sort | uniq | while read CPS; do

    UNION_FILE="${OUT_DIR}/${CPS}_union.bed"
    MERGED_FILE="${OUT_DIR}/${CPS}_consensus.bed"
    file_list=""
    
    # Get the specific Histone Marker for this CPS group from the 5th column
    MARKER=$(grep "^${CPS}," "$CSV_FILE" | head -n 1 | awk -F',' '{print $5}' | tr -d '\r' | xargs)

    echo "------------------------------------------"
    echo "Processing Group: $CPS | Target Marker: $MARKER"
    > "$UNION_FILE"

    # Identify all sample IDs in this CPS (Columns 3 and 4)
    # This handles both single samples and semicolon-separated groups
    SAMPLES=$(grep "^${CPS}," "$CSV_FILE" | awk -F',' '{print $3,$4}' | tr ';' '\n' | tr ' ' '\n' | sort -u)

    for sname in $SAMPLES; do
        sname=$(echo "$sname" | tr -d '\r' | xargs)
        if [[ -z "$sname" ]]; then continue; fi

        # --- THE FIX: Match Sample AND Marker AND exclude IgG ---
        # This wildcard pattern ensures we only get files like 'SampleID*CTK27ac*.stringent.bed'
        # It correctly catches -1, -2, etc. while ignoring other markers like CTK4me1
        MATCH_FILES=$(ls ${DIRECTORY_PATH}/${sname}*${MARKER}*.stringent.bed 2>/dev/null | grep -v "IgG")

        if [[ -n "$MATCH_FILES" ]]; then
            for M_FILE in $MATCH_FILES; do
                fname=$(basename "$M_FILE")
                echo "  Merging file: $fname"
                cat "$M_FILE" >> "$UNION_FILE"
                file_list="${file_list}${fname}; "
            done
        else
            echo "  [WARNING] NO file found for Sample: $sname with Marker: $MARKER"
        fi
    done

    # Final Merge process
    if [ -s "$UNION_FILE" ]; then
        echo "  Running bedtools sort and merge..."
        bedtools sort -i "$UNION_FILE" | bedtools merge -i - > "$MERGED_FILE"

        COUNT=$(wc -l < "$MERGED_FILE")
        echo "  Success: $COUNT consensus peaks created for $CPS."
        
        # Write to manifest for your future reference
        echo "${CPS},${MARKER},${file_list}" >> "$MANIFEST"
        rm -f "$UNION_FILE"
    else
        echo "  [ERROR] No data collected for $CPS. Check if filenames contain $MARKER."
    fi
done

echo "------------------------------------------"
echo "Workflow finished. Manifest saved to: $MANIFEST"
