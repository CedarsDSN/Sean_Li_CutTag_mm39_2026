# Step 4: BAM Processing & Quality Filtering

## Overview
Raw alignment BAM files contain artifacts such as multi-mapped reads, mitochondrial DNA (chrM), and PCR duplicates. To ensure high-confidence peak calling and accurate quantification, we strictly filter the BAM files to retain only uniquely mapped, properly paired reads originating from the nuclear genome.

## Script & Execution
The following core processing steps are executed via a shell script taking the sample name (`${1}`) as an argument. It performs dynamic chromosome extraction, mapping quality filtering, and duplicate removal sequentially.

```bash
# Define paths
# bam_path="/path/to/alignment_bams"
# qc_path="/path/to/qc_reports"

mkdir -p $qc_path

# 1. Dynamically extract all chromosome names from the BAM header, strictly excluding the mitochondrial genome (chrM)
CHRS=$(samtools view -H $bam_path/${1}.coordsorted.bam | grep "^@SQ" | cut -f2 | sed 's/SN://' | grep -v "chrM")

# 2. Filter BAM: Keep only properly paired reads (-f 2) with MAPQ >= 10 (-q 10), and only on the valid chromosomes extracted above
samtools view -b -f 2 -q 10 $bam_path/${1}.coordsorted.bam $CHRS > $bam_path/${1}.filter.bam

# 3. Mark and physically remove PCR duplicates using Picard
picard -Xmx48g MarkDuplicates \
    -I $bam_path/${1}.filter.bam \
    -O $bam_path/${1}.rmdup.bam \
    -REMOVE_DUPLICATES true \
    -METRICS_FILE $qc_path/${1}.rmDups.metrics.txt

# 4. Index the final clean BAM and generate mapping statistics
samtools index $bam_path/${1}.rmdup.bam
samtools flagstat $bam_path/${1}.rmdup.bam > $qc_path/${1}.rmdup.stats

# 5. Clean up the intermediate filtered BAM to save disk space
rm $bam_path/${1}.filter.bam
```

## Key Filtering Rationale

* **Mitochondrial DNA Removal (`grep -v "chrM"`)**: The mitochondrial genome is highly accessible, devoid of true chromatin/histones, and often highly abundant. If not removed, chrM reads will artificially inflate the library size and skew normalization metrics.
* **Proper Pairing & Quality (`-f 2 -q 10`)**: 
  * `-f 2`: Retains only reads mapped as a "proper pair" based on the fragment length constraints defined in Bowtie2.
  * `-q 10`: Removes reads with low mapping confidence, effectively eliminating multi-mapped reads that align to repetitive regions of the genome.
* **PCR Duplicate Removal (`Picard MarkDuplicates`)**: While CUT&Tag can naturally produce identical fragments due to specific Tn5 insertion hotspots, high duplication rates typically indicate PCR over-amplification during library prep. Physically removing them (`-REMOVE_DUPLICATES true`) prevents highly amplified loci from dominating the differential analysis.

---

### ⚠️ Troubleshooting Note: Picard Versioning & Read Groups
If you are running **Picard version 3.x or newer**, the `MarkDuplicates` command may crash with a strict validation error complaining about missing **Read Group (`@RG`)** tags. This happens because Bowtie2 does not append `@RG` tags by default.

**Solutions to bypass this error:**
1. **Downgrade Picard**: Use a Picard 2.x version, which handles missing read groups more gracefully.
2. **Reduce Stringency**: Add `VALIDATION_STRINGENCY=LENIENT` or `VALIDATION_STRINGENCY=SILENT` to your Picard command to force it to ignore the missing tags.
3. **Add Read Groups**: If your downstream pipeline strictly requires them, use Picard's `AddOrReplaceReadGroups` tool on the BAM file *before* running `MarkDuplicates`.

## Output
The final, pristine files ready for downstream peak calling and visualization are the `.rmdup.bam` files and their `.bai` indices. Quality control metrics are saved in the `$qc_path` directory.
