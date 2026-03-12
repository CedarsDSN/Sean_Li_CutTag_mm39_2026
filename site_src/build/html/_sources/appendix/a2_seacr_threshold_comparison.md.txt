# A2. Comparison of SEACR Thresholds: 0.01 vs 0.005 vs 0.05

## Overview

SEACR peak calling in this project was performed in numeric-threshold, control-free mode. Because the choice of threshold directly influences peak number, peak stringency, downstream CPS structure, and ultimately the feature space used for quantification, the threshold parameter was treated as a major workflow design choice rather than a minor tuning detail.

In practice, the project focused on comparing three thresholds:

- `0.01`
- `0.005`
- `0.05`

This section summarizes why these thresholds were compared, how they differ conceptually, and why the final SEACR setting was chosen in the context of the broader CUT&Tag workflow.

---

## Why Threshold Comparison Was Necessary

In a SEACR workflow based on numeric thresholding, the threshold affects much more than the size of the peak set.

It can influence:

- how permissive or conservative peak calling becomes
- how many weak regions enter downstream consensus construction
- how stable or unstable the occupancy matrix becomes
- how large the CPS feature universe grows
- how much noise is propagated into master matrix generation and MAnorm2 testing

Because this project used SEACR peak calls to define the CPS and then built all later quantification on top of that CPS, threshold choice had consequences well beyond the peak-calling step itself.

---

## Conceptual Meaning of the Tested Thresholds

Although the exact numerical behavior of SEACR depends on the signal structure of the dataset, the tested values can be interpreted approximately as follows.

### `0.005`

This threshold is the most permissive among the three tested settings.

Expected practical behavior:

- more peaks retained
- greater sensitivity
- more weak or borderline regions entering downstream CPS construction
- higher risk of carrying low-confidence intervals into quantification and occupancy tracking

Potential benefit:
- may recover weaker true biological regions

Potential risk:
- enlarges the feature universe and increases the chance that noisy or unstable loci enter later analysis

---

### `0.01`

This threshold represents an intermediate, moderately conservative setting.

Expected practical behavior:

- retains strong and moderate target-mark regions
- avoids some of the weakest background-like intervals admitted by more permissive settings
- produces a feature universe that is broad enough for comparison while still reasonably controlled

In this project, `0.01` served as the key candidate because it offered a practical balance between sensitivity and specificity for CPS construction and downstream differential analysis.

---

### `0.05`

This threshold is the most stringent among the three tested values.

Expected practical behavior:

- fewer peaks retained
- stronger emphasis on high-confidence enrichment
- cleaner but smaller feature universe
- higher risk of excluding real but moderate-strength biological signal

Potential benefit:
- reduces weak-feature burden

Potential risk:
- may become too restrictive for a project intended to support multiple comparative analyses across CPS groups

---

## Why Threshold Choice Matters Downstream

A SEACR threshold is not isolated to Step 6. It changes the behavior of later stages in several important ways.

### 1. CPS construction

A more permissive threshold sends more intervals into the union-and-merge stage, which can enlarge the CPS and make the consensus feature space less selective.

A more stringent threshold keeps the CPS smaller and cleaner, but risks excluding real signal early.

### 2. Occupancy patterns

Because occupancy is defined using original peak calls, threshold choice directly affects whether a CPS interval is recorded as occupied or unoccupied in each sample.

Thus, threshold changes influence not only the CPS interval set, but also the occupancy matrix used later in filtering and normalization.

### 3. Master matrix burden

A larger, more permissive CPS increases the number of intervals entering quantification, which can increase:

- storage burden
- matrix complexity
- the number of weakly informative rows
- downstream multiple-testing burden

### 4. MAnorm2 filtering and statistical testing

If more weak or unstable intervals enter the master matrix, later filters must work harder to remove them. In some cases, permissive peak calling can shift the burden of quality control downstream rather than solving it at the peak-calling stage.

---

## Raw BedGraph vs Scaling-Factor-Adjusted BedGraph

A related methodological question was whether SEACR should operate on:

- raw fragment pileup BedGraphs
- or scaling-factor-adjusted BedGraphs

This question became especially relevant when considering ChIPseqSpikeInFree-like scaling or other global normalization ideas.

### Why raw BedGraph was preferred

In this project, raw fragment-level BedGraphs were retained as the preferred SEACR input for several reasons:

1. **SEACR was intended to see the empirical fragment pileup directly**  
   The project treated peak calling as a signal-definition step rather than as a normalization-driven step. Raw fragment BedGraphs therefore better preserved the intended peak-calling substrate.

2. **Peak calling was intentionally separated from later formal normalization**  
   The main workflow was designed so that:
   - raw fragment BedGraphs define peaks
   - CPS / master matrices define the quantitative feature space
   - MAnorm2 handles differential normalization and testing

   Using adjusted BedGraphs for SEACR would blur the boundary between peak definition and formal comparative normalization.

3. **Scaling-factor adjustment at the SEACR stage would impose another layer of model dependence**  
   If externally adjusted BedGraphs were used for peak calling, then the peak universe itself would become dependent on that scaling choice, not just the later quantitative interpretation.

For these reasons, the project treated raw fragment BedGraphs as the cleaner and more interpretable SEACR input.

---

## Why the Final Setting Was Chosen

The final SEACR threshold was chosen not because one threshold is universally correct for all CUT&Tag projects, but because one setting provided the most practical balance for this dataset and this workflow.

The chosen setting was favored because it offered a reasonable compromise between:

- retaining biologically meaningful enrichment
- avoiding excessive admission of weak background-like intervals
- preserving a manageable CPS feature universe
- supporting stable downstream occupancy behavior
- aligning with the project’s broader CPS–master matrix–MAnorm2 architecture

In other words, the final setting was selected as a **workflow-compatible threshold**, not just a peak-count optimization.

---

## Relationship to Other Workflow Components

This threshold discussion is tightly connected to several other methodological decisions in the project:

- why SEACR used raw fragment BedGraphs instead of browser-style normalized tracks
- why negative-control libraries were excluded from target-mark CPS construction
- why browser visualization and peak calling were treated as separate signal layers
- why MAnorm2 filtering and normalization were kept downstream of CPS construction rather than imposed during peak calling

Thus, the threshold comparison should be understood as part of the larger workflow architecture rather than as a standalone parameter sweep.

---

## Key Take-Home Message

SEACR threshold choice has direct consequences for peak stringency, CPS size, occupancy behavior, and downstream differential analysis. In this project, comparison of `0.01`, `0.005`, and `0.05` was used to identify a threshold that balanced sensitivity and specificity while preserving a stable, interpretable feature universe for the later CPS–master matrix–MAnorm2 workflow.

Equally important, this comparison was evaluated in the context of **raw fragment BedGraph input**, because peak calling and formal normalization were intentionally kept as separate analytical layers in the final design.
