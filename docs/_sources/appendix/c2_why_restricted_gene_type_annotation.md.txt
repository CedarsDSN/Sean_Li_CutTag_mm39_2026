# C2. Why Restricted Gene-Type Annotation Was Chosen Instead of a Fully Generic Annotation Set

## Overview

The final annotation framework in this project did not use an unrestricted, fully generic genome annotation universe. Instead, it focused on a curated subset of biologically relevant gene classes, especially:

- protein-coding genes
- lncRNAs
- miRNAs

This was a deliberate project-level decision. It was not made because other annotation classes are universally unimportant, but because the project prioritized interpretability, consistency, and biologically relevant downstream output over maximal annotation breadth.

This section explains why that restricted strategy was preferred.

---

## Why a Fully Generic Annotation Universe Was Not Ideal

A fully generic annotation set can include many additional feature classes, such as:

- pseudogenes
- TECs
- weakly supported transcripts
- low-priority or poorly interpretable annotation categories
- broad catalog-level features that are not central to the project’s downstream biological aims

In principle, such comprehensiveness may sound attractive. In practice, however, it can make final annotation output noisier, harder to interpret, and less focused on the gene classes most relevant to chromatin-mark biology in this project.

---

## Why the Project Preferred a Restricted Gene-Type Set

### 1. The final result tables were meant to be interpretable without heavy post hoc cleanup

The project’s differential result tables were intended to serve as usable downstream products, not just intermediate raw annotation dumps.

That meant the annotation layer needed to support:

- readable gene labeling
- meaningful nearest-gene interpretation
- practical downstream enrichment analysis
- collaborator-friendly result review

A highly unrestricted annotation universe would have increased the amount of low-priority or confusing gene labeling in those tables.

### 2. The project wanted to emphasize biologically relevant feature classes

The main biological interpretation of the CUT&Tag results was expected to revolve around:

- coding-gene regulation
- long noncoding regulatory context
- miRNA-related signal when relevant

These feature classes were substantially more aligned with the expected downstream interpretation than a broader “include everything” strategy.

### 3. Restriction reduced annotation clutter

A more focused gene-type universe helped reduce:

- irrelevant nearest-gene assignments
- overpopulation of obscure transcript classes
- unnecessary complexity in downstream summaries
- interpretive noise in pathway and gene-list review

In other words, restricting the gene universe was a way of increasing signal-to-noise ratio at the annotation layer.

---

## Why This Was Not the Same as Ignoring Noncoding Biology

It is important to note that the project did **not** reduce annotation to protein-coding genes only.

The final framework retained:

- lncRNAs
- miRNAs

because these classes were considered biologically meaningful and relevant for the kinds of regulatory interpretations the project might later make.

Thus, the annotation strategy was not “coding-only.” It was **curated and biologically selective**.

---

## Why This Decision Worked Well With the Custom GENCODE Framework

This restricted gene-type strategy fit naturally with the project’s broader custom GENCODE-matched annotation framework.

Because the project was already building:

- a custom TxDb
- a custom gene map
- a filtered GENCODE-derived annotation ecosystem

it was straightforward to define a biologically focused annotation universe rather than inheriting the full breadth of a generic annotation package by default.

This let the project control both:

- **technical consistency** of annotation resources
- **biological scope** of the annotation output

That combination was important.

---

## Why This Was Especially Useful for Downstream Interpretation

The restricted annotation set improved downstream interpretability in several practical ways.

### 1. Cleaner result tables

When differential peaks were annotated, the final tables were easier to review because the nearest-gene and annotation labels were more likely to belong to gene classes the project actually cared about.

### 2. Cleaner gene-level summaries

Top-gene lists, annotation distributions, and downstream reporting all became easier to interpret when the annotation universe was focused.

### 3. Better collaborator communication

In collaborative settings, highly cluttered annotation output can make result review more difficult. A more focused annotation universe helps collaborators understand what kinds of genes are being reported and why.

---

## Why a Fully Generic Strategy Was Not Rejected Universally

The project did **not** conclude that fully generic annotation is always wrong. Rather, it concluded that for this workflow, a more focused annotation universe was a better match to the project’s goals.

A fully generic annotation strategy may still be useful in:

- broad exploratory analyses
- transcript-discovery-oriented workflows
- annotation-centric cataloging projects

But this project was focused on chromatin-mark differential interpretation within a curated analytical framework, so a restricted gene-type strategy was more appropriate.

---

## Relationship to the Custom Annotation Discussion

This section is closely related to the separate discussion of why a custom GENCODE-matched annotation resource was preferred.

The distinction is:

- **C1** explains why the annotation resource needed to be custom and reference matched
- **C2** explains why the biological scope of that resource was intentionally restricted

Together, these decisions shaped the project’s final annotation design.

---

## Key Take-Home Message

Restricted gene-type annotation was chosen because the project prioritized biological interpretability over unrestricted annotation breadth.

By focusing on protein-coding genes, lncRNAs, and miRNAs, the workflow reduced annotation clutter, improved the readability of final result tables, and aligned the annotation output more closely with the project’s downstream biological goals.

In this project, the annotation universe was therefore curated not to exclude biology arbitrarily, but to make the final outputs more focused, useful, and interpretable.
