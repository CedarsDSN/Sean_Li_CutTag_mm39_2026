# Pipeline Index

## Current production workflow

### 01_alignment
- `submit_alignment.sh`: submit mm39 alignment jobs
- `submit_alignment_spikein.sh`: submit spike-in alignment jobs
- `run_alignment.sh`: mm39 alignment worker
- `run_alignment_spikein.sh`: spike-in alignment worker

### 02_bam_processing
- `submit_process_bam.sh`: submit BAM processing jobs
- `run_process_bam.sh`: BAM filtering, chrM removal, duplicate removal, indexing, and QC summary generation

### 03_signal_generation
- `run_bedgraph_seacr.sh`: generate raw fragment bedGraph for SEACR
- `run_bigwig_cpm.sh`: generate CPM-normalized BigWig for visualization
- `run_bam_to_bed.sh`: convert BAM to paired BED for `profile_bins`

### 04_peak_calling
- `run_seacr_peak_calling.sh`: run SEACR peak calling
- `run_cps_generation.sh`: generate marker-specific CPS

### 05_quantification
- `submit_profile_bins_all.sh`: submit all CPS-level `profile_bins` jobs
- `submit_profile_bins_master.sh`: submit selected CPS-level `profile_bins` jobs
- `run_profile_bins_master.sh`: `profile_bins` worker for master matrix generation

### 06_differential_analysis
- `submit_manorm2_all.sh`: submit all MAnorm2 comparison jobs
- `submit_manorm2_master_count.sh`: submit selected MAnorm2 comparison jobs
- `run_manorm2_master_count.R`: MAnorm2 differential enrichment analysis script

### 07_summary_qc
- `run_summary_master.sh`: aggregate summary/filter/dist outputs and organize result files
- `run_plot_pca.R`: generate PCA plots from CPS-level master matrices

### 08_preflight_checks
- `preflight_check_cps_peak_inputs.sh`: validate metadata-defined SEACR peak inputs before CPS generation

## Supporting directories

### config
- `project_config.sh`: shared project paths and common parameters used across scripts

### metadata_form
- `Metadata_Comparison.csv`: current primary metadata file for maintained workflow
- `Metadata_CTK27ac_Comparison.csv`: marker-specific metadata for H3K27ac-related analyses
- `Metadata_CTK4me1_Comparison.csv`: marker-specific metadata for H3K4me1-related analyses

### reference
- `mm39.excluderanges.bed`: mm39 blacklist / exclusion regions
- `mm10.Boyle.mm10-Excludable.v2.bed`: mm10 blacklist / exclusion regions retained for reference or legacy compatibility

### methods_comparison
- `Chipseqspikefree.sh`: shell wrapper for ChIPseqSpikeInFree-related analyses
- `sub_Chipseqspikefree.sh`: submission script for ChIPseqSpikeInFree jobs
- `Chipseqspikefree.r`: R script for ChIPseqSpikeInFree calculations
- `bw_bedgraph_generated_w_sf.sh`: generate tracks using spike-in-free scaling factors
- `merge_cps_matrix.r`: helper script for exploratory CPS-level matrix merging

### legacy
- `generate_profile_bins_commands.sh`: older command-generation approach for `profile_bins`
- `run_profile_bins_master.sh`: older worker version retained for reference
- `submit_profile_bins_master.sh`: older submission version retained for reference

### logs
- reserved directory for Slurm logs and related runtime logs

## Current maintained workflow

The current maintained workflow is:

1. alignment  
2. BAM processing  
3. dual-track signal generation  
4. SEACR peak calling and CPS generation  
5. master count matrix quantification  
6. MAnorm2 differential enrichment analysis  
7. summary aggregation and PCA  

## Notes

- `submit_*_all.sh` scripts are convenience entry points for running all jobs in a stage.
- `submit_*` scripts are used for partial or targeted reruns.
- `run_*` scripts are the actual worker scripts.
- `run_bigwig_cpm.sh` is for visualization tracks.
- `run_bedgraph_seacr.sh` is for SEACR peak-calling input generation.
- `preflight_check_cps_peak_inputs.sh` is a validation step and not part of the main computational chain.
- `methods_comparison/` and `legacy/` are retained for exploratory analyses, historical reference, or debugging, and are not part of the default maintained production workflow.
