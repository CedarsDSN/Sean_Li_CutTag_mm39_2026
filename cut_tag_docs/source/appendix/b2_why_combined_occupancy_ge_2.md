# B2. Why the Occupancy Filter Was Set to Combined Occupancy >= 2

## Overview

One important filtering decision in the MAnorm2 workflow was to require that each retained interval show occupancy support in at least two replicates across the two comparison groups combined.

In code, the core logic was:

```r
occupancy_keep <- (occ_n_g1 + occ_n_g2) >= 2
```

At first glance, this may look like a simple thresholding rule. In practice, however, it reflects an important balance between:

- sensitivity to biologically meaningful differential loci
- resistance to single-replicate noise
- reproducibility-aware interval retention
- compatibility with limited replicate numbers

This section explains why the project chose a combined occupancy threshold of `>= 2`, rather than a weaker or stricter alternative.

---

## What the Rule Actually Means

The rule does **not** require:

- at least two occupied replicates in each group
- or at least two occupied replicates within one specific group

Instead, it requires that across both comparison groups combined, the interval must be supported by at least two occupancy calls in total.

This means that all of the following patterns would pass the filter:

- 2 occupied replicates in Group 1 and 0 in Group 2
- 0 occupied replicates in Group 1 and 2 in Group 2
- 1 occupied replicate in Group 1 and 1 in Group 2

Thus, the rule is intentionally compatible with true group-specific biology while still requiring more than one total occupancy event.

---

## Why `>= 2` Was Chosen Instead of `>= 1`

A natural alternative would have been:

```r
occupancy_keep <- (occ_n_g1 + occ_n_g2) >= 1
```

This would have retained any interval supported by even a single occupied replicate across the whole comparison.

The project did **not** adopt that rule because it would have allowed too many weakly supported intervals into downstream analysis.

### 1. A single occupied replicate is too easy to obtain by noise

If only one replicate needs to show occupancy, then an interval can enter formal analysis even if it is driven by:

- a weak borderline peak
- a single noisy sample
- an outlier-like library
- unstable local behavior

This would lower the reproducibility standard too much for the project’s main analysis.

### 2. A threshold of `>= 1` would increase downstream noise burden

Permitting single-replicate-supported intervals would likely increase:

- the number of tested intervals
- the number of weak or unstable loci entering the matrix
- the burden on later mean/count/CV filtering
- the multiple-testing burden in the final statistical analysis

The workflow was designed to avoid shifting too much quality-control burden downstream.

### 3. The project wanted at least minimal reproducibility evidence

Requiring combined occupancy `>= 2` establishes that the interval is not supported by only one isolated peak call. This is still a modest threshold, but it is meaningfully more reproducible than `>= 1`.

---

## Why the Filter Was Not Made Stricter

At the other extreme, the workflow could have required something stronger, such as:

- two occupied replicates in each group
- or complete occupancy in all replicates across both groups

The project did **not** adopt such a strict rule because it would have suppressed biologically plausible group-specific regions.

### 1. True differential regions may be occupied only on one side of the comparison

In CUT&Tag differential analysis, many biologically meaningful loci are expected to be:

- occupied in one group
- weak or absent in the other group

A strict per-group occupancy rule would penalize exactly the kind of signal the differential analysis is intended to detect.

### 2. The project wanted to preserve sensitivity to asymmetric biology

The combined occupancy rule allows loci to be retained if they are reproducibly present in one group but absent in the other. This is especially important in:

- sex-linked comparisons
- strong condition-specific regulatory regions
- mark-specific enrichment differences

Thus, the rule supports differential biology better than a rigid symmetric occupancy requirement would.

---

## Why Occupancy Was Used At All

One might also ask why occupancy needed to be included in the filter at all, given that count-based filters were already present.

The answer is that occupancy connects the formal quantitative matrix back to the original peak-calling evidence.

An interval in a CPS or master matrix can exist structurally even if it is only weakly supported in a given comparison. By requiring occupancy support, the workflow ensures that formally tested intervals retain at least some direct connection to the original sample-level peak calls.

This was especially important in a project where:

- CPS intervals are constructed by merging sample-level peaks
- master matrices may contain broad feature universes
- not every matrix row is equally convincing for every comparison

Occupancy filtering helped ensure that later testing focused on intervals with at least modest direct peak support.

---

## Why This Rule Fit the Replicate Structure of the Project

This project often operated with relatively limited replicate numbers per group. Under that condition, the occupancy threshold had to be strong enough to reduce noise, but not so strict that real differential loci would be systematically discarded.

Combined occupancy `>= 2` was therefore a practical compromise:

- stronger than single-replicate permissiveness
- weaker than symmetric full-group reproducibility
- compatible with truly group-skewed loci
- appropriate for limited but nontrivial replicate structure

This made it a better fit for the project’s actual design than either a looser or stricter alternative.

---

## Relationship to Other Filters

The occupancy rule was only one component of the project’s multi-layer filtering strategy.

It worked together with:

- bottom-count filtering
- mean-count thresholds
- variance/CV filtering

Thus, occupancy `>= 2` was not expected to solve all filtering needs alone. Instead, it served as the **reproducibility-support layer** within a broader quality-control framework.

This is important because it means the project did not rely on occupancy alone to define confidence. Rather, it used occupancy as one essential safeguard against structurally weak intervals.

---

## Key Take-Home Message

The occupancy filter was set to combined occupancy `>= 2` because the project needed a rule that was:

- stricter than one-replicate permissiveness
- less restrictive than symmetric per-group occupancy
- compatible with true group-specific biology
- appropriate for limited replicate counts

This threshold provided a practical balance between reproducibility and sensitivity, ensuring that intervals entering formal differential analysis had at least modest peak-level support without excluding biologically meaningful asymmetric signal.
