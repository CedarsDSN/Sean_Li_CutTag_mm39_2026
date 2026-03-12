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

bam_path="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/bam"
qc_path="/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/qc"

mkdir -p /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/qc

CHRS=$(samtools view -H $bam_path/${1}.coordsorted.bam | grep "^@SQ" | cut -f2 | sed 's/SN://' | grep -v "chrM")

samtools view -b -f 2 -q 10 $bam_path/${1}.coordsorted.bam $CHRS > $bam_path/${1}.filter.bam

picard -Xmx48g MarkDuplicates \
    -I $bam_path/${1}.filter.bam \
    -O $bam_path/${1}.rmdup.bam \
    -REMOVE_DUPLICATES true \
    -METRICS_FILE $qc_path/${1}.rmDups.metrics.txt

samtools index $bam_path/${1}.rmdup.bam
samtools flagstat $bam_path/${1}.rmdup.bam > $qc_path/${1}.rmdup.stats

rm $bam_path/${1}.filter.bam

#samtools view -bu -f2 $bam_path/$1.coordsorted.bam | samtools view -b -q 10 - | samtools sort - -o $bam_path/$1.filter.MAPQ10.sorted.bam
#picard MarkDuplicates -I $bam_path/$1.filter.MAPQ10.sorted.bam -O $bam_path/$1.filter.MAPQ10.NoDups.bam -REMOVE_DUPLICATES true -METRICS_FILE $qc_path/$1.rmDups
#samtools flagstat $bam_path/$1.filter.MAPQ10.NoDups.bam > $qc/$1.filter.stats
#samtools index $bam_path/$1.filter.MAPQ10.NoDups.bam
#bamCoverage --bam $bam_path/$1.filter.MAPQ10.NoDups.bam -o $bw_path/$1.bw --blackListFileName $ref_path/blacklist.bed --binSize 10 --ignoreForNormalization 'chrM' --extendReads
#bamCoverage --bam $bam_path/$1.filter.MAPQ10.NoDups.bam --outFileFormat bedgraph -o $bw_path/$1.bedgraph  --blackListFileName $ref_path/blacklist.bed --binSize 10 --ignoreForNormalization 'chrM' --extendReads



