# Step 6: SEACR Peak Calling

## Overview

CUT&Tag data is typically characterized by extremely low global background and high local signal-to-noise ratios. This sparse signal structure differs substantially from conventional ChIP-seq and is one of the main reasons why CUT&Tag often benefits from a dedicated peak-calling strategy.

To identify enriched regions from these sparse-background profiles, we used **SEACR** (Sparse Enrichment Analysis for CUT&RUN), a peak caller specifically designed for CUT&RUN/CUT&Tag-style data. SEACR operates directly on fragment pileup BedGraph files and is well suited for datasets in which local enrichment is sharp and background is minimal.

Accordingly, we performed peak calling on the raw fragment-level BedGraph files generated in Step 5, rather than on the normalized browser tracks.

---

## Input Strategy

As described in Step 5, two different signal representations were generated from the same aligned BAM files:

1. **CPM-normalized BigWig tracks** for browser visualization.
2. **Raw fragment-level BedGraph tracks** for peak calling.

For SEACR, we used *only* the second type of file: the exact, unsmoothed, non-normalized fragment BedGraph. 

This distinction is essential. Browser tracks are optimized for human interpretation, whereas SEACR requires a mathematically faithful representation of the underlying fragment pileup landscape.

---

## Execution Command

We processed the machine-readable BedGraph files using a Slurm array script. During this step, we explicitly excluded IgG and nAb control samples from the execution list, since these files were not used as independent peak-calling targets in the present workflow.

```bash
# Define paths
bg_dir="path/to/seacr_bedgraph"
out_dir="path/to/seacr_stringent_001"
seacr_exec="path/to/SEACR_1.3.sh"

mkdir -p "$out_dir"

# 1. Dynamically identify valid BedGraph files, excluding IgG/nAb controls
BG_LIST=($(find "$bg_dir" -maxdepth 1 -name "*.seacr.bedgraph" | grep -viE "IgG|nAb" | sort))

# 2. Select the current sample based on Slurm Array ID
current_bg=${BG_LIST[$((SLURM_ARRAY_TASK_ID-1))]}
base_name=$(basename "$current_bg" .rmdup.seacr.bedgraph)
output_prefix="${out_dir}/${base_name}.01"

# 3. Execute SEACR
bash "$seacr_exec" \
    "$current_bg" \
    0.01 \
    non \
    stringent \
    "$output_prefix"
```

---

## Parameter Rationale

The choice of SEACR parameters strongly influences the balance between sensitivity and specificity. In this project, we adopted a control-free, stringent calling strategy.

### `0.01` threshold
Instead of supplying an external control BedGraph, we used a numeric threshold of `0.01`. In this mode, SEACR retains the top 1% of enriched regions ranked by total signal intensity (area under the curve, AUC). This provides a conservative and reproducible way to define enriched regions without relying on a potentially unstable control track. This thresholding strategy was chosen to minimize false positives while still preserving strong biologically meaningful enrichment.



### `non` mode
Because we used a numeric threshold rather than a control BedGraph as the second argument, the workflow effectively operates without a matched control track for empirical threshold definition. In this setting, we intentionally avoided direct IgG/nAb-based thresholding. This was an important design choice for our dataset. Across batches, IgG/nAb controls were highly sparse and not always uniformly structured, making them less suitable as direct denominators for peak calling. Rather than introducing inconsistency through variable control behavior, we adopted a uniform control-free SEACR strategy across comparable target samples.

### `stringent` mode
We used SEACR in stringent mode to obtain a conservative, high-confidence set of enriched regions. Compared with relaxed mode, stringent calling produces tighter and more selective peak calls, which is desirable for downstream construction of a robust Common Peak Set (CPS). Because the CPS serves as the foundation for subsequent quantification and differential analysis, we prioritized specificity and reproducibility over maximal sensitivity at this stage.

---

## Why IgG/nAb Controls Were Not Used Directly

In conventional ChIP-seq workflows, input DNA or IgG controls are often incorporated directly into peak calling. However, for this CUT&Tag dataset, we intentionally did not use IgG/nAb BedGraphs as SEACR control inputs for several reasons:

* **Extreme sparsity:** CUT&Tag control libraries often contain very low signal and highly sparse coverage profiles.
* **Inconsistent structure across batches:** Because this project was generated across multiple experimental batches and different negative control types were present (IgG in some batches and nAb in others), direct control-based thresholding would have introduced additional heterogeneity.
* **Need for a consistent calling framework:** For downstream merging into CPS and cross-sample comparison, it was more important to apply a stable and internally consistent peak-calling strategy across all target samples than to use batch-variable sparse controls.

> **Note:** It is important to note that this does not mean IgG/nAb controls were biologically irrelevant. Rather, in this workflow they were treated primarily as background reference tracks for QC and visualization, not as formal control tracks for SEACR peak calling.

---

## Output

The output of this step is a `.stringent.bed` file for each biological sample, containing the genomic coordinates of all high-confidence enriched regions identified by SEACR.

These individual peak files are then carried forward into the next module, where they are merged across samples to construct the Common Peak Set (CPS) used for downstream counting, normalization, and differential analysis.

### Key Take-Home Message

SEACR peak calling in this workflow was performed on raw fragment-level BedGraph files, not on normalized browser tracks. We used a control-free, stringent, numeric-threshold strategy (`0.01`, `non`, `stringent`) to obtain a robust and internally consistent set of per-sample peaks suitable for downstream CPS construction.
