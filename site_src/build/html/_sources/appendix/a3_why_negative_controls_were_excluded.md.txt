# A3. Why Negative-Control Libraries Were Excluded from SEACR and CPS Construction

## Overview

Negative-control libraries such as `IgG`, `nAb`, and `CTnAb` were part of the broader experimental context of this project, but they were intentionally excluded from the core target-mark peak-calling and consensus-feature-definition workflow.

At first glance, one might ask why control libraries should not simply be processed in parallel with the target-mark libraries and allowed to participate in SEACR peak calling or CPS construction. After all, they are real sequencing libraries generated from the same experimental system.

However, the project ultimately treated these control libraries as **background-reference and QC resources**, not as feature-defining inputs for the target-mark analytical backbone.

This section explains why.

---

## What Was Excluded

The following classes of negative-control libraries were intentionally excluded from the target-mark feature-definition workflow:

- `IgG`
- `nAb`
- `CTnAb`

This exclusion was applied not only at one isolated step, but consistently across multiple parts of the pipeline, including:

- SEACR peak calling for target-mark peak definition
- CPS construction
- BAM-to-BED generation for target-mark quantification
- matrix generation steps intended for target-mark enrichment analysis

In other words, the project treated control exclusion as a structural design choice rather than a single local convenience.

---

## Why They Were Not Treated as Ordinary Peak-Calling Targets

### 1. The project’s main goal was to define **target-mark enrichment**, not generic signal structure

The role of SEACR in the main workflow was to identify regions of bona fide enrichment for biological target marks such as H3K27ac or H3K4me1.

Negative-control libraries do not represent the same signal class. They are not expected to define the same biological feature universe as a target-mark library. Allowing them to enter the same feature-definition stage as if they were target-mark datasets would blur the distinction between:

- true target-associated enrichment
- negative-control background behavior

This would undermine the biological meaning of the resulting peak universe.

### 2. Control libraries are often sparse and structurally unstable

In CUT&Tag and related chromatin assays, negative-control libraries are often highly sparse. In this project, that sparsity made them poorly suited as direct drivers of target-region definition.

Even if a control library yields some nonzero signal or even some called intervals under a peak caller, those intervals are not the intended targets of the formal downstream enrichment analysis. They are more appropriately interpreted as:

- background structure
- nonspecific binding
- assay noise
- technical context

rather than as constituents of the target-mark CPS.

### 3. Peak-calling output from controls is not the desired final feature universe

A control library may produce intervals under SEACR, but that does **not** mean those intervals should be promoted into the shared feature universe used for target-mark quantification.

The project’s CPS was intended to represent a marker-specific consensus universe of biologically meaningful enriched regions from target libraries. Control-derived intervals would not serve that purpose well and would risk introducing non-target structure into the final matrix.

---

## Why They Were Excluded From CPS Construction

The logic for CPS exclusion was even stronger than the logic for peak-calling exclusion.

### 1. CPS was intended to represent a target-mark feature universe

The CPS was constructed as the shared interval space for downstream quantification, occupancy tracking, and differential enrichment analysis. That feature universe needed to be grounded in target-mark biology.

If negative-control intervals were merged into the CPS, the feature universe would no longer represent only target-mark enrichment. Instead, it would become a hybrid of:

- target-specific signal
- background-control structure
- potentially sparse or noisy control-specific intervals

That would weaken the biological meaning of the CPS itself.

### 2. Control-derived intervals would propagate into all downstream analysis layers

Once a control-derived interval enters the CPS, it does not remain isolated. It then propagates into:

- master matrix generation
- occupancy tracking
- PCA
- MAnorm2 filtering
- normalization-anchor logic
- differential testing

This means that letting control intervals enter CPS is not a small local choice; it changes the quantitative substrate of the entire downstream workflow.

### 3. The project wanted control libraries to inform interpretation, not define the main feature universe

Control libraries were still useful, but their role was interpretive rather than feature-defining.

They helped with:

- QC
- background inspection
- assessing nonspecific signal
- understanding assay context

But they were not used to decide which intervals should enter the formal target-mark CPS.

---

## Why This Exclusion Was Applied Consistently Across Multiple Steps

One important project-level realization was that control exclusion had to be applied **consistently**, not only at the CPS step.

If control libraries are excluded from CPS construction but still allowed to enter other quantification-preparation stages, they can still create confusion in file matching, BED generation, matrix assembly, or metadata interpretation.

For this reason, exclusion was enforced across several stages of the main target-mark workflow.

This consistency served two purposes:

1. it reduced the chance of accidentally carrying control-derived files into feature-definition or quantification steps  
2. it made the project’s analytical logic easier to interpret and document  

The rule became simple:

> control libraries may be inspected, but they do not define the target-mark feature universe.

---

## Why This Decision Was Especially Important in This Project

This project involved:

- multiple histone marks
- multiple CPS groups
- metadata-driven file discovery
- automated peak calling and merging
- downstream master matrix construction

In such a workflow, even a small file-matching mistake could allow control-derived intervals to enter the target-mark pipeline and silently contaminate downstream results.

That risk made explicit control exclusion especially important. It was not just a theoretical preference; it was a practical safeguard for the integrity of the whole pipeline.

---

## What This Decision Does *Not* Mean

Excluding `IgG`, `nAb`, and `CTnAb` from SEACR and CPS does **not** imply that those libraries were unimportant or should never be inspected.

Instead, it means they were assigned a different analytical role.

They remained useful for:

- evaluating nonspecific background
- contextualizing target-mark signal
- troubleshooting assay behavior
- supporting methodological comparisons

But they were intentionally kept outside the formal target-mark feature-definition backbone.

---

## Relationship to Other Workflow Decisions

This decision is tightly connected to several other project-level design choices:

- why browser visualization and peak calling were treated as separate signal layers
- why raw fragment BedGraphs were used for SEACR
- why the CPS was intended to represent a target-mark consensus universe
- why the master matrix and MAnorm2 workflow were designed around target-mark occupancy and quantification rather than control-defined intervals

Thus, control exclusion should be understood as part of the larger workflow architecture rather than as an isolated filtering preference.

---

## Key Take-Home Message

Negative-control libraries (`IgG`, `nAb`, `CTnAb`) were excluded from SEACR and CPS construction because the project’s main workflow was designed to define and quantify **target-mark enrichment**, not background structure.

These control libraries remained valuable for QC and interpretive context, but they were intentionally prevented from entering the feature-definition backbone of the target-mark analysis. This preserved the biological meaning of the CPS, protected downstream quantification from control-derived contamination, and made the entire metadata-driven workflow more robust and interpretable.
