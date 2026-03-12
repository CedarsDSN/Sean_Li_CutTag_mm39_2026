# A1. ChIPseqSpikeInFree in This Project

## Overview

`ChIPseqSpikeInFree` was considered in this project as a possible way to estimate global scaling behavior without relying on a formal external spike-in design. However, after testing and discussion, it was not adopted as the default normalization backbone for the main CUT&Tag workflow.

This section documents how the method was evaluated, what practical issues arose, and why its role in this project remained exploratory rather than foundational.

---

## Why It Was Considered

The main reasons for considering `ChIPseqSpikeInFree` were:

- the project did not rely on a formal external spike-in framework
- some comparisons could plausibly contain broad global shifts in signal
- a spike-in-free scaling estimate might provide an alternative to purely library-size-based interpretation
- it was important to test whether global-scaling-aware frameworks would materially change biological conclusions

In other words, `ChIPseqSpikeInFree` was evaluated as a possible auxiliary normalization strategy, not as an assumed default.

---

## Core Evaluation Questions

The project focused on several practical questions:

1. Should `ChIPseqSpikeInFree` be used at all in this dataset?
2. Should it be run with or without input / control tracks?
3. Should its scaling factors be interpreted as true biological global effects?
4. Should those scaling factors be propagated directly into downstream MAnorm2 differential analysis?
5. How should one interpret cases where the same sample receives different scaling factors in different CPS contexts?

---

## Why It Was Not Adopted as the Default Normalization Backbone

### 1. The project was not built around a spike-in-driven experimental design

Although `ChIPseqSpikeInFree` can be informative, the project’s primary analytical design was built around:

- CPS-defined feature spaces
- MAnorm2-based within-comparison normalization
- raw fragment BedGraphs for SEACR peak calling
- CPM-normalized BigWig tracks for browser visualization

Because the workflow was not originally anchored to spike-in-style external scaling, replacing the main normalization backbone with `ChIPseqSpikeInFree` would have introduced a new global dependency not equally supported across all analysis steps.

### 2. Scaling factors were context dependent

One of the most important observations from testing was that the same biological sample could receive different scaling factors when analyzed in different CPS contexts.

This means that the scaling factor was not a universal intrinsic property of the sample alone. Instead, it depended on:

- which comparison framework was being used
- which genomic intervals were being evaluated
- which other samples were present in the same analytical context

This context dependence made it difficult to use the resulting scaling factors as a single project-wide normalization standard.

### 3. Scaling factors should not be overinterpreted as true global fold changes

A scaling factor estimated by `ChIPseqSpikeInFree` should not automatically be interpreted as the true biological magnitude of a global enrichment difference. In practice, the scaling factor reflects the model and assumptions used to estimate global scaling behavior, not a direct measurement of biological ground truth.

Therefore:

- a factor of 1.3 does not prove a 1.3-fold biological global effect
- a factor of 6.5 does not by itself prove a sixfold biological global shift

For this reason, these scaling factors were treated as exploratory normalization outputs rather than definitive biological measurements.

---

## With or Without Input / Control

A major practical question was whether `ChIPseqSpikeInFree` should be run with input or control libraries included.

### With input / control

Potential advantages:

- may better represent background structure in some datasets
- may help certain global-scaling estimation frameworks

Potential problems in this project:

- input / control libraries were not uniformly available or equally informative across all contexts
- very sparse control libraries can behave unstably
- some control datasets may be skipped or contribute weakly because of low usable signal

### Without input / control

Potential advantages:

- more internally consistent across target-mark datasets
- avoids injecting sparse or unstable control behavior into the scaling estimate
- aligns better with the control-free design used elsewhere in the main workflow

### Project interpretation

In this project, the with/without-input question was treated as part of methodological evaluation rather than a settled universal rule. The broader conclusion was that even when `ChIPseqSpikeInFree` was informative, it did not provide a sufficiently universal or stable basis to replace the core CPS–MAnorm2 framework.

---

## Why Its Scaling Factors Were Not Propagated Directly into MAnorm2

A key downstream design decision was not to take `ChIPseqSpikeInFree` scaling factors and directly impose them as the default normalization layer for MAnorm2 differential testing.

The reasons were:

- the scaling factors were context dependent rather than globally stable
- MAnorm2 already contains its own comparison-specific normalization logic
- anchor-based normalization in MAnorm2 was designed to operate within the CPS-defined comparison framework
- directly combining external scaling factors with MAnorm2 without a coherent unified design would risk mixing two incompatible normalization assumptions

Accordingly, `ChIPseqSpikeInFree` was treated as a comparative or exploratory method rather than the default quantitative engine of the main pipeline.

---

## Relationship to Other Workflow Components

This project ultimately kept the following division of labor:

- **SEACR** for peak calling on raw fragment BedGraphs
- **CPS / master matrices** for consistent feature-space quantification
- **MAnorm2** for comparison-specific normalization and differential enrichment analysis
- **CPM BigWig** for browser visualization
- **ChIPseqSpikeInFree** as a methodological comparison tool rather than the default backbone

This design preserved internal consistency across the full workflow.

---

## Key Take-Home Message

`ChIPseqSpikeInFree` was seriously considered and tested in this project, but it was not adopted as the default normalization backbone. The main reasons were:

- lack of a true spike-in-centered experimental design
- context-dependent scaling-factor behavior across CPS groups
- the risk of overinterpreting scaling factors as direct biological global effects
- incompatibility with simply imposing those factors onto the project’s CPS–MAnorm2 differential framework

As a result, `ChIPseqSpikeInFree` remained an informative comparison tool, not the primary normalization engine of the final workflow.
