# Step 2: Quality Control & Adapter Trimming

## Overview
This project utilizes a **50x50 paired-end (PE50)** sequencing strategy. In CUT&Tag experiments, the Tn5 transposase occasionally generates very short DNA fragments. If a fragment is shorter than the 50bp read length, the sequencer will "read through" and sequence the artificial adapter at the other end. Therefore, strict adapter trimming is required before alignment.

## Tool Selection
We use **`cutadapt`** to robustly identify and remove adapter sequences from both forward (R1) and reverse (R2) reads.

## Execution Command
Here is the core command template used for trimming across all samples:

```bash
# Define the adapter sequences (e.g., Nextera/Tn5 adapters)
PRIMERS="CTGTCTCTTATACACATCT"

# Run cutadapt for PE50 reads
cutadapt \
  --minimum-length 30 \
  -a $PRIMERS \
  -A $PRIMERS \
  -o trim_fastqs/<sample_name>_trim_R1.fastq.gz \
  -p trim_fastqs/<sample_name>_trim_R2.fastq.gz \
  <sample_name>.R1.fastq.gz \
  <sample_name>.R2.fastq.gz \
  > trim_fastqs/<sample_name>_trim.log
```
### Output
All the resulting trimmed FASTQ files and their corresponding trimming log files are organized and saved in the **/trim_fastqs** folder for downstream processing.
