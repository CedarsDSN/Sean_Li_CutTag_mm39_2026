# Step 1: Reference Genome & Annotation Build Up

## Overview
A clean and accurately annotated reference is the foundation of any robust CUT&Tag pipeline. For this project, we transitioned to the **Mouse GRCm39 (mm39)** assembly and adopted the highly comprehensive **GENCODE vM38** annotation. 

This step details how we filtered the raw genome and annotation files to create a customized, high-signal-to-noise reference environment.

---

## 1. Genome Preparation (Primary Chromosomes Only)

The raw GRCm39 genome from GENCODE contains hundreds of unlocalized scaffolds, unplaced contigs, and alternate alleles. Aligning reads to these extra sequences often leads to severe multi-mapping issues and dilutes the statistical power of peak calling.

To prevent this, we strictly filtered the original FASTA file to retain **only the primary assembly** (chr1-19, chrX, chrY, and chrM). 

Here are the key commands to build the essential indices for downstream alignment (`Bowtie2`) and feature extraction (`samtools`):

```bash
# 1. Build Bowtie2 index for alignment
bowtie2-build GRCm39.primary_assembly.genome.fa GRCm39

# 2. Build FASTA index for fast sequence retrieval
samtools faidx GRCm39.primary_assembly.genome.fa
```
## 2. Annotation Filtering (GENCODE GTF)

The complete GENCODE vM38 GTF contains over 40 different gene biotypes (including various pseudogenes, TECs, snRNAs, etc.). Including all these biotypes heavily clutters downstream differential analysis and frequently results in "NA" hits when annotating H3K27ac/H3K4me1 peaks.

Based on our biological focus, we heavily filtered the raw GTF to strictly retain only the following three gene types:

* **`protein_coding`**
* **`lncRNA`**
* **`miRNA`**

The precise `awk` command used to generate this customized annotation track (while safely preserving the standard GTF header lines):

```bash
# Filter the raw GTF for the three specific biotypes and keep headers
zcat gencode.vM38.annotation.gtf.gz | awk '
  $0 ~ /^#/ { print $0; next }
  $0 ~ /gene_type "protein_coding"/ || $0 ~ /gene_type "lncRNA"/ || $0 ~ /gene_type "miRNA"/ { print $0 }
' > gencode.vM38.pc_lnc_miRNA.gtf
```
### Resulting Output
This filtering process resulted in our streamlined annotation file: `gencode.vm38.pc_lnc_miRNA.sorted.gtf.gz`. By mapping our peaks strictly back to this curated GTF, we successfully eliminated the "NA" gene symbols in the final reports, ensuring every significant peak is mapped to a highly confident, biologically meaningful feature.
