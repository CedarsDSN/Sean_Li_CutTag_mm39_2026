# A4. Why Browser Visualization and Peak Calling Require Two Different Signal Tracks

## Overview

One important methodological decision in this project was to generate **two different signal products** from the same aligned BAM files:

1. a browser-oriented normalized BigWig track for visualization  
2. a raw fragment-level BedGraph track for SEACR peak calling  

At first glance, this may seem redundant. However, the project concluded that browser visualization and peak calling impose fundamentally different technical demands on the signal representation. As a result, using a single shared track type for both purposes would have forced an undesirable compromise.

This section explains why the dual-track strategy was necessary and why it improved the overall workflow.

---

## The Core Problem: Human Interpretation and Peak Calling Do Not Need the Same Signal

Although both browser inspection and peak calling begin from the same aligned reads, they ask different questions.

### Browser visualization asks:

- what does the locus look like to a human reviewer?
- do replicates appear visually consistent?
- is one condition obviously stronger than another at a candidate region?
- is this locus worth further attention?

### Peak calling asks:

- where does the algorithm define enriched regions?
- where are the signal boundaries?
- how should contiguous versus separated fragments be interpreted?
- which regions should enter the downstream feature universe?

Because these questions are different, the optimal signal representation is different as well.

---

## Why Browser Visualization Needed a Human-Readable Track

For IGV and related browser inspection, the project needed tracks that were:

- easy to load
- visually interpretable
- reasonably comparable across libraries
- stable enough for locus-level inspection

This is why the browser layer used normalized BigWig tracks, specifically CPM-normalized signal.

A browser track should make it easy to inspect:

- overall track shape
- relative local height
- whether peaks are obviously present
- replicate agreement
- locus-specific biological plausibility

For those purposes, a visualization-friendly track is more important than exact preservation of every raw fragment boundary.

---

## Why Peak Calling Needed a Machine-Readable Track

SEACR operates on the empirical structure of fragment pileup, not on a browser-optimized approximation. For that reason, the project generated raw fragment-level BedGraphs separately for peak calling.

These BedGraphs preserved:

- exact fragment-derived signal blocks
- local zero-signal gaps
- unsmoothed peak boundaries
- the native fragment structure needed by SEACR for threshold-based region definition

This is important because peak calling is not merely about seeing where the signal is “high.” It also depends on how enriched regions are segmented and where boundaries are placed.

Thus, the project treated SEACR input as a **signal-definition substrate**, not simply as a visualization product in a different file format.

---

## Why a Single Shared Track Type Would Have Been a Bad Compromise

The project explicitly rejected the idea that one signal representation should serve both browser inspection and SEACR.

### 1. Browser tracks are often normalized for readability

Browser tracks were intended to support visual comparison across libraries. That makes normalization such as CPM appropriate. But SEACR peak calling was intentionally based on raw fragment-level BedGraph input, not normalized browser signal.

### 2. Browser tracks may be binned or smoothed

Even mild binning or smoothing can improve browser readability and reduce noise. But those same operations can blur the fine local structure that a peak caller needs in order to define enriched intervals correctly.

### 3. Peak calling should remain separate from later normalization logic

The project’s workflow architecture deliberately separated:

- signal definition for peak calling
- feature-space construction
- downstream comparative normalization
- browser-level visualization

If a single shared track had been forced into all of these roles, the analytical layers would have become harder to distinguish and justify.

---

## Why the BigWig Track Was Not Reused for SEACR

A common temptation is to say: if a BigWig already exists, why not convert or reuse that signal for peak calling?

In this project, that was intentionally avoided for several reasons:

- the BigWig was created for browser readability, not formal peak definition
- CPM-normalized browser signal was not meant to define the CPS
- browser-oriented processing may alter local signal structure
- the project wanted SEACR to see the raw fragment pileup directly

Thus, even though the browser and SEACR tracks originated from the same BAM files, they were intentionally treated as different analytical products.

---

## Why This Separation Improved Workflow Clarity

The dual-track design made the full workflow easier to reason about:

- **BigWig tracks** were for qualitative, human-readable inspection
- **BedGraph tracks** were for formal peak calling
- **master matrices + MAnorm2** handled comparison-specific quantitative inference

This separation reduced conceptual confusion. It made it easier to explain why:

- visualization normalization could differ from inferential normalization
- SEACR threshold comparisons should be evaluated on BedGraph inputs, not browser tracks
- CPM tracks were acceptable for IGV even though MAnorm2 was used later for formal differential analysis

---

## Why This Was Especially Important in This Project

This project involved:

- many samples
- multiple histone marks
- metadata-driven automation
- CPS construction
- downstream master matrices and MAnorm2 analysis
- browser-based visual review of candidate loci

In a workflow of this scale, mixing the roles of signal products would have made the architecture less transparent. The dual-track design kept the pipeline cleaner by assigning each signal type a distinct purpose.

---

## Relationship to Other Workflow Decisions

This decision is tightly connected to several other methodological discussions in the appendix:

- why CPM-normalized BigWigs were acceptable for visualization
- why raw fragment BedGraphs were preferred for SEACR
- why SEACR threshold choice mattered for downstream CPS structure
- why formal normalization was handled later by MAnorm2 rather than built into the browser track layer

Thus, the dual-track strategy should be understood as part of the broader principle that **different analytical tasks require different signal representations**.

---

## Key Take-Home Message

Browser visualization and peak calling require different signal tracks because they serve different analytical purposes.

In this project:

- **CPM-normalized BigWig tracks** were generated for human-readable browser inspection
- **raw fragment BedGraph tracks** were generated for SEACR peak calling

This dual-track strategy was not redundant preprocessing. It was a deliberate design choice that preserved both browser readability and peak-calling fidelity while keeping the broader workflow conceptually clean.
