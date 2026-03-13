# Full Pipeline Run Guide

This page describes how to run the maintained CUT&Tag analysis pipeline from start to finish using the current production scripts under `script/`.

## Pipeline flowchart

### Detailed workflow

```{mermaid}
flowchart TD

    A["Input data<br/>trim_fastqs/*.fastq.gz"] --> B["01_alignment<br/>submit_alignment.sh<br/>run_alignment.sh"]
    A --> C["01_alignment (spike-in)<br/>submit_alignment_spikein.sh<br/>run_alignment_spikein.sh"]

    B --> D["Output<br/>bam/*.coordsorted.bam"]
    C --> E["Output<br/>bam_spike/*.amp.bam<br/>bam_spike/*.ecoli.bam"]

    D --> F["02_bam_processing<br/>submit_process_bam.sh<br/>run_process_bam.sh"]
    F --> G["Output<br/>bam/*.rmdup.bam<br/>qc/*.metrics / *.stats"]

    G --> H["03_signal_generation<br/>run_bigwig_cpm.sh"]
    G --> I["03_signal_generation<br/>run_bedgraph_seacr.sh"]
    G --> J["03_signal_generation<br/>run_bam_to_bed.sh"]

    H --> K["Output<br/>bw_bedgraph_cpm/*.cpm.bw"]
    I --> L["Output<br/>seacr_bedgraph/*.seacr.bedgraph"]
    J --> M["Output<br/>bam_to_bed/*.bed"]

    L --> N["04_peak_calling<br/>run_seacr_peak_calling.sh"]
    N --> O["Output<br/>seacr_peak_calling/*.stringent.bed"]

    O --> P["08_preflight_checks<br/>preflight_check_cps_peak_inputs.sh"]
    P --> Q["04_peak_calling<br/>run_cps_generation.sh"]
    Q --> R["Output<br/>consensus_peaks/CPS*_consensus.bed"]

    R --> S["05_quantification<br/>submit_profile_bins_all.sh<br/>submit_profile_bins_master.sh<br/>run_profile_bins_master.sh"]
    M --> S
    O --> S

    S --> T["Output<br/>manorm2_master_counts/CPS*_master_counts_profile_bins.xls"]

    T --> U["06_differential_analysis<br/>submit_manorm2_all.sh<br/>submit_manorm2_master_count.sh<br/>run_manorm2_master_count.R"]
    U --> V["Output<br/>manorm2_master_results/*_results.txt<br/>*_summary.csv<br/>*_filter_stats.csv<br/>*_dist.csv"]

    V --> W["07_summary_qc<br/>run_summary_master.sh"]
    T --> X["07_summary_qc<br/>run_plot_pca.R"]

    W --> Y["Final summary outputs<br/>All_Comparisons_Summary.csv<br/>All_Filter_Stats.csv<br/>All_Chromosome_Dist.csv"]
    X --> Z["Final PCA outputs<br/>PCA_master/*.pdf"]
```

## Overview

The maintained workflow consists of the following major stages:

1. alignment  
2. BAM processing  
3. signal generation  
4. SEACR peak calling and CPS generation  
5. master count matrix quantification  
6. MAnorm2 differential enrichment analysis  
7. summary aggregation and PCA  

The pipeline is currently executed stage by stage rather than through a single workflow engine.

---

## Directory structure

The maintained pipeline scripts are organized as:

```text
script/
├── 01_alignment/
├── 02_bam_processing/
├── 03_signal_generation/
├── 04_peak_calling/
├── 05_quantification/
├── 06_differential_analysis/
├── 07_summary_qc/
├── 08_preflight_checks/
├── config/
├── metadata_form/
├── methods_comparison/
├── legacy/
└── reference/
```

The central configuration file is:

```text
script/config/project_config.sh
```

This file defines the project root, major data directories, metadata paths, reference paths, and common parameters.

---

## Before starting

Make sure the following are ready before running the pipeline:

- trimmed FASTQ files are present in the expected input directory
- `project_config.sh` has the correct project paths
- the metadata file is correct
- the required conda environment and tools are available

### Key configuration file

```text
script/config/project_config.sh
```

### Primary metadata file

```text
script/metadata_form/Metadata_Comparison.csv
```

### Important notes

- `submit_*` scripts are used to submit a batch of jobs for a stage
- `submit_*_all.sh` scripts are convenience entry points for submitting all jobs in a stage
- `run_*` scripts are the actual worker scripts
- `preflight_check_cps_peak_inputs.sh` is a validation step and should be run before CPS generation / quantification

---

# Stage 1. Alignment

## Purpose

Align trimmed paired-end FASTQ files to the mm39 genome and generate sorted BAM files.  
A separate spike-in alignment stage is also available.

## Scripts used

### Main genome alignment
- `01_alignment/submit_alignment.sh`
- `01_alignment/run_alignment.sh`

### Spike-in alignment
- `01_alignment/submit_alignment_spikein.sh`
- `01_alignment/run_alignment_spikein.sh`

## Recommended execution

```bash
bash script/01_alignment/submit_alignment.sh
bash script/01_alignment/submit_alignment_spikein.sh
```

## Main outputs

### Genome alignment
- `bam/*.coordsorted.bam`
- `bam/*.coordsorted.bam.bai`
- `bam/*_bowtie2.log`

### Spike-in alignment
- `bam_spike/*.amp.bam`
- `bam_spike/*.ecoli.bam`

## Check before moving on

Wait until all alignment jobs have completed successfully.

---

# Stage 2. BAM processing

## Purpose

Filter aligned BAM files, remove mitochondrial reads, keep proper pairs, remove duplicates, index final BAMs, and generate basic QC summaries.

## Scripts used

- `02_bam_processing/submit_process_bam.sh`
- `02_bam_processing/run_process_bam.sh`

## Recommended execution

```bash
bash script/02_bam_processing/submit_process_bam.sh
```

## Main outputs

- `bam/*.rmdup.bam`
- `bam/*.rmdup.bam.bai`
- `qc/*.rmDups.metrics.txt`
- `qc/*.rmdup.stats`

## Check before moving on

Wait until all BAM processing jobs have completed successfully.

---

# Stage 3. Signal generation

## Purpose

Generate the core downstream analysis inputs from processed BAM files:

- CPM-normalized BigWig for visualization
- SEACR-compatible bedGraph
- paired BED for `profile_bins`

## Scripts used

- `03_signal_generation/run_bigwig_cpm.sh`
- `03_signal_generation/run_bedgraph_seacr.sh`
- `03_signal_generation/run_bam_to_bed.sh`

## Recommended execution

First determine the number of processed BAM files:

```bash
N=$(find /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam -maxdepth 1 -name "*.rmdup.bam" | sort | wc -l)
M=$(find /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam -maxdepth 1 -name "*rmdup*.bam" | grep -viE "IgG|nAb|CTnAb" | sort | wc -l)
```

Then run:

```bash
sbatch --array=1-"$N" script/03_signal_generation/run_bigwig_cpm.sh
sbatch --array=1-"$N" script/03_signal_generation/run_bedgraph_seacr.sh
sbatch --array=1-"$M" script/03_signal_generation/run_bam_to_bed.sh
```

## Main outputs

### Visualization
- `bw_bedgraph_cpm/*.cpm.bw`

### SEACR input
- `seacr_bedgraph/*.seacr.bedgraph`

### Quantification input
- `bam_to_bed/*.bed`

## Check before moving on

Wait until all signal-generation jobs are complete.

---

# Stage 4. SEACR peak calling and CPS generation

## Purpose

Call individual sample peaks with SEACR, verify that metadata-defined sample-marker peak inputs exist, and generate marker-specific consensus peak sets (CPS).

## Scripts used

### Peak calling
- `04_peak_calling/run_seacr_peak_calling.sh`

### Validation
- `08_preflight_checks/preflight_check_cps_peak_inputs.sh`

### CPS generation
- `04_peak_calling/run_cps_generation.sh`

## Recommended execution

First determine the number of SEACR-compatible bedGraph files:

```bash
K=$(find /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/seacr_bedgraph -maxdepth 1 -name "*.seacr.bedgraph" | grep -viE "IgG|nAb|CTnAb" | sort | wc -l)
```

Run SEACR:

```bash
sbatch --array=1-"$K" script/04_peak_calling/run_seacr_peak_calling.sh
```

After SEACR finishes, run the preflight validation:

```bash
bash script/08_preflight_checks/preflight_check_cps_peak_inputs.sh
```

Then generate CPS:

```bash
bash script/04_peak_calling/run_cps_generation.sh
```

## Main outputs

### Sample-level SEACR peaks
- `seacr_peak_calling/*.stringent.bed`

### CPS outputs
- `consensus_peaks/CPS*_consensus.bed`
- `consensus_peaks/merging_manifest.log`

## Check before moving on

Make sure the preflight check passes or investigate any missing peak file warnings before continuing.

---

# Stage 5. Master count matrix quantification

## Purpose

Quantify read counts and occupancy across CPS regions using `profile_bins`, and generate one master matrix per CPS.

## Scripts used

- `05_quantification/submit_profile_bins_all.sh`
- `05_quantification/submit_profile_bins_master.sh`
- `05_quantification/run_profile_bins_master.sh`

## Recommended execution

To submit all CPS jobs:

```bash
bash script/05_quantification/submit_profile_bins_all.sh
```

## Main outputs

- `manorm2_master_counts/CPS*_master_counts_profile_bins.xls`

These master matrices are the direct inputs to downstream MAnorm2 differential analysis and PCA generation.

## Check before moving on

Wait until all `profile_bins` jobs are complete and verify that the expected `CPS*_master_counts_profile_bins.xls` files are present.

---

# Stage 6. MAnorm2 differential enrichment analysis

## Purpose

Run comparison-level differential enrichment analysis using MAnorm2, with filtering, normalization, annotation, and summary table generation.

## Scripts used

- `06_differential_analysis/submit_manorm2_all.sh`
- `06_differential_analysis/submit_manorm2_master_count.sh`
- `06_differential_analysis/run_manorm2_master_count.R`

## Recommended execution

To submit all comparisons:

```bash
bash script/06_differential_analysis/submit_manorm2_all.sh
```

## Main outputs

- `manorm2_master_results/*_results.txt`
- `manorm2_master_results/*_summary.csv`
- `manorm2_master_results/*_filter_stats.csv`
- `manorm2_master_results/*_dist.csv`
- `manorm2_master_results/QC_Plots/*.pdf`

## Check before moving on

Wait until all comparison-level MAnorm2 jobs have completed.

---

# Stage 7. Summary aggregation and PCA

## Purpose

Aggregate comparison-level outputs into global summary tables, organize result files by marker and CPS, and generate PCA plots from CPS-level master matrices.

## Scripts used

- `07_summary_qc/run_summary_master.sh`
- `07_summary_qc/run_plot_pca.R`

## Recommended execution

After all MAnorm2 jobs have finished:

```bash
bash script/07_summary_qc/run_summary_master.sh
Rscript script/07_summary_qc/run_plot_pca.R
```

## Main outputs

### Aggregated tables
- `manorm2_master_results/All_Comparisons_Summary.csv`
- `manorm2_master_results/All_Filter_Stats.csv`
- `manorm2_master_results/All_Chromosome_Dist.csv`

### Organized comparison-level outputs
These are organized into marker- and CPS-specific folders, for example:

```text
manorm2_master_results/
└── CTK27ac/
    ├── All_Comparisons_Summary.csv
    ├── All_Filter_Stats.csv
    ├── All_Chromosome_Dist.csv
    ├── QC_Plots/
    └── CPS4/
```

### PCA outputs
- `PCA_master/*.pdf`

---

# Recommended full execution order

Run the maintained pipeline in the following order:

## Step 1
```bash
bash script/01_alignment/submit_alignment.sh
bash script/01_alignment/submit_alignment_spikein.sh
```

## Step 2
```bash
bash script/02_bam_processing/submit_process_bam.sh
```

## Step 3
```bash
N=$(find /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam -maxdepth 1 -name "*.rmdup.bam" | sort | wc -l)
M=$(find /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam -maxdepth 1 -name "*rmdup*.bam" | grep -viE "IgG|nAb|CTnAb" | sort | wc -l)

sbatch --array=1-"$N" script/03_signal_generation/run_bigwig_cpm.sh
sbatch --array=1-"$N" script/03_signal_generation/run_bedgraph_seacr.sh
sbatch --array=1-"$M" script/03_signal_generation/run_bam_to_bed.sh
```

## Step 4
```bash
K=$(find /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/seacr_bedgraph -maxdepth 1 -name "*.seacr.bedgraph" | grep -viE "IgG|nAb|CTnAb" | sort | wc -l)

sbatch --array=1-"$K" script/04_peak_calling/run_seacr_peak_calling.sh
bash script/08_preflight_checks/preflight_check_cps_peak_inputs.sh
bash script/04_peak_calling/run_cps_generation.sh
```

## Step 5
```bash
bash script/05_quantification/submit_profile_bins_all.sh
```

## Step 6
```bash
bash script/06_differential_analysis/submit_manorm2_all.sh
```

## Step 7
```bash
bash script/07_summary_qc/run_summary_master.sh
Rscript script/07_summary_qc/run_plot_pca.R
```

---

# Validation strategy

For a new code update, the recommended validation strategy is:

1. run a small subset of samples  
2. verify that each stage produces the expected output files  
3. verify that downstream stages can directly consume upstream outputs  
4. run the full dataset  
5. compare the new outputs against the previous production results  

Key checks include:

- file counts per major output directory
- consistency of CPS generation
- consistency of `profile_bins` master matrices
- comparison-level MAnorm2 summary statistics
- overall PCA and QC trends

---

# Related files

## Configuration
- `script/config/project_config.sh`

## Metadata
- `script/metadata_form/Metadata_Comparison.csv`
- `script/metadata_form/Metadata_CTK27ac_Comparison.csv`
- `script/metadata_form/Metadata_CTK4me1_Comparison.csv`

## Reference files
- `script/reference/mm39.excluderanges.bed`
- `script/reference/mm10.Boyle.mm10-Excludable.v2.bed`

---

# Notes

- `methods_comparison/` contains exploratory or comparison workflows and is not part of the default maintained production workflow.
- `legacy/` contains older helper scripts retained for reference and is not part of the maintained production workflow.
- The current maintained pipeline is executed stage by stage rather than by a single workflow engine.

