#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH -p defq
#SBATCH -t 80:00:00
#SBATCH --mem=64GB
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=yizhou.wang@cshs.org
#SBATCH -o /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/log/%x_%j.log

source /common/compbiomed-dsn/anaconda3/anaconda/etc/profile.d/conda.sh
conda activate /common/compbiomed-dsn/anaconda3/anaconda/envs/CnT_env
module load samtools
Genome_Ref="/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/Bowtie2Index/GRCm39"
trim_fastq_path="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/trim_fastqs"
bam_path="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam"

mkdir -p /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam

SAMPLE_ID=$1

bowtie2 --dovetail --very-sensitive-local -p 10 --no-unal --no-mixed --no-discordant --phred33 -I 10 -X 700 -x $Genome_Ref -1 $trim_fastq_path/${SAMPLE_ID}_R1.fastq.gz -2 $trim_fastq_path/${SAMPLE_ID}_R2.fastq.gz 2>$bam_path/${SAMPLE_ID}_bowtie2.log|samtools sort -@ 4 -o $bam_path/${SAMPLE_ID}.coordsorted.bam -

samtools index $bam_path/${SAMPLE_ID}.coordsorted.bam 
