# Step 11: Result Aggregation and CPS-Based File Organization

## Overview

After all comparison-specific MAnorm2 analyses have completed, the resulting output files must be consolidated into project-level summary tables and then organized into CPS-specific directories for easier downstream review.

This step performs two tasks:

1. **Aggregation of comparison-level result summaries** into three master CSV files
2. **Automatic CPS-based file organization** of comparison-specific outputs

Because each comparison generates its own summary, filter-statistics, and chromosome-distribution files, this aggregation step creates a reproducible project-wide overview while preserving the original per-comparison outputs.

---

## Execution Command

```bash
cd /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/manorm2_master_results/ || exit 1

rm -f All_Comparisons_Summary.csv All_Filter_Stats.csv All_Chromosome_Dist.csv

first_summary=$(ls CPS*_Comp*_summary.csv | head -n 1)
head -n 1 "$first_summary" > All_Comparisons_Summary.csv
awk 'FNR>1' CPS*_Comp*_summary.csv | sort -t, -k1,1n >> All_Comparisons_Summary.csv

first_filter=$(ls CPS*_Comp*_filter_stats.csv | head -n 1)
head -n 1 "$first_filter" > All_Filter_Stats.csv
awk 'FNR>1' CPS*_Comp*_filter_stats.csv | sort -t, -k1,1n >> All_Filter_Stats.csv

first_dist=$(ls CPS*_Comp*_dist.csv 2>/dev/null | head -n 1)
if [ -n "$first_dist" ]; then
    head -n 1 "$first_dist" > All_Chromosome_Dist.csv
    awk 'FNR>1' CPS*_Comp*_dist.csv | sort -t, -k1,1n >> All_Chromosome_Dist.csv
fi

for f in CPS*_Comp*; do
    [ -e "$f" ] || continue
    cps=$(echo "$f" | cut -d'_' -f1)
    mkdir -p "$cps"
    mv "$f" "$cps"/
done
```

---

## Aggregated Output Files

This step generates up to three master summary files in the root `manorm2_master_results/` directory:

### 1. `All_Comparisons_Summary.csv`

This file combines all comparison-level summary tables into one project-wide table. It records high-level differential-analysis results for each comparison, including:

- comparison identifier
- CPS identifier
- histone marker
- group names
- total number of significant regions
- counts of regions higher in each group
- top genes
- annotation distribution summaries

This table is useful for rapid screening across all completed comparisons.

### 2. `All_Filter_Stats.csv`

This file combines all per-comparison filtering diagnostics into a single master table. It records:

- group identities
- matched count and occupancy columns
- total intervals before filtering
- number of intervals retained after each filtering stage
- basic filtering thresholds
- occupancy and variance thresholds
- normalization-anchor counts and fractions
- final mean-variance fitting method used

This table provides a reproducible audit trail of the comparison-specific filtering and normalization logic used in Step 9.

### 3. `All_Chromosome_Dist.csv`

If chromosome-direction summary files were generated, they are merged into a single chromosome-level overview table. This file records, for each comparison:

- chromosome name
- count of regions higher in Group 2
- count of regions higher in Group 1
- comparison identifier
- CPS
- histone marker
- comparison name

This file is particularly useful for quickly identifying chromosome-biased enrichment patterns, including sex-chromosome effects.

---

## CPS-Based File Organization

After the aggregated summary tables are created, all comparison-specific files matching the pattern `CPS*_Comp*` are moved into directories grouped by CPS identifier.

For example:

- `CPS1_Comp1_...`
- `CPS1_Comp2_...`

are moved into:

- `CPS1/`

This organization improves project readability by grouping all outputs associated with the same CPS into a single folder.

---

## Key Design Rationale

### 1. Centralized project-level summaries

Comparison-specific files are useful for detailed inspection, but they are inconvenient for global review across dozens of analyses. Aggregating the outputs into three master CSV files provides an immediate project-level summary without modifying the original comparison-level results.

### 2. Preservation of per-comparison provenance

This step does not overwrite or compress the original comparison-specific outputs. Instead, it preserves them exactly as generated and simply reorganizes them into CPS-based subdirectories.

### 3. Cleaner downstream navigation

By grouping all `CPS*_Comp*` files into their corresponding CPS folders, the result directory becomes much easier to navigate. This is especially useful when reviewing multiple histone markers and many related comparisons within the same CPS framework.

---

## Output Structure

After this step, the result directory contains:

### Root-level project summaries
- `All_Comparisons_Summary.csv`
- `All_Filter_Stats.csv`
- `All_Chromosome_Dist.csv` (if applicable)

### CPS-specific subdirectories
- `CPS1/`
- `CPS2/`
- `CPS3/`
- ...

Each CPS directory contains the original comparison-level files for that CPS, including result tables, summaries, filter statistics, and chromosome-distribution outputs.

---

## Key Take-Home Message

This step converts a large collection of comparison-level MAnorm2 outputs into a structured result system consisting of:

1. project-level aggregate summary tables
2. CPS-based organized comparison folders

Together, these outputs make the full CUT&Tag differential analysis more auditable, easier to review, and more manageable for downstream interpretation.

