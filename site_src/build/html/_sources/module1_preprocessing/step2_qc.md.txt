# Step 2: FASTQ QC and Adapter Trimming

## Purpose

The maintained analysis scripts assume that adapter-trimmed paired-end FASTQ files have already been generated before alignment. This step is therefore treated as an upstream preparation step for the current script repository.

The alignment scripts expect trimmed FASTQs under:

```bash
${PROJECT_ROOT}/trim_fastqs
```

with this naming pattern:

```text
<SAMPLE_ID>_R1.fastq.gz
<SAMPLE_ID>_R2.fastq.gz
```

## Recommended QC Checks

Before submitting alignment jobs, confirm:

- both R1 and R2 files exist for every sample
- file names exactly match the expected `<SAMPLE_ID>_R1.fastq.gz` and `<SAMPLE_ID>_R2.fastq.gz` pattern
- adapter trimming completed successfully
- read lengths and quality profiles are acceptable after trimming
- sample names match the downstream marker/group naming convention used in the metadata files

## Relationship to the Current Pipeline

The current repository does not contain the trimming script itself. The first maintained executable stage in this repository is alignment:

```bash
script/01_alignment/submit_alignment.sh
```

That script discovers sample IDs by listing `*_R1.fastq.gz` files in `${FASTQ_DIR}` and removing the `_R1.fastq.gz` suffix. Any mismatch in FASTQ naming will therefore propagate immediately into alignment job names and downstream BAM names.

## Output Expected by Step 3

The required input for Step 3 is:

```text
trim_fastqs/
├── <SAMPLE_ID>_R1.fastq.gz
└── <SAMPLE_ID>_R2.fastq.gz
```

These files are consumed directly by the Bowtie2 alignment scripts.
