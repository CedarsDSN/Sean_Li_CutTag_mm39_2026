# C1. Why Custom GENCODE-Matched Annotation Was Preferred Over Generic Annotation Resources

## Overview

A major annotation decision in this project was to use a **custom GENCODE-matched annotation framework** rather than relying solely on generic precompiled annotation resources such as standard TxDb or organism-wide mapping packages.

At first glance, generic annotation resources are convenient and widely used. However, in a project like this one—where the upstream workflow already depended on a specific filtered GENCODE release, a custom reference build, and curated gene-type selection—annotation consistency became too important to leave to a loosely matched generic package.

The final workflow therefore used:

- a custom TxDb built from the same filtered GENCODE annotation used upstream
- a custom Ensembl-to-symbol gene map derived from that same source

This section explains why that choice was made and why it improved downstream interpretability.

---

## Why Generic Annotation Resources Were Not Ideal for This Project

Generic annotation packages are often useful for broad exploratory work, but they can become problematic when they do not perfectly match the exact reference framework used throughout the rest of the pipeline.

In this project, several potential problems were identified.

### 1. Annotation-version mismatch

If the alignment, feature preparation, and downstream annotation do not all use the same annotation release, inconsistencies can arise in:

- transcript definitions
- gene boundaries
- TSS positions
- gene identifiers
- symbol mapping

Even if these mismatches appear small, they can create confusion when interpreting individual peaks or integrating results across steps.

### 2. Avoidable symbol-mapping loss

Generic mapping resources do not always align cleanly with the exact Ensembl identifiers present in a custom GTF-derived workflow. This can produce unnecessary mapping loss, especially when gene identifiers include version suffixes or when the annotation release differs subtly from the package’s internal reference.

### 3. Less control over the biological feature universe

A generic annotation package typically reflects a much broader annotation universe than the one the project intentionally chose upstream. That can make the final annotation output noisier, less focused, and less aligned with the project’s intended biological interpretation.

---

## Why Annotation Consistency Mattered More in This Project

Annotation in this project was not a minor cosmetic add-on. It directly influenced:

- genomic context assignment
- nearest-gene labeling
- distance-to-TSS interpretation
- downstream biological interpretation of differential loci
- volcano-plot labeling
- gene-level downstream enrichment analysis
- integration with RNA-seq or other omics layers

Because annotation was so tightly coupled to downstream interpretation, it was important to make it as internally consistent as possible with the rest of the workflow.

---

## What the Project Used Instead

The project used two custom annotation resources derived directly from the same filtered GENCODE source used earlier in the pipeline.

### 1. Custom TxDb

A project-specific TxDb was built from the filtered GENCODE annotation used in reference preparation. This meant that promoter, intron, intergenic, and transcript-context assignments were all defined relative to the same curated annotation universe used upstream.

### 2. Custom gene map

A custom Ensembl-to-symbol mapping object was also created from that same GENCODE source. This provided a direct and internally matched mapping layer for assigning gene symbols to annotated loci.

Together, these resources allowed the annotation step to operate within the same biological and coordinate framework as the rest of the workflow.

---

## Why This Was Better Than Using Generic Resources Alone

### 1. It preserved internal consistency across the pipeline

One of the biggest advantages of the custom framework was that the same annotation logic was effectively carried through:

- reference preparation
- genomic feature definition
- annotation
- final interpretation

This reduced the risk that the workflow would quantify one annotation universe but interpret results in another.

### 2. It reduced unnecessary mapping failure

Because the gene map was generated from the same GENCODE source, Ensembl identifiers in the annotation output had a much cleaner path to gene-symbol assignment. This was especially important in a workflow where versioned Ensembl IDs were present and later normalized for downstream use.

### 3. It improved confidence in locus-level interpretation

When a peak was labeled as promoter-associated, nearest to a given gene, or located a certain distance from a TSS, that label came from the same annotation framework used throughout the project. This made the interpretation more defensible and less dependent on hidden package-specific annotation differences.

### 4. It better matched the project’s curated biological scope

The project had already made deliberate choices about which gene types and annotation universe were most relevant. A custom GENCODE-matched framework preserved that logic, whereas a generic package would have reintroduced a broader and potentially less relevant annotation universe at the final interpretation stage.

---

## Why This Decision Was Especially Important for the Final Differential Tables

The final differential-enrichment output tables in this project were intended to be directly interpretable and reusable. They included:

- genomic coordinates
- statistical results
- annotation labels
- gene identifiers
- gene symbols
- comparison metadata

Once these tables were exported, they were meant to support downstream review without requiring re-annotation or constant manual correction.

That made annotation quality especially important. A project-matched annotation framework was therefore preferable to a generic one because it made the final exported tables more coherent and more trustworthy as standalone outputs.

---

## Relationship to the Restricted Gene-Type Strategy

This decision is closely related to the separate appendix discussion on why restricted gene-type annotation was preferred over a fully generic annotation set.

The key distinction is:

- this section explains **why the annotation resource itself was custom matched**
- the other section explains **why the project intentionally restricted the biological feature classes included in that resource**

Together, those decisions created a final annotation framework that was both technically consistent and biologically focused.

---

## Relationship to Downstream Mapping Logic

This decision also connected directly to the choice to normalize Ensembl IDs and map symbols using the project’s own gene map rather than relying purely on generic organism packages.

That choice helped ensure that:

- annotation identifiers
- gene symbols
- feature labels

all came from one internally consistent reference ecosystem.

This was particularly important in a project intended to produce publication-ready result tables and downstream biological summaries.

---

## Key Take-Home Message

Custom GENCODE-matched annotation was preferred in this project because annotation was too central to downstream interpretation to rely on a loosely matched generic resource alone.

By using a project-specific TxDb and gene map derived from the same filtered GENCODE source used upstream, the workflow achieved:

- stronger internal consistency
- cleaner gene-symbol mapping
- more reliable locus-level interpretation
- final result tables that were easier to trust and reuse

In this project, annotation was treated as an integrated part of the analytical design, not as a generic post hoc labeling step.
