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


source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools

bam_list_dir="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/sf_calculation_Chipseqspikefree/CTK27ac/bam_list"
metafile_dir="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/sf_calculation_Chipseqspikefree/CTK27ac/metaFile"
sf_results_root="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/sf_calculation_Chipseqspikefree/CTK27ac/sf_results"
script_dir="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script"

META_FILE=$1
BAM_LIST_FILE=$2
CPS_ID=$3


CURRENT_RESULTS_DIR="${sf_results_root}/${CPS_ID}"
mkdir -p $CURRENT_RESULTS_DIR
cd $CURRENT_RESULTS_DIR

echo "Running analysis for $CPS_ID, results will be in $CURRENT_RESULTS_DIR"

###$1 is the metadata for Chipseqspikefree;$2 is the bam file list with full path;$3 is the CPS number

Rscript $script_dir/Chipseqspikefree.r \
    $metafile_dir/$META_FILE \
    $bam_list_dir/$BAM_LIST_FILE \
    $CPS_ID


