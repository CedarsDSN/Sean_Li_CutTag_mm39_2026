#!/bin/bash

# =========================
# Project root
# =========================
PROJECT_ROOT="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39"
SCRIPT_ROOT="${PROJECT_ROOT}/script"

# =========================
# Input / reference paths
# =========================
FASTQ_DIR="${PROJECT_ROOT}/trim_fastqs"
GENOME_REF="/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/Bowtie2Index/GRCm39"

# =========================
# Script stage directories
# =========================
ALIGNMENT_DIR="${SCRIPT_ROOT}/01_alignment"
BAM_PROCESS_DIR="${SCRIPT_ROOT}/02_bam_processing"
SIGNAL_DIR="${SCRIPT_ROOT}/03_signal_generation"
PEAK_DIR="${SCRIPT_ROOT}/04_peak_calling"
QUANT_DIR="${SCRIPT_ROOT}/05_quantification"
DE_DIR="${SCRIPT_ROOT}/06_differential_analysis"
SUMMARY_DIR="${SCRIPT_ROOT}/07_summary_qc"
CHECK_DIR="${SCRIPT_ROOT}/08_preflight_checks"
METHOD_DIR="${SCRIPT_ROOT}/methods_comparison"

# =========================
# Metadata and references
# =========================
METADATA_DIR="${SCRIPT_ROOT}/metadata_form"
METADATA_CURRENT="${METADATA_DIR}/Metadata_Comparison.csv"
METADATA_K27AC="${METADATA_DIR}/Metadata_CTK27ac_Comparison.csv"
METADATA_K4ME1="${METADATA_DIR}/Metadata_CTK4me1_Comparison.csv"

REFERENCE_DIR="${SCRIPT_ROOT}/reference"
BLACKLIST_MM39="${REFERENCE_DIR}/mm39.excluderanges.bed"
BLACKLIST_MM10="${REFERENCE_DIR}/mm10.Boyle.mm10-Excludable.v2.bed"

# =========================
# Common analysis directories
# =========================
BAM_DIR="${PROJECT_ROOT}/bam"
BW_DIR="${PROJECT_ROOT}/bw"
BEDGRAPH_DIR="${PROJECT_ROOT}/bedgraph"
SEACR_DIR="${PROJECT_ROOT}/seacr"
CPS_DIR="${PROJECT_ROOT}/consensus_peaks"
MASTER_COUNT_DIR="${PROJECT_ROOT}/manorm2_master_counts"
MASTER_RESULT_DIR="${PROJECT_ROOT}/manorm2_master_results"
PCA_DIR="${PROJECT_ROOT}/PCA_master"

# =========================
# Logs
# =========================
LOG_DIR="${PROJECT_ROOT}/log"

# =========================
# Common parameters
# =========================
MAPQ_MIN=10
FRAG_MAX=1000
SEACR_THRESHOLD="0.01"
SEACR_MODE="stringent"
