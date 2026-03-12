# B3. Why Autosomal Fully Occupied Peaks Were Used as MAnorm2 Normalization Anchors

## Overview

A key normalization decision in the MAnorm2 workflow was to use a conservative anchor set for `normBioCond()` rather than letting all retained intervals participate equally in between-group normalization.

The project defined normalization anchors as intervals that were:

- located on autosomes
- occupied in every replicate of Group 1
- occupied in every replicate of Group 2

In code, the logic was equivalent to:

```r
autosome <- !(data_filtered$chrom %in% c("chrX", "chrY"))
common_peak_idx <- autosome &
                   (occ_n_g1_f == ncol(occ_g1_f)) &
                   (occ_n_g2_f == ncol(occ_g2_f))
```

This section explains why such a conservative anchor definition was used and why it was especially appropriate for this project.

---

## Why Normalization Anchors Needed To Be Chosen Carefully

In MAnorm2, normalization anchors are intended to provide a shared baseline between the two biological conditions being compared. If that baseline is defined using unstable, partially differential, or biologically biased loci, normalization may become harder to interpret.

This issue was particularly important in this project because the comparisons included:

- strong biological differences in some contexts
- sex-related contrasts
- mark-specific asymmetry
- limited replicate numbers in many comparisons

Under these conditions, it was not safe to assume that “all retained peaks” should automatically serve as normalization anchors.

---

## Why Not Use All Retained Peaks as Anchors

A more permissive approach would have been to let the full retained interval set contribute to normalization. The project deliberately avoided that for several reasons.

### 1. Not all retained intervals are equally stable

Even after filtering, retained intervals may still include:

- partially differential loci
- weakly stable loci
- intervals with asymmetric occupancy behavior
- regions that pass thresholding but are not ideal baseline candidates

Such intervals may be appropriate to **test**, but not necessarily appropriate to **normalize on**.

### 2. Using all retained intervals risks absorbing true biology into the normalization baseline

If a substantial number of retained intervals reflect real group differences, allowing them to influence normalization could partially suppress the very biological shifts the analysis is meant to detect.

The project therefore wanted a smaller but cleaner normalization baseline, rather than a broader but more biologically mixed one.

---

## Why Autosomes Were Chosen

One of the most important parts of the anchor definition was the exclusion of `chrX` and `chrY`.

### 1. Sex chromosomes may carry real biology in this project

This project included sex-related comparisons in which differences on `chrX` and `chrY` were not nuisance artifacts—they were potentially real and biologically meaningful.

If sex chromosomes were included in the normalization anchor set, true dosage-linked or sex-specific signal could be partially absorbed into the scaling baseline.

### 2. Autosomes provide a safer shared background for normalization

By restricting anchors to autosomes, the workflow reduced the chance that normalization would distort or dilute biologically meaningful sex-chromosome differences.

This was especially important because some loci on `chrY` were later used as biological sanity checks for model behavior.

---

## Why Full Occupancy in All Replicates Was Required

The second major part of the anchor rule was the requirement that the interval be occupied in **every replicate of both groups**.

### 1. Full occupancy implies strong reproducibility

An interval present in every replicate on both sides of the comparison is more likely to represent a stable shared feature than one that is only intermittently occupied.

### 2. Full occupancy reduces anchor noise

Partially occupied intervals could fluctuate into or out of the anchor set based on weaker or noisier peak support. Requiring full occupancy made the anchor set more reproducible and less sensitive to borderline loci.

### 3. Full occupancy better matches the conceptual role of a normalization baseline

A normalization anchor is supposed to represent shared signal, not just signal that happens not to fail a test. Full occupancy across all replicates gives a stronger basis for calling the region part of the shared baseline.

---

## Why a Smaller but Cleaner Anchor Set Was Preferred

This project deliberately favored a more conservative anchor set, even if that meant having fewer anchors overall.

The reasoning was that normalization is more defensible when it relies on regions that are:

- clearly shared
- clearly occupied
- unlikely to represent strong group-specific biology
- structurally stable across replicates

Thus, the project preferred anchor quality over anchor quantity.

---

## Why This Was Especially Important in the Context of Real Biological Asymmetry

This conservative anchor strategy was particularly important because the project did **not** assume that the genome-wide signal landscape was always symmetric between groups.

Some comparisons could plausibly contain:

- mark-specific asymmetry
- sex-linked differences
- broad group-skewed enrichment behavior

Under such conditions, using a permissive anchor definition would increase the risk that real biological differences are treated as normalization background.

The autosomal fully occupied anchor rule reduced that risk and therefore aligned better with the project’s broader interpretive goals.

---

## Relationship to the Occupancy Filter and Master Matrix Design

The anchor strategy also fit naturally into the larger workflow architecture.

Because the project already used:

- CPS-based feature spaces
- occupancy-aware filtering
- master matrices containing both counts and occupancy

it was straightforward to define a normalization baseline that explicitly respected occupancy structure.

This was another advantage of the master-matrix design: it allowed the workflow to distinguish clearly between:

- intervals that are testable
- intervals that are good normalization anchors

Those two sets did not have to be identical.

---

## Key Take-Home Message

Autosomal fully occupied peaks were used as MAnorm2 normalization anchors because the project needed a conservative and biologically defensible shared baseline.

This strategy:

- avoided sex-chromosome distortion
- required strong replicate-level reproducibility
- reduced the influence of unstable or partially differential loci
- helped preserve true biological asymmetry rather than absorbing it into normalization

In this project, the anchor set was intentionally designed to be smaller but cleaner, making comparison-specific normalization more interpretable and more robust.
