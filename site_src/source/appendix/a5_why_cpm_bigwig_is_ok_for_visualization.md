# A5. Why CPM-Normalized BigWig Tracks Are Acceptable for Visualization

## Overview

A recurring methodological question in this project was whether browser tracks used for IGV visualization should undergo the same normalization logic used in formal differential analysis. In particular, because the differential-enrichment framework ultimately relied on CPS-based quantification and MAnorm2 normalization, it was necessary to justify why browser tracks generated using simple CPM normalization were still acceptable for visual interpretation.

The conclusion of this project was that CPM-normalized BigWig tracks were appropriate for **visualization**, even though they were not the normalization backbone for formal differential inference.

This section explains why.

---

## The Core Distinction: Visualization vs Formal Inference

The most important point is that browser visualization and formal differential analysis do **not** have the same goal.

### Browser visualization is intended to support:

- qualitative inspection of local signal shape
- visual comparison of track height at specific loci
- replicate consistency checking
- figure generation and IGV screenshots
- rapid interpretation of candidate regions

### Formal differential analysis is intended to support:

- feature-level statistical comparison
- comparison-specific normalization
- reproducibility-aware filtering
- mean-variance modeling
- significance testing

Because the goals differ, the normalization requirements also differ.

The browser layer only needs a signal representation that is:

- visually interpretable
- reasonably comparable across libraries
- stable enough for locus-level inspection

It does **not** need to encode the entire formal statistical normalization framework.

---

## Why CPM Was a Reasonable Choice

In this project, BigWig tracks were generated using CPM normalization because CPM provides a straightforward and interpretable way to account for sequencing-depth differences across libraries.

Practical advantages of CPM include:

- simple library-size normalization
- easy interpretation of relative track height
- broad compatibility with browser-based visualization tools
- suitability for qualitative comparison across multiple samples

For the purpose of IGV-based inspection, these properties were sufficient.

---

## Why CPM Tracks Do Not Need To Match MAnorm2 Normalization Exactly

A common concern is that browser tracks should use the same normalization logic as the formal differential analysis. In this project, that was intentionally **not** required.

The reason is that the browser track and the differential model answer different questions.

### The browser asks:

> what does the signal look like at this locus?

### The differential model asks:

> after filtering and comparison-specific normalization, is this region statistically different between groups?

These are related questions, but they are not identical. Therefore, it is methodologically acceptable for the browser layer and the differential-analysis layer to use different normalization logic, as long as each is appropriate for its purpose.

In this project:

- **CPM BigWigs** were used for qualitative visualization
- **MAnorm2** was used for formal comparison-specific normalization and differential testing

This division of labor was deliberate.

---

## Why CPM Was Sufficient for IGV in This Project

### 1. Browser tracks were not used as the substrate for statistical testing

The project did **not** use BigWig tracks as the input for differential calling or enrichment statistics. Formal inference was based on:

- CPS-defined feature spaces
- master count matrices
- occupancy-aware filtering
- MAnorm2 normalization and differential testing

Because the browser tracks did not carry inferential responsibility, CPM was sufficient.

### 2. Browser tracks were meant to support human interpretation

The goal of the BigWig track was not to establish final quantitative truth, but to let a reviewer visually inspect:

- whether signal is visibly present
- whether a mark appears stronger in one condition than another
- whether replicates look coherent
- whether candidate loci are biologically plausible

For these tasks, CPM-normalized tracks were appropriate.

### 3. CPM preserved simplicity in the browser layer

One of the strengths of CPM is that it keeps browser interpretation simple. In a large project with many samples and many loci, this simplicity matters. More complicated scaling logic can make visual review harder to explain without necessarily improving local interpretability.

---

## Why ChIPseqSpikeInFree Scaling Was Not Forced Into BigWig Visualization

The project also considered whether browser tracks should be rescaled using `ChIPseqSpikeInFree`-derived scaling factors. This was ultimately not adopted as the default strategy.

The main reasons were:

- browser tracks were not the formal inferential layer
- `ChIPseqSpikeInFree` scaling factors were context dependent across CPS groups
- scaling-factor inconsistency made it difficult to apply one universal project-wide browser-scaling rule
- CPM already provided a stable and interpretable baseline for IGV viewing

Thus, the project did not require browser tracks to carry the same scaling complexity that was being explored methodologically elsewhere.

---

## Why the Collaborator Concern Was Understandable but Not Fatal

A reasonable concern from a collaborator is that CPM only accounts for library size and does not incorporate more sophisticated normalization, such as MAnorm2 or ChIPseqSpikeInFree-style scaling. That concern is valid in principle if the BigWig tracks were being used as the primary basis for formal quantitative conclusions.

However, in this project, that was **not** their role.

The browser tracks were used to support:

- visual review
- local interpretation
- qualitative consistency checks

while formal conclusions were derived from a separate downstream framework.

Therefore, the use of CPM-normalized BigWigs did not undermine the formal statistical analysis. Instead, it reflected the intentional separation between:

- **human-readable browser visualization**
- **formal comparison-specific differential modeling**

---

## Relationship to the Dual-Track Strategy

This choice is tightly connected to the project’s broader dual-track signal-generation design:

- **BigWig tracks** for browser visualization
- **raw fragment BedGraphs** for SEACR peak calling

Under that design:

- visualization tracks were optimized for readability
- peak-calling tracks were optimized for mathematical faithfulness
- differential analysis was handled separately through CPS/master-matrix/MAnorm2 logic

Thus, CPM-normalized BigWig tracks were one part of a larger workflow architecture in which each signal layer had a distinct purpose.

---

## Key Take-Home Message

CPM-normalized BigWig tracks were acceptable in this project because they were used for **visualization**, not for formal statistical inference. Their purpose was to provide simple, interpretable, library-size-adjusted browser tracks for IGV-based inspection of local signal patterns.

Formal differential conclusions were derived from the separate CPS–master matrix–MAnorm2 framework. Because visualization and inferential analysis were intentionally separated, CPM was an appropriate and sufficient normalization strategy for the browser layer.
