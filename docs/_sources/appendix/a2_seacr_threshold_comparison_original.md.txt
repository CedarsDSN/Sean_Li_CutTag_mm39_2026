# A2. Comparison of SEACR Thresholds: 0.01 vs 0.005 vs 0.05

## Overview

SEACR peak calling in this project was performed using numeric-threshold, control-free mode. Because the choice of threshold directly affects peak number, peak stringency, and downstream CPS structure, multiple thresholds were considered and compared.

This section summarizes the rationale for evaluating `0.01`, `0.005`, and `0.05`, and explains why threshold choice matters not only for peak calling itself but also for all later stages of the workflow.

---

## Why Threshold Comparison Was Necessary

In a SEACR workflow based on numeric thresholding, the threshold affects:

- how many enriched regions are retained
- how permissive or conservative the peak set becomes
- how broad the downstream consensus feature universe may become
- how strongly noise versus sensitivity is favored

Because the CPS and master matrix steps depend directly on per-sample peak calls, threshold choice propagates into:

- CPS size
- occupancy patterns
- master count matrix structure
- MAnorm2 filtering and normalization
- apparent differential peak burden

For this reason, threshold selection was treated as a project-level design decision rather than a minor parameter tweak.

---

## Practical Interpretation of the Tested Thresholds

### `0.005`

This threshold is more permissive than `0.01`.

Expected behavior:

- more peaks retained
- greater sensitivity
- higher risk of weak or noisy regions entering downstream CPS construction
- more complex and potentially less stable occupancy structure

Potential advantage:
- may recover weaker biologically relevant regions

Potential drawback:
- can inflate feature-space size and noise burden

### `0.01`

This threshold represents an intermediate, moderately conservative setting.

Expected behavior:

- strong signal regions retained
- lower risk of weak background regions entering the final peak universe
- suitable balance between sensitivity and specificity for downstream CPS construction

In this project, `0.01` served as the principal candidate because it provided a practical balance between retaining biologically meaningful enrichment and avoiding over-expansion of the consensus feature space.

### `0.05`

This threshold is more stringent in practice.

Expected behavior:

- fewer peaks retained
- higher confidence per retained region
- greater specificity
- greater risk of excluding real but moderate-strength enrichment

Potential advantage:
- cleaner peak set with lower false-positive burden

Potential drawback:
- may become too restrictive for downstream comparative analysis if true features are removed early

---

## Why Threshold Choice Matters Downstream

The effect of SEACR threshold choice does not stop at peak calling. Different thresholds alter downstream analysis in several ways.

### 1. CPS construction

More permissive thresholds increase the number of intervals fed into the union-and-merge process, which can enlarge the CPS and potentially admit weaker regions.

### 2. Occupancy behavior

If weaker peaks are called at permissive thresholds, the occupancy matrix may become less stringent and more difficult to interpret biologically.

### 3. Differential testing burden

Larger CPS or noisier occupancy patterns increase the number of candidate intervals entering quantification and, indirectly, the multiple-testing burden.

### 4. Biological interpretability

An overly permissive threshold may retain more intervals, but not all retained intervals will be equally convincing as true regulatory signals.

---

## Raw BedGraph vs Scaling-Factor-Adjusted BedGraph

Another related question was whether SEACR should operate on:

- raw fragment pileup BedGraphs
- or scaling-factor-adjusted BedGraphs

The project ultimately favored raw fragment BedGraphs as the primary SEACR input.

### Why raw BedGraph was preferred

- SEACR is designed to evaluate the empirical structure of fragment pileup signal
- the project’s main peak-calling logic was intentionally separated from later normalization logic
- applying external scaling before SEACR would mix signal definition with downstream normalization assumptions
- retaining raw BedGraph input preserved a cleaner distinction between peak calling and formal differential quantification

Thus, threshold evaluation was performed in the context of raw fragment-level SEACR input, not rescaled browser-style coverage tracks.

---

## Project-Level Interpretation

The threshold comparison was not intended to identify a universally “correct” SEACR threshold for all CUT&Tag datasets. Instead, it was used to determine which setting best fit the current project’s balance of:

- sensitivity
- specificity
- CPS stability
- downstream differential-analysis interpretability

The final selected threshold was therefore chosen as a workflow design decision grounded in the behavior of this dataset, not as a universal rule.

---

## Key Take-Home Message

SEACR threshold choice is a workflow-defining decision because it directly affects peak stringency, CPS structure, occupancy behavior, and downstream differential analysis. In this project, comparison of `0.01`, `0.005`, and `0.05` was used to identify a practical balance between sensitivity and specificity while preserving a stable feature universe for later quantification and testing.
