#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH -p defq
#SBATCH -t 12:00:00
#SBATCH --mem=32GB
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/logs/profile_bins_CTK27ac_%A_%a.log

set -eo pipefail

PROJECT_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39
SCRIPT_ROOT=/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script
METADATA_FILE=${SCRIPT_ROOT}/metadata_form/Metadata_Comparison.csv

PEAK_DIR=${PROJECT_ROOT}/macs3_peak_calls/CTK27ac
BED_DIR=${PROJECT_ROOT}/bam_to_bed
OUT_DIR=${PROJECT_ROOT}/quantification/CTK27ac
MANIFEST_DIR=${OUT_DIR}/manifests
BLACKLIST_BED=${PROJECT_ROOT}/script/reference/mm39.excluderanges.bed

mkdir -p "${OUT_DIR}"
mkdir -p "${MANIFEST_DIR}"

source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env

TASK_ID="${SLURM_ARRAY_TASK_ID:-}"
if [[ -z "$TASK_ID" ]]; then
    echo "ERROR: SLURM_ARRAY_TASK_ID is not set"
    exit 1
fi

if [[ ! -f "$METADATA_FILE" ]]; then
    echo "ERROR: Metadata file not found: $METADATA_FILE"
    exit 1
fi

if [[ ! -f "$BLACKLIST_BED" ]]; then
    echo "ERROR: Blacklist BED not found: $BLACKLIST_BED"
    exit 1
fi

CPS=$(Rscript -e '
meta <- read.csv("'"${METADATA_FILE}"'", stringsAsFactors=FALSE, check.names=FALSE)
meta <- meta[meta$histone_marker == "CTK27ac", ]
cps <- sort(unique(meta$Concensus_peak))
tid <- as.integer(Sys.getenv("SLURM_ARRAY_TASK_ID"))
if (is.na(tid) || tid < 1 || tid > length(cps)) stop("Invalid array task ID")
cat(cps[tid])
')

echo "Processing ${CPS} (CTK27ac)"

MANIFEST_FILE="${MANIFEST_DIR}/${CPS}_CTK27ac_manifest.tsv"

Rscript -e '
metadata_file <- "'"${METADATA_FILE}"'"
peak_dir <- "'"${PEAK_DIR}"'"
bed_dir <- "'"${BED_DIR}"'"
manifest_file <- "'"${MANIFEST_FILE}"'"
cps <- "'"${CPS}"'"

meta <- read.csv(metadata_file, stringsAsFactors=FALSE, check.names=FALSE)
meta <- meta[meta$Concensus_peak == cps & meta$histone_marker == "CTK27ac", ]

split_groups <- function(x) unlist(strsplit(x, ";", fixed=TRUE))

groups <- sort(unique(trimws(c(
  unlist(lapply(meta$group1, split_groups)),
  unlist(lapply(meta$group2, split_groups))
))))
groups <- groups[groups != ""]

samples <- c(rbind(
  paste0(groups, "-CTK27ac-1"),
  paste0(groups, "-CTK27ac-2")
))
samples <- sort(unique(samples))

manifest <- data.frame(
  sample = samples,
  label = gsub("-", "_", samples),
  peak_file = file.path(peak_dir, samples, paste0(samples, "_peaks.narrowPeak")),
  summit_file = file.path(peak_dir, samples, paste0(samples, "_summits.bed")),
  read_file = file.path(bed_dir, paste0(samples, ".rmdup.blfilter.bed")),
  stringsAsFactors = FALSE
)

write.table(manifest, manifest_file, sep="\t", quote=FALSE, row.names=FALSE)
cat("Wrote manifest:", manifest_file, "\n")
'

# check all files exist
awk 'NR>1{print $3"\n"$4"\n"$5}' "$MANIFEST_FILE" | while read -r f; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: Missing file: $f"
        exit 1
    fi
done

PEAKS=$(awk 'NR>1{print $3}' "$MANIFEST_FILE" | paste -sd, -)
SUMMITS=$(awk 'NR>1{print $4}' "$MANIFEST_FILE" | paste -sd, -)
READS=$(awk 'NR>1{print $5}' "$MANIFEST_FILE" | paste -sd, -)
LABS=$(awk 'NR>1{print $2}' "$MANIFEST_FILE" | paste -sd, -)

profile_bins \
  --peaks="${PEAKS}" \
  --summits="${SUMMITS}" \
  --reads="${READS}" \
  --labs="${LABS}" \
  --paired \
  --typical-bin-size 2000 \
  --filter="${BLACKLIST_BED}" \
  -n "${OUT_DIR}/${CPS}_macs3_per_sample_summit"

echo "Finished ${CPS}"
