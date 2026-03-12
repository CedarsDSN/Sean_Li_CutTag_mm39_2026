# B1. Why the Workflow Moved From Individual Comparison Count Matrices to a Master Count Matrix Design

## Overview

One of the most important architectural changes in this project was the transition from **individual comparison count matrices** to a **CPS-level master count matrix** design.

At first, it was natural to think in a comparison-centered way: for each pairwise or grouped contrast, generate a dedicated count matrix containing only the relevant samples and then perform downstream differential analysis directly. However, as the project expanded to include many comparisons, shared sample groups, multiple histone marks, and repeated reuse of the same biological samples across different analytical contexts, that strategy became increasingly inefficient and difficult to maintain.

The final workflow therefore moved to a metadata-driven master matrix design in which each CPS defines a shared feature universe, all relevant samples are quantified once into a single matrix, and individual comparisons are extracted downstream as needed.

This section explains why that transition occurred and why it became an important improvement to the overall pipeline.

---

## Why Individual Comparison Matrices Seemed Reasonable at First

The original appeal of a comparison-specific matrix design was simplicity.

Conceptually, it allowed the workflow to proceed as:

1. define the samples for one comparison  
2. build a comparison-specific interval set  
3. quantify only those samples  
4. run differential analysis immediately  

For a small project with very few comparisons, this can work. It feels direct, local, and easy to understand because each matrix corresponds to one explicit contrast.

For that reason, the project initially considered or used an individual-comparison strategy in earlier stages.

---

## Why the Individual Comparison Strategy Became Limiting

As the project matured, several practical and methodological problems became clear.

### 1. Repeated quantification of the same samples

Many comparisons in this project reused the same biological samples across multiple related contrasts.

Under an individual-comparison matrix design, this means the same sample would be:

- re-quantified multiple times
- re-packaged into multiple partially overlapping matrices
- repeatedly processed in slightly different analytical contexts

This created unnecessary redundancy in both computation and file management.

### 2. Feature-space inconsistency across comparisons

A more serious issue was that separate comparison-specific matrices do not naturally live in the same feature space.

If each comparison defines its own interval universe independently, then different comparisons may be testing slightly different genomic coordinates even when they involve overlapping sample sets or related biology.

This makes it harder to answer questions such as:

- how do two related comparisons differ?
- is a locus absent because it is biologically absent, or because it never entered that comparison’s matrix?
- can summary results be meaningfully compared across comparisons if the underlying tested feature space is not shared?

In a project with many related contrasts, this lack of feature-space consistency becomes a major interpretability problem.

### 3. Workflow management became increasingly cumbersome

This project included:

- many CPS groups
- many pairwise or grouped comparisons
- repeated sample reuse
- multiple histone markers
- downstream PCA, QC, summary, and annotation steps

Under this level of complexity, individual comparison matrices became awkward to manage. File naming, tracking, recomputation, and result comparison all became more difficult because each comparison carried its own partially independent quantitative universe.

### 4. Metadata-driven automation was harder to scale

A major strength of the final workflow is that it is metadata driven. That logic becomes much cleaner when the pipeline can say:

- build one CPS
- quantify all relevant samples once
- extract comparison-specific columns later

rather than:

- dynamically rebuild a separate matrix for every comparison

The latter is much harder to maintain cleanly and reproducibly at scale.

---

## Why the Master Matrix Design Solved These Problems

The project ultimately moved to a CPS-level master matrix strategy because it provided a much cleaner quantitative backbone.

In this design:

- each **CPS** defines a shared interval universe
- all relevant samples for that CPS are quantified once
- both **count** and **occupancy** information are stored in the same matrix
- downstream comparisons simply select the appropriate subset of columns from that shared matrix

This resolved several problems simultaneously.

### 1. One quantification step per CPS, not per comparison

Instead of repeatedly rebuilding matrices, the workflow quantifies each sample once within a given CPS context. This reduced redundancy and made sample-level quantification more stable and auditable.

### 2. Shared feature space within a CPS

All comparisons within the same CPS now operate on the same interval universe. This makes downstream comparison more meaningful because differences between comparisons are less likely to reflect hidden differences in the tested feature set.

### 3. Better support for downstream filtering and normalization

The master matrix made it much easier to implement the later MAnorm2 workflow, because Step 9 could simply:

- read the CPS-level matrix
- extract the group-specific columns
- apply comparison-specific filtering
- run comparison-specific normalization and differential testing

This created a clean separation between:

- **quantification infrastructure**
- **comparison-specific statistical analysis**

### 4. Better support for PCA and QC

A CPS-level master matrix also naturally supports:

- CPS-level PCA
- global sample-structure inspection
- occupancy-aware QC
- consistent summary-table generation

These tasks are much harder to implement elegantly if every comparison exists as an isolated matrix.

---

## Why This Was Especially Important in This Project

This design change was not only about computational tidiness. It was especially important because this project needed to integrate:

- SEACR-derived CPS feature definition
- occupancy-aware downstream filtering
- MAnorm2 comparison-specific normalization
- per-CPS PCA
- large-scale summary-table aggregation
- multiple histone-mark analyses

All of these tasks become more coherent when a CPS-level master matrix serves as the central quantitative substrate.

In other words, the master matrix was not just a convenience. It became the structural core that allowed the entire downstream workflow to scale cleanly.

---

## Relationship to the Metadata-Driven Design

The shift to a master matrix design also aligned naturally with the broader metadata-driven philosophy of the project.

The metadata file already defined:

- CPS identity
- group structure
- histone marker
- sample membership

Under the final design, the workflow could use metadata in two stages:

1. build the CPS-level master matrix once  
2. use the same metadata again to define individual comparisons from that matrix  

This is much more elegant than rebuilding comparison-specific quantification products from scratch for every contrast.

---

## What the Master Matrix Does *Not* Mean

Moving to a master matrix does **not** mean that all later statistical analyses became “global” or non-specific.

The workflow still preserved comparison specificity where it mattered:

- filtering was applied per comparison
- normalization anchors were selected per comparison
- mean-variance fitting was performed per comparison
- differential testing was performed per comparison

Thus, the master matrix unified **quantification infrastructure**, not the inferential logic itself.

This distinction was important: the project wanted shared quantification, but still needed comparison-specific statistical modeling.

---

## Key Take-Home Message

The workflow moved from individual comparison count matrices to a CPS-level master count matrix design because the project had become too complex for isolated comparison-specific quantification to remain efficient, consistent, and interpretable.

The master matrix design provided:

- less redundant quantification
- a shared feature universe within each CPS
- cleaner metadata-driven automation
- better support for PCA, QC, and summary reporting
- a stable quantitative backbone for downstream comparison-specific MAnorm2 analysis

As a result, the master matrix became a central structural improvement in the final CUT&Tag workflow.
