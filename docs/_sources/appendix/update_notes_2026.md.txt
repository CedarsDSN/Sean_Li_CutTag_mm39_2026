# 2026 Current-Code Documentation Update

## Current Source of Truth

The documentation has been updated to follow the scripts currently present under:

```text
script/
```

The active workflow is no longer described as a MAnorm2-centered pipeline. The maintained differential analysis branch currently uses edgeR.

## Current Maintained Pipeline

```text
FASTQ
  -> Bowtie2 mm39 alignment
  -> proper-pair, MAPQ, chrM, duplicate, and blacklist filtering
  -> final *.rmdup.blfilter.bam
  -> paired BED conversion for profile_bins --paired
  -> marker-specific peak/feature definition
  -> marker-specific profile_bins quantification
  -> edgeR differential enrichment analysis
  -> summary organization and PCA QC
```

## Marker-Specific Branches

CTK4me1:

```text
SEACR bedGraph peak calling
  -> CPS consensus peak generation
  -> profile_bins over CPS consensus bins
  -> edgeR
```

CTK27ac:

```text
MACS3 BAMPE peak calling
  -> profile_bins using MACS3 narrowPeak and summit files
  -> edgeR
```

## Removed from the Active Narrative

The following topics may still exist in historical appendix or legacy pages, but they are not the active maintained workflow described by the current scripts:

- MAnorm2 differential enrichment analysis
- MAnorm2 normalization anchors
- a maintained BigWig generation stage
- a maintained H3K27me3 branch
- old stage numbering with `03_signal_generation`, `05_quantification`, or `07_summary_qc`

## Current Caveats

- `Metadata_Comparison.csv` is the active metadata file used by most current scripts.
- At the time of this update, the checked-in `Metadata_Comparison.csv` contains CTK4me1 comparisons.
- CTK27ac scripts also read `Metadata_Comparison.csv`; CTK27ac rows must be present there before running the CTK27ac branch, or the scripts should be adjusted to use `Metadata_CTK27ac_Comparison.csv`.
- The current CTK4me1 branch depends on SEACR-ready bedGraph files under `${PROJECT_ROOT}/seacr_bedgraph/CTK4me1`; the maintained script directory does not currently include a separate BigWig or bedGraph-generation stage.
