# B6. Pairing Integrity and `profile_bins` Diagnostics

## Overview

A technically important part of the workflow was the generation of paired-end fragment count matrices using `profile_bins --paired`. Because this mode depends on correct pairing behavior, mate-name compatibility, and fragment-level integrity, the project had to take pairing quality seriously during BAM-to-BED conversion and matrix generation.

This section explains why pairing integrity mattered, what kinds of technical issues were considered, and why pairing-aware diagnostics were important for protecting the quality of the master matrix.

---

## Why Pairing Integrity Mattered in This Project

The project quantified CUT&Tag signal at the **fragment level**, not at the level of individual read ends. This distinction is important because in paired-end CUT&Tag data, the biologically meaningful unit is the DNA fragment bounded by the mate pair.

As a result, matrix generation depended on correctly reconstructing paired fragments before running `profile_bins --paired`.

If pairing integrity is compromised, then the resulting matrix may be affected by:

- mate-name mismatch
- incomplete fragment reconstruction
- technically unpaired records
- inconsistent BED formatting
- loss of usable fragments during pairing logic

Since the master matrix later became the quantitative backbone for PCA and MAnorm2, fragment pairing quality could not be treated as a trivial implementation detail.

---

## The Practical Problem: `/1` and `/2` Suffixes

A key technical issue in this project was that `bedtools bamtobed` appends mate suffixes such as `/1` and `/2` to read names.

However, `profile_bins --paired` expects both mates from the same fragment to share the same read name in a compatible paired representation.

This meant that direct BAM-to-BED conversion was not sufficient by itself. The workflow needed an additional standardization step to:

- remove `/1` and `/2`
- restore compatible mate naming
- ensure that the resulting BED file could be interpreted correctly as paired-end fragment input

This is why the BAM-to-BED preparation logic included explicit suffix stripping and pairing-aware handling rather than a naïve direct export.

---

## Why Proper-Pair Filtering Was Used Upstream

Before BED conversion, the workflow also filtered alignments to retain only high-confidence proper pairs.

This reduced the influence of:

- unmapped reads
- secondary alignments
- supplementary alignments
- structurally ambiguous pairing behavior

The goal was not simply to maximize the number of retained lines, but to maximize the number of **usable paired fragments** entering the matrix-generation stage.

In a fragment-based quantification workflow, more raw reads do not necessarily mean better matrix input if those reads are not structurally valid for pairing.

---

## Why `profile_bins` Diagnostics Were Important

The project paid attention to pairing-related diagnostics because they can reveal whether the fragment-quantification substrate is behaving as expected.

Examples of useful diagnostic concerns include:

- unexpectedly high numbers of unpaired reads
- lower-than-expected effective pairing yield
- signs that mate-name formatting is incompatible
- sample-specific irregularities in fragment construction
- possible incompatibilities between BED preparation and `profile_bins --paired`

These are not merely low-level software issues. If pairing diagnostics are poor, then the resulting master matrix may no longer reflect the true fragment structure of the CUT&Tag libraries.

---

## How Low Pairing Yield Was Interpreted

If a sample showed unexpectedly weak pairing efficiency or problematic `profile_bins` behavior, the project would interpret that first as a **technical diagnostic signal**, not immediately as biology.

Possible explanations include:

- mate-name incompatibility after BED conversion
- excessive read filtering upstream
- malformed BED structure
- library-specific pairing irregularity
- local incompatibility between generated BED files and `profile_bins --paired`

This distinction mattered because the workflow did not want to mistake preprocessing artifacts for sample-level chromatin biology.

---

## Why This Was Especially Important for the Master Matrix Design

The master matrix was designed to be reused across multiple downstream tasks:

- comparison-specific differential analysis
- CPS-level PCA
- QC review
- occupancy-aware filtering
- summary reporting

Because so many downstream outputs depended on the same matrix, pairing integrity problems at the matrix-generation stage could propagate very widely.

That is why the project treated paired-end BED preparation and `profile_bins` diagnostics as structural safeguards rather than optional engineering details.

---

## Relationship to the Move From Individual Matrices to Master Matrices

This issue also became more important after the workflow moved to CPS-level master matrices.

When one shared master matrix supports many later analyses, matrix quality becomes more critical than in a one-off comparison-specific matrix design. A flawed paired BED or a poorly paired fragment representation would not affect only one contrast; it could affect an entire CPS-level quantitative substrate.

Thus, strong pairing integrity became even more important under the final workflow architecture.

---

## Key Take-Home Message

Pairing integrity was a critical technical requirement for `profile_bins --paired` because the project quantified CUT&Tag signal at the fragment level. Correct mate-name standardization, proper-pair filtering, and pairing-aware diagnostics were essential to ensure that the master matrix reflected real fragment-level signal rather than artifacts of incompatible paired-end preprocessing.

In this project, pairing diagnostics were therefore treated as an important quality-control layer protecting the integrity of all downstream matrix-based analyses.
