# Step 3: Alignment

## Overview
Trimmed paired-end reads are aligned to the customized GRCm39 reference genome using **Bowtie2**. To optimize computational efficiency and save disk space, the alignment output is piped directly into `samtools sort` to generate coordinate-sorted BAM files on the fly, bypassing the creation of bulky intermediate SAM files.

## Script & Execution
The core alignment commands are encapsulated in a shell script named `alignment.sh`. Since this is a compute-intensive step, the jobs are submitted to the High-Performance Computing (HPC) cluster using a Slurm submission script named `1_sub_alignment_slurm.sh`.

Here is the core command executed for the primary genome alignment:

```bash
# Define paths (configured in the wrapper script)
# Genome_Ref="path/to/GRCm39"
# trim_fastq_path="path/to/trim_fastqs"
# bam_path="path/to/alignment_bams"

# 1. Align and directly sort by coordinate
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
  -x $Genome_Ref \
  -1 $trim_fastq_path/${SAMPLE_ID}_R1.fastq.gz \
  -2 $trim_fastq_path/${SAMPLE_ID}_R2.fastq.gz \
  2> $bam_path/${SAMPLE_ID}_bowtie2.log | \
  samtools sort -@ 4 -o $bam_path/${SAMPLE_ID}.coordsorted.bam -

# 2. Index the sorted BAM file
samtools index $bam_path/${SAMPLE_ID}.coordsorted.bam
```

## Key Parameter Rationale
The alignment parameters are specifically tailored for CUT&Tag libraries:

* **`--dovetail`**: Tn5 transposase can generate fragments shorter than the sequencing read length. This flag allows Bowtie2 to consider these "dovetailing" pairs as valid, concordant alignments.
* **`--very-sensitive-local`**: Uses local alignment to softly clip adapters or low-quality bases, maximizing the mapping rate.
* **`--no-unal`, `--no-mixed`, `--no-discordant`**: Enforces strict filtering at the alignment stage, outputting only reads where *both* mates align successfully and correctly.
* **`-I 10 -X 700`**: Defines the valid fragment length bounds (10bp to 700bp).

---

## Spike-in Alignment Assessment
Standard CUT&Tag protocols often introduce an exogenous spike-in DNA (e.g., *E. coli*) for downstream data normalization. To evaluate this, we performed a parallel alignment against the spike-in reference genome using a batch submission loop:

```bash
# Loop through all trimmed fastq files and submit spike-in alignment jobs
SAMPLES=$(ls $FASTQ_DIR/*_R1.fastq.gz | xargs -n 1 basename | sed 's/_R1.fastq.gz//')

for SAMPLE in $SAMPLES
do
    echo "Submitting sample: $SAMPLE"
    sbatch --job-name="aln_$SAMPLE" ./alignment_spike.sh $SAMPLE
done
```

### Observation & Conclusion
Upon reviewing the alignment logs from the `alignment_spike.sh` runs, we observed that the **spike-in alignment rates were extremely low** across the samples. 

We can safely assume that the exogenous spike-in was either omitted during the experimental protocol or was present at negligible levels. Consequently, we concluded that utilizing spike-in normalization factors is biologically unsupported for this specific dataset. Downstream visualization and quantification will instead rely on highly robust within-sample normalization methods (such as CPM).

## Output
The final outputs for the primary analysis are the cleanly aligned, coordinate-sorted BAM files (`.coordsorted.bam`), their indices (`.coordsorted.bam.bai`), and the alignment logs, all stored in the designated BAM output folder.
