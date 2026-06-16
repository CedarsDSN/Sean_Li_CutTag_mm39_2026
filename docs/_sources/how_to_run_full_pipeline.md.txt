# Full Pipeline Run Guide

## Overview

This page describes the current maintained CUT&Tag analysis workflow for the Sean Li mm39 project.
The scripts under `script/` are the source of truth for the active pipeline.

The current workflow is:

- alignment to mm39 with Bowtie2
- BAM filtering, duplicate removal, and mm39 blacklist filtering
- CTK4me1 peak calling with SEACR followed by CPS consensus peak generation
- CTK27ac peak calling with MACS3 in BAMPE mode
- paired BED conversion for `profile_bins --paired`
- marker-specific `profile_bins` quantification
- edgeR differential enrichment analysis
- edgeR-based summary organization and PCA QC

The active implementation does not use the previous MAnorm2 differential-analysis branch as the maintained analysis path.

## Recommended execution order

1. Alignment
   - `script/01_alignment/submit_alignment.sh`

2. BAM processing
   - `script/02_bam_processing/submit_process_bam.sh`

3. CTK27ac peak calling by MACS3
   - `script/03_peak_calling/CTK27ac/submit_macs3_callpeak_CTK27ac.sh`

4. CTK4me1 peak calling by SEACR
   - `script/03_peak_calling/CTK4me1/submit_seacr_callpeak_CTK4me1.sh`

5. CTK4me1 consensus peak generation
   - `script/03_peak_calling/CTK4me1/run_cps_generation.sh`

6. BAM to paired-end BED conversion
   - `script/04_quantification/run_bam_to_bed.sh`

7. CTK27ac quantification
   - `script/04_quantification/CTK27ac/submit_profile_bins_all_CPS_CTK27ac.sh`

8. CTK4me1 quantification
   - `script/04_quantification/CTK4me1/submit_profile_bins_all_CPS_CTK4me1.sh`

9. CTK27ac differential analysis by edgeR
   - `script/05_differential_analysis/CTK27ac/submit_edgeR_all_comparisons_CTK27ac.sh`

10. CTK4me1 differential analysis by edgeR
   - `script/05_differential_analysis/CTK4me1/submit_edgeR_all_comparisons_CTK4me1.sh`

11. PCA-based QC
   - `script/06_summary_qc/CTK27ac/run_edgeR_PCA_all_CPS_CTK27ac.R`
   - `script/06_summary_qc/CTK4me1/run_edgeR_PCA_all_CPS_CTK4me1.R`

12. Organize outputs
   - `script/06_summary_qc/CTK27ac/organize_edgeR_outputs_CTK27ac.sh`
   - `script/06_summary_qc/CTK4me1/organize_edgeR_outputs_CTK4me1.sh`

## Notes before running

- Most scripts are designed for SLURM on the Cedars-Sinai HPC environment.
- Most paths are configured for `/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39`.
- The current differential analysis method is edgeR.
- The current maintained marker branches are CTK4me1 and CTK27ac.
- CTK4me1 uses SEACR plus CPS consensus peak sets.
- CTK27ac uses MACS3 per-sample peak and summit files.
- Confirm that `Metadata_Comparison.csv` contains the marker rows you intend to process.
