# Step 3: Alignment

## Purpose

Trimmed paired-end CUT&Tag reads are aligned to the mm39 reference genome with Bowtie2. The alignment output is streamed directly into `samtools sort` to create coordinate-sorted BAM files without writing intermediate SAM files.

## Scripts

```text
script/01_alignment/submit_alignment.sh
script/01_alignment/run_alignment.sh
```

Optional spike-in assessment scripts:

```text
script/01_alignment/submit_alignment_spikein.sh
script/01_alignment/run_alignment_spikein.sh
```

## Inputs

The scripts read FASTQs from:

```bash
${PROJECT_ROOT}/trim_fastqs
```

Expected file names:

```text
<SAMPLE_ID>_R1.fastq.gz
<SAMPLE_ID>_R2.fastq.gz
```

The mm39 Bowtie2 index is configured in:

```text
script/config/project_config.sh
```

Current reference variable:

```bash
GENOME_REF="/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/Bowtie2Index/GRCm39"
```

## Main Command

The primary alignment command in `run_alignment.sh` is:

```bash
bowtie2 \
    --dovetail \
    --very-sensitive-local \
    -p 10 \
    --no-unal \
    --no-mixed \
    --no-discordant \
    --phred33 \
    -I 10 \
    -X 700 \
    -x "$GENOME_REF" \
    -1 "$R1" \
    -2 "$R2" \
    2> "$LOG_OUT" | \
samtools sort -@ 4 -o "$BAM_OUT" -

samtools index "$BAM_OUT"
```

## Parameter Rationale

- `--dovetail`: allows short CUT&Tag fragments where mates can overlap or dovetail.
- `--very-sensitive-local`: improves alignment sensitivity while allowing soft clipping.
- `--no-unal`, `--no-mixed`, `--no-discordant`: keeps the BAM focused on concordant paired alignments.
- `-I 10 -X 700`: defines the accepted fragment-size range.

## Outputs

For each sample, alignment produces:

```text
${PROJECT_ROOT}/bam/<SAMPLE_ID>.coordsorted.bam
${PROJECT_ROOT}/bam/<SAMPLE_ID>.coordsorted.bam.bai
${PROJECT_ROOT}/bam/<SAMPLE_ID>_bowtie2.log
```

## Spike-in Branch

The repository keeps a separate spike-in alignment branch for Amp/pBlueScript and E. coli assessment. These outputs are written to:

```bash
${PROJECT_ROOT}/bam_spike
```

This branch is useful for evaluating possible exogenous signal, but the current maintained differential workflow does not depend on spike-in normalization.
