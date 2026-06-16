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

genome_amp="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/old/Spikein_indices/Amp_pbluescript/Amp_index/Amp_pBlue"
genome_ecoli="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/old/Spikein_indices/EcoliK12_index/EcoliK12Index/EcoliK12"
trim_fastq_path="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/trim_fastqs"
bam_spikein_path="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam_spike"

bowtie2 --very-sensitive-local --no-overlap --no-dovetail --no-mixed --no-discordant --phred33 -I 10 -X 700 -x $genome_amp -1 $trim_fastq_path/${1}_R1.fastq.gz -2 $trim_fastq_path/${1}_R2.fastq.gz 2> $bam_spikein_path/${1}_amp_bowtie2.log | samtools view -bS - > $bam_spikein_path/${1}.amp.bam
bowtie2 --very-sensitive-local --no-overlap --no-dovetail --no-mixed --no-discordant --phred33 -I 10 -X 700 -x $genome_ecoli -1 $trim_fastq_path/${1}_R1.fastq.gz -2 $trim_fastq_path/${1}_R2.fastq.gz 2> $bam_spikein_path/${1}_ecoli_bowtie2.log | samtools view -bS - > $bam_spikein_path/${1}.ecoli.bam

