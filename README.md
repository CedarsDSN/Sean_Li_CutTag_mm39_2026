# Sean_Li_CutTag_mm39_2026
## Documentation
Project documentation: https://cedarsdsn.github.io/Sean_Li_CutTag_mm39_2026/

## Overview

This repository contains the **current maintained CUT&Tag analysis workflow** for the Sean Li project, updated for the **mm39** reference framework and the 2026 analysis architecture.

The current pipeline is built around a **SEACR → CPS → master count matrix → MAnorm2** framework, with separate signal products for:

- **browser visualization** (`BigWig`)
- **peak calling** (`BedGraph`)
- **formal differential enrichment analysis** (`MAnorm2`)

This repository is intended to serve as the main entry point for collaborators reviewing the current analysis, documentation, workflow logic, and project-level outputs.

---

## Project Summary

This project investigates chromatin-level differences across multiple biological contexts using CUT&Tag profiling of histone marks in mouse samples.

The study includes comparisons involving:

- **sex**
- **tissue context**
- **genotype / treatment-related conditions**
- **multiple CPS-defined comparison groups**

The primary histone marks analyzed in the current workflow include:

- **H3K4me1**
- **H3K27ac**
- **H3K27me3** *(available in selected sample groups / analysis branches where applicable)*

The main goal of the current analysis framework is to identify and interpret **differentially enriched chromatin regions** across biologically defined comparisons using a reproducible, metadata-driven pipeline.

---

## Current Analysis Framework

The current workflow follows the architecture below:

1. **Read preprocessing**
   - adapter trimming
   - read-level QC

2. **Alignment and BAM processing**
   - alignment to mm39
   - duplicate removal
   - mapping QC
   - BAM sorting / indexing

3. **Dual-track signal generation**
   - **CPM-normalized BigWig** for browser visualization
   - **raw fragment BedGraph** for SEACR peak calling

4. **SEACR peak calling**
   - stringent peak calling in control-free numeric-threshold mode
   - target-mark sample peak definition

5. **Consensus Peak Set (CPS) generation**
   - metadata-driven, marker-specific consensus interval construction

6. **Master count matrix generation**
   - fragment-level quantification across all relevant samples within each CPS
   - count + occupancy matrix generation

7. **Differential enrichment analysis**
   - comparison-specific filtering
   - conservative normalization-anchor selection
   - mean-variance fitting with MAnorm2
   - annotated differential result tables

8. **Project-level QC and result aggregation**
   - summary tables
   - chromosome distribution summaries
   - PCA on CPS-level master matrices

9. **Workflow documentation and appendix**
   - step-by-step methods documentation
   - project-specific methodological discussions
   - design-decision appendix

---

## Documentation

This repository includes expanded project documentation describing both the workflow and the major methodological decisions behind it.

### Documentation topics include

- reference preparation
- preprocessing and alignment
- signal generation
- SEACR peak calling
- CPS generation
- master count matrix generation
- MAnorm2 differential analysis
- genomic annotation
- PCA and result organization
- methodological appendix and design decisions

If the static HTML documentation has been built locally, start with:

```text
cut_tag_docs/build/html/index.html
