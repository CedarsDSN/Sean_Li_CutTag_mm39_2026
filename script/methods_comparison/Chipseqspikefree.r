library("ChIPseqSpikeInFree")

args <- commandArgs(trailingOnly = TRUE)

metaFile_path <- args[1]
bam_list_path <- args[2]
prefix_name   <- args[3]

meta_data <- read.table(metaFile_path, header = TRUE, stringsAsFactors = FALSE)
print("--- MetaData Content ---")
print(head(meta_data))

bam_df <- read.table(bam_list_path, header = FALSE, stringsAsFactors = FALSE)
bams_vec <- as.vector(bam_df[, 1])

existing_bams <- bams_vec[file.exists(bams_vec)]
if (length(existing_bams) != length(bams_vec)) {
  missing <- bams_vec[!file.exists(bams_vec)]
  print("Missing files:")
  print(missing)
  stop("部分 BAM 文件不存在，请检查路径！")
}

print(paste("Processing", length(bams_vec), "BAM files..."))

ChIPseqSpikeInFree(
    bamFiles = bams_vec, 
    chromFile = "/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/GRCm39.chrom.sizes", 
    metaFile = metaFile_path, 
    ncores = 2, 
    prefix = prefix_name
)

