# Step 10: edgeR Output Summary and Organization

## Purpose

After all edgeR comparison jobs finish, the project contains many per-comparison result files. This step aggregates comparison-level summary tables and reorganizes outputs by CPS so collaborators can review results more easily.

## Scripts

```text
script/06_summary_qc/CTK4me1/organize_edgeR_outputs_CTK4me1.sh
script/06_summary_qc/CTK27ac/organize_edgeR_outputs_CTK27ac.sh
```

## Inputs

edgeR result directories:

```text
${PROJECT_ROOT}/edgeR_DE_results/CTK4me1
${PROJECT_ROOT}/edgeR_DE_results/CTK27ac
```

Quantification directories:

```text
${PROJECT_ROOT}/quantification/CTK4me1
${PROJECT_ROOT}/quantification/CTK27ac
```

PCA directories, if PCA has already been run:

```text
${PROJECT_ROOT}/PCA_edgeR/CTK4me1
${PROJECT_ROOT}/PCA_edgeR/CTK27ac
```

## Aggregated Summary Files

The organization scripts collect per-comparison CSVs into marker-level summary tables:

```text
All_Comparisons_Summary_edgeR.csv
All_Filter_Stats_edgeR.csv
All_Chromosome_Dist_edgeR.csv
```

These are moved into:

```text
${PROJECT_ROOT}/edgeR_DE_results/<MARKER>/Summary
```

## CPS-Level Organization

The scripts move comparison-level edgeR files into CPS-specific folders:

```text
${PROJECT_ROOT}/edgeR_DE_results/<MARKER>/<CPS>/
```

They also move quantification matrices and manifests into CPS-specific folders under:

```text
${PROJECT_ROOT}/quantification/<MARKER>/<CPS>/
```

If PCA files already exist, they are also organized into CPS folders under:

```text
${PROJECT_ROOT}/PCA_edgeR/<MARKER>/<CPS>/
```

## Recommended Timing

Run this step after:

1. marker-specific quantification has completed
2. all edgeR jobs have completed
3. PCA QC has completed, if PCA files should be moved into CPS folders automatically

If the organization script is run before PCA, the PCA files will still be generated later, but they will remain in the top-level PCA output directory until the organization script is run again.

## Outputs

Final organized output structure:

```text
edgeR_DE_results/<MARKER>/
├── CPS1/
├── CPS2/
├── ...
└── Summary/

quantification/<MARKER>/
├── CPS1/
├── CPS2/
└── ...

PCA_edgeR/<MARKER>/
├── CPS1/
├── CPS2/
└── ...
```
