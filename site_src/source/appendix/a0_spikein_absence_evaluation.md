# A0. How Spike-In Absence Was Evaluated in This Project

## Overview

Before considering any spike-in-based or spike-in-free global scaling strategy, it was first necessary to determine whether this project actually contained usable exogenous spike-in signal. In CUT&Tag workflows, this question is important because normalization strategies based on external DNA require either:

- a deliberately added spike-in control
- or a detectable and sufficiently stable carry-over signal from an exogenous source such as *E. coli*

In this project, we explicitly evaluated whether such signal was present and suitable for normalization. This assessment ultimately shaped the decision not to treat accidental bacterial carry-over as a valid spike-in surrogate and not to build the primary workflow around spike-in-based normalization.

---

## Why This Evaluation Was Necessary

Several downstream decisions depended on this initial check:

1. whether an external scaling framework could be applied at all  
2. whether accidental *E. coli* carry-over could be treated as a pseudo-spike-in  
3. whether spike-in-aware tools such as `ChIPseqSpikeInFree` should be used as a core normalization backbone or only as an exploratory comparison tool  

Because spike-in-based normalization can strongly affect global interpretation, it was important to establish whether spike-in-like reads were truly present and sufficiently reliable before using them in formal downstream analysis.

---

## Evaluation Logic

The spike-in absence evaluation in this project was based on the following logic:

### 1. No deliberate spike-in design was built into the primary experiment

The project was not originally designed around a formal exogenous spike-in normalization framework. Therefore, any spike-in-like signal would have had to come from:

- accidental bacterial carry-over
- residual contaminating DNA
- or some other unintended exogenous source

This means that the presence of spike-in-like reads could not be assumed and had to be checked explicitly.

### 2. Accidental carry-over is not equivalent to a true spike-in

Even if a small number of exogenous reads are present, that does not automatically make them suitable for normalization. A usable spike-in signal should be:

- detectable across samples
- sufficiently abundant
- relatively stable across libraries
- interpretable as an external reference rather than random contamination

Accidental carry-over does not reliably satisfy these criteria.

### 3. Absence must be interpreted biologically and technically

A low or undetectable exogenous signal can mean several different things:

- true absence of spike-in material
- successful cleanup with minimal carry-over
- sequencing depth too low to recover exogenous reads
- inconsistent contamination that is not reproducible enough for normalization

Therefore, the question was not only “are any exogenous reads present?” but also “are they reliable enough to support normalization?”

---

## Practical Assessment Strategy

The project treated spike-in absence evaluation as a pre-normalization diagnostic question. The practical criteria were:

- whether exogenous reads were detectably present at all
- whether they were present consistently across the relevant samples
- whether they were abundant enough to support stable scaling
- whether their behavior was plausible as a normalization reference rather than random contamination

If these conditions were not met, spike-in-based normalization would not be considered reliable for the main workflow.

---

## Project Conclusion

Based on the project-level evaluation, usable spike-in signal was not established strongly enough to justify treating this dataset as a spike-in-driven normalization workflow.

As a result:

- accidental bacterial carry-over was **not** adopted as a formal spike-in surrogate
- spike-in-like scaling was **not** used as the default normalization backbone
- the main analytical framework remained centered on:
  - CPS-based quantification
  - MAnorm2-based normalization and differential analysis
  - CPM-normalized browser tracks for visualization
  - raw fragment BedGraphs for SEACR peak calling

This decision helped keep the primary workflow grounded in signals that were directly supported by the actual experimental design and detectable target-mark data.

---

## Relationship to Later Appendix Sections

This spike-in absence evaluation provides the foundation for the discussions in the following sections:

- **A1. ChIPseqSpikeInFree in this project**
- **A2. Comparison of SEACR thresholds: 0.01 vs 0.005 vs 0.05**
- **A5. Why CPM-normalized BigWig tracks are acceptable for visualization**

In other words, the project did not reject spike-in-aware methods arbitrarily; rather, it first evaluated whether a reliable spike-in-like signal existed and then built the main workflow accordingly.

---

## Key Take-Home Message

Spike-in-based normalization should not be assumed simply because exogenous or bacterial reads might exist in principle. In this project, spike-in absence was treated as an explicit methodological question. Because no sufficiently reliable spike-in-like signal was established for use as a formal normalization reference, the main CUT&Tag workflow was intentionally built without relying on a spike-in-centered normalization design.
