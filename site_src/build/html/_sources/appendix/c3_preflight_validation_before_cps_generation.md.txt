# C3. Pre-Flight Validation Before CPS Generation

## Overview

Before running CPS generation, the project benefited from explicit pre-flight validation of metadata and input files. This was especially important because CPS construction in this workflow was metadata driven: if metadata entries, filenames, marker identities, or control exclusions were inconsistent, those errors could propagate into all downstream analyses.

This section explains why pre-flight validation mattered and why it was treated as a practical safeguard rather than an optional convenience.

---

## Why CPS Generation Was a Sensitive Step

CPS generation sits near the center of the workflow. It defines the shared interval universe that later feeds into:

- master count matrix generation
- occupancy tracking
- PCA
- MAnorm2 filtering and normalization
- differential enrichment analysis

Because so many later steps depend on the CPS, small errors at the CPS stage can propagate widely and become difficult to diagnose later.

This made pre-flight validation especially important.

---

## What Needed To Be Validated Before CPS Generation

### 1. File existence

Before merging sample-level peak files, the project needed to confirm that all expected target-mark peak files actually existed.

If expected files were missing, then the CPS would be built from an incomplete sample set, potentially without obvious failure at the merge stage itself.

### 2. Marker consistency

Each CPS was intended to represent a marker-specific feature universe. Therefore, it was necessary to ensure that only files corresponding to the intended histone mark were included.

Without this check, it would be possible for a CPS merge step to accidentally combine peak files from mismatched target marks, which would fundamentally distort the resulting feature universe.

### 3. Metadata integrity

Because the workflow was metadata driven, it was important to verify that:

- CPS identifiers were correct
- comparison structures were parsed correctly
- semicolon-delimited sample groups expanded as intended
- sample names matched the naming conventions used in the actual peak files

If metadata parsing is wrong, then the workflow may silently build the wrong CPS even if all files are present.

### 4. Negative-control exclusion

The project also needed to ensure that negative-control libraries such as `IgG`, `nAb`, and `CTnAb` did not accidentally enter target-mark CPS construction through permissive filename matching or metadata confusion.

This was particularly important in an automated workflow where broad wildcard matching can otherwise pick up unintended files.

---

## Why These Checks Were Important in a Metadata-Driven Workflow

A metadata-driven design is powerful because it enables large-scale automation. But that same strength also means that one inconsistency can propagate across many outputs.

For example, if a metadata row:

- points to the wrong sample name
- implies the wrong marker
- fails to exclude a control file
- omits an expected replicate

then the CPS can be wrong before any downstream quantification even begins.

Thus, pre-flight validation was essential for protecting the logic of the metadata-driven workflow itself.

---

## Why This Was Not Just a Technical Convenience

It would be easy to treat pre-flight validation as a purely engineering-oriented step. In reality, it had direct methodological importance.

If the CPS is wrong, then later analyses may appear numerically valid while actually operating on the wrong feature universe.

That means pre-flight validation protects not only:

- computational correctness
- file-matching correctness

but also:

- biological interpretability
- validity of downstream comparisons
- trustworthiness of summary tables and differential results

In this sense, pre-flight validation was part of the project’s methodological rigor, not just its scripting hygiene.

---

## Why This Was Especially Important in This Project

This project involved:

- multiple CPS groups
- multiple histone markers
- repeated sample reuse across comparisons
- metadata-driven automation
- exclusion of negative controls
- downstream matrix reuse across many analyses

In a workflow of this complexity, silent structural errors are more dangerous than obvious crashes, because they can survive for multiple downstream steps before being noticed.

That is why validating the CPS inputs before merge was especially worthwhile.

---

## Relationship to the Master Matrix Design

Pre-flight validation also became more important after the workflow moved to CPS-level master matrices.

Because each master matrix became a shared quantitative substrate for multiple downstream analyses, an upstream CPS mistake would no longer affect only one local comparison. It could affect an entire CPS-level analytical branch.

Thus, validating CPS inputs before merge helped protect the integrity of everything built on top of the CPS.

---

## Key Take-Home Message

Pre-flight validation before CPS generation was important because CPS construction defines the shared feature universe for many downstream analyses. Checking file existence, marker consistency, metadata integrity, and control exclusion before merging helped prevent silent structural errors from propagating into master matrices, PCA, filtering, and differential analysis.

In this project, pre-flight validation was therefore an important methodological safeguard built into the metadata-driven workflow.
