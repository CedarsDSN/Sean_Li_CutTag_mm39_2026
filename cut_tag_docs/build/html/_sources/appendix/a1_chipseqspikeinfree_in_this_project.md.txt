# A1. ChIPseqSpikeInFree in This Project

## Overview

`ChIPseqSpikeInFree` was evaluated in this project as a possible way to estimate genome-wide scaling behavior without relying on a formally added external spike-in. The motivation for testing it was straightforward: some CUT&Tag comparisons can plausibly contain broad global shifts, and a spike-in-free scaling framework might capture that behavior more explicitly than simple library-size normalization.

However, after project-specific testing and comparison with the rest of the workflow, `ChIPseqSpikeInFree` was **not** adopted as the default normalization backbone of the final pipeline. Instead, it was treated as an informative methodological comparison framework.

This section documents the main reasons for that decision.

---

## Why ChIPseqSpikeInFree Was Considered

The method was considered for several reasons:

- the project did not use a formal exogenous spike-in design
- some biological comparisons could plausibly involve broad global signal changes
- it was important to test whether a spike-in-free global scaling strategy would alter interpretation relative to the main CPS–MAnorm2 workflow
- it provided a way to explicitly examine the idea of genome-wide scaling without assuming that library-size normalization alone was always sufficient

Thus, `ChIPseqSpikeInFree` was evaluated as a candidate auxiliary normalization framework, not as a method that was assumed to be correct a priori.

---

## Core Questions Addressed During Evaluation

The project-level discussion of `ChIPseqSpikeInFree` focused on the following practical questions:

1. Should `ChIPseqSpikeInFree` be used at all in this dataset?
2. Should it be run with or without input / control samples?
3. Can carry-over bacterial DNA be treated as an accidental spike-in?
4. Should the resulting scaling factors be interpreted as direct biological global-effect estimates?
5. Should those scaling factors be propagated directly into MAnorm2 differential analysis?
6. How should one interpret cases where the same biological sample receives different scaling factors in different CPS contexts?

---

## Why Accidental *E. coli* Carry-Over Was Not Used as a Spike-In Surrogate

One related idea that was discussed was whether accidental bacterial carry-over, especially *E. coli*-like DNA, could be treated as a pseudo-spike-in.

This was ultimately not adopted for the following reasons:

- the project did not establish a robust, intentionally designed spike-in framework
- accidental carry-over is not equivalent to a controlled external reference
- exogenous carry-over, even if present, may be sparse, unstable, or inconsistent across samples
- an accidental signal is difficult to justify as a quantitative normalization backbone for formal downstream inference

Accordingly, accidental bacterial carry-over was not treated as a formal spike-in substitute in the final workflow.

---

## With or Without Input / Control Samples

A major practical issue was whether `ChIPseqSpikeInFree` should be run together with input or control libraries.

### Potential rationale for including input / control

Including input-like controls might in principle help characterize background structure and improve interpretation in some settings.

### Practical concerns in this project

In this project, however, that strategy was not obviously superior because:

- control libraries were not uniformly informative across all CPS contexts
- some controls were sparse and therefore potentially unstable as scaling references
- the main workflow itself was not built around input-driven normalization logic
- importing input/control behavior into the scaling model risked adding another layer of inconsistency across already heterogeneous comparisons

For these reasons, the with/without-input question was treated as an exploratory methodological issue rather than a settled default rule.

---

## Why CPS-Specific Scaling-Factor Inconsistency Was a Major Concern

One of the most important observations from project-level testing was that the same biological sample could receive different scaling factors when analyzed in different CPS contexts.

This means that the estimated scaling factor was not simply an intrinsic property of the sample alone. Instead, it depended on:

- which feature universe was being considered
- which other samples were present in the same analytical context
- how the global signal structure was represented within that CPS

This context dependence had an important consequence:

> a `ChIPseqSpikeInFree` scaling factor could not be treated as a universal sample-level constant that could be safely propagated throughout the entire workflow.

This was one of the strongest reasons not to adopt it as the single global normalization backbone of the project.

---

## Why Scaling Factors Were Not Interpreted as Direct Biological Global Effects

Another important caution was interpretive.

Even when `ChIPseqSpikeInFree` produced a scaling factor, that value was not interpreted as a direct measurement of the true biological magnitude of genome-wide change. In practice, the scaling factor reflects the assumptions and model behavior of the method under a given analytical context.

Therefore:

- a scaling factor of 1.3 was **not** interpreted as proof of a true 1.3-fold biological global effect
- a scaling factor of 6.5 was **not** interpreted as proof of a true sixfold biological global effect

The scaling factor was treated as a model-derived normalization quantity, not as a standalone biological conclusion.

---

## Why ChIPseqSpikeInFree Was Not Adopted as the Default Normalization Backbone

Several project-specific considerations led to the decision not to adopt `ChIPseqSpikeInFree` as the default normalization backbone.

### 1. The main workflow was built around a different quantitative architecture

The final workflow was centered on:

- CPS-based feature definition
- CPS-level master matrices
- comparison-specific MAnorm2 filtering and normalization
- occupancy-aware differential testing
- separate browser-visualization normalization

Replacing that design with a single spike-in-free scaling backbone would have required a more radical redefinition of the full workflow than was justified by the project-level evidence.

### 2. Scaling factors were not globally stable across contexts

Because scaling factors could vary across CPS groups, they did not provide a universal sample-level normalization constant suitable for all steps.

### 3. The workflow already had a coherent comparison-specific normalization framework

MAnorm2 provided its own comparison-specific normalization structure, based on conservative shared anchors within each analysis context. This was more naturally aligned with the CPS-based design of the project.

### 4. Browser visualization and peak calling were already intentionally separated from formal differential normalization

The workflow already used:

- CPM-normalized BigWigs for visualization
- raw fragment BedGraphs for SEACR
- CPS/master-matrix quantification for differential analysis

Introducing `ChIPseqSpikeInFree` as the single normalization backbone across all three layers would have reduced that intentional separation and created more methodological coupling than desired.

---

## Why Its Scaling Factors Were Not Propagated Directly Into MAnorm2

The project also considered whether `ChIPseqSpikeInFree` scaling factors should be directly imposed on downstream MAnorm2 analysis.

This was not adopted for several reasons:

- the scaling factors were CPS-context dependent
- MAnorm2 already performs its own comparison-specific normalization
- the anchor-based logic of `normBioCond()` was designed to work within the CPS-defined comparison space
- layering an external scaling-factor system on top of that framework would have mixed two different normalization philosophies without a single unified statistical design

Thus, although `ChIPseqSpikeInFree` was informative as a comparison method, its scaling factors were not treated as default inputs to the formal MAnorm2 testing framework.

---

## Relationship to Other Workflow Components

The final project-level division of labor remained:

- **raw fragment BedGraphs** for SEACR peak calling
- **CPS / master matrices** for unified feature-space quantification
- **MAnorm2** for comparison-specific normalization and differential enrichment testing
- **CPM BigWigs** for browser visualization
- **ChIPseqSpikeInFree** for methodological testing and comparative evaluation

This preserved internal consistency across the pipeline.

---

## Key Take-Home Message

`ChIPseqSpikeInFree` was seriously evaluated in this project, but it was not adopted as the default normalization backbone. The main reasons were:

- absence of a true spike-in-centered experimental design
- the weakness of treating accidental carry-over as a spike-in substitute
- CPS-specific scaling-factor inconsistency
- the danger of overinterpreting scaling factors as direct biological global-effect estimates
- incompatibility with simply imposing those factors onto the project’s CPS–MAnorm2 differential framework

As a result, `ChIPseqSpikeInFree` remained an informative methodological comparison tool rather than the primary normalization engine of the final workflow.
