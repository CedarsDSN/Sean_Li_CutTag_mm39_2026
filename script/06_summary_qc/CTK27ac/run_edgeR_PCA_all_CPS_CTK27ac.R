library(edgeR)
library(ggplot2)
library(ggrepel)

# =========================================================
# 1. Path configuration
# =========================================================
quant_dir <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/quantification/CTK27ac"
out_dir <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/PCA_edgeR/CTK27ac"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

all_matrix_files <- list.files(
  quant_dir,
  pattern = "^CPS[0-9]+_macs3_per_sample_summit_profile_bins\\.xls$",
  full.names = TRUE
)

if (length(all_matrix_files) == 0) {
  stop(paste("No quantification matrix files found in:", quant_dir))
}

message(paste("Detected", length(all_matrix_files), "quantification matrices. Starting PCA generation..."))

# =========================================================
# 2. Parameters
# =========================================================
top_n_variable_peaks <- 2000
min_peaks_required <- 2000

# =========================================================
# 3. Main PCA loop
# =========================================================
for (mat_file in all_matrix_files) {

  cps_id <- sub(".*(CPS[0-9]+)_macs3_per_sample_summit_profile_bins\\.xls$", "\\1", basename(mat_file))
  message(paste("\nProcessing:", cps_id))

  data <- read.table(
    mat_file,
    header = TRUE,
    sep = "\t",
    check.names = FALSE,
    stringsAsFactors = FALSE,
    quote = "",
    comment.char = ""
  )

  data <- data[!(data$chrom %in% c("chrM", "chrUn")) & !grepl("_random", data$chrom), , drop = FALSE]

  count_cols <- grep("\\.read_cnt$", colnames(data), value = TRUE)

  if (length(count_cols) == 0) {
    message("WARNING: ", cps_id, " has no count columns. Skipping.")
    next
  }

  sample_names <- sub("\\.read_cnt$", "", count_cols)
  group_names <- sub("_[12]$", "", sample_names)

  count_mat <- as.matrix(data[, count_cols, drop = FALSE])
  rownames(count_mat) <- paste(data$chrom, data$start, data$end, sep = "_")
  colnames(count_mat) <- sample_names

  group <- factor(group_names)
  design <- model.matrix(~ 0 + group)

  y <- DGEList(counts = count_mat, group = group)

  keep <- filterByExpr(y, design = design)
  count_mat_filt <- count_mat[keep, , drop = FALSE]

  if (nrow(count_mat_filt) < min_peaks_required) {
    message(paste("WARNING:", cps_id, " has too few retained peaks after filterByExpr (", nrow(count_mat_filt), "). Skipping PCA."))
    next
  }

  message(paste("  Retained", nrow(count_mat_filt), "peaks after filterByExpr. Running TMM normalization..."))

  y <- DGEList(counts = count_mat_filt, group = group)
  y <- calcNormFactors(y)

  logcpm <- cpm(y, log = TRUE, prior.count = 2)

  row_vars <- apply(logcpm, 1, var, na.rm = TRUE)
  top_n_use <- min(top_n_variable_peaks, nrow(logcpm))
  top_peaks <- order(row_vars, decreasing = TRUE)[seq_len(top_n_use)]
  pca_input <- logcpm[top_peaks, , drop = FALSE]

  pca_res <- prcomp(t(pca_input), scale. = FALSE)
  pc_var <- pca_res$sdev^2
  pc_per <- round(pc_var / sum(pc_var) * 100, 1)

  pca_df <- as.data.frame(pca_res$x[, 1:3, drop = FALSE])
  pca_df$Sample <- sample_names
  pca_df$Group <- group_names

  my_theme <- theme_bw() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      legend.position = "right",
      legend.title = element_blank(),
      panel.grid.minor = element_blank()
    )

  p12 <- ggplot(pca_df, aes(x = PC1, y = PC2, color = Group, label = Sample)) +
    geom_point(size = 5, alpha = 0.8) +
    geom_text_repel(size = 3, show.legend = FALSE, max.overlaps = 20) +
    xlab(paste0("PC1 (", pc_per[1], "%)")) +
    ylab(paste0("PC2 (", pc_per[2], "%)")) +
    ggtitle(paste0("edgeR PCA of ", cps_id, " (PC1 vs PC2)")) +
    my_theme

  p13 <- ggplot(pca_df, aes(x = PC1, y = PC3, color = Group, label = Sample)) +
    geom_point(size = 5, alpha = 0.8) +
    geom_text_repel(size = 3, show.legend = FALSE, max.overlaps = 20) +
    xlab(paste0("PC1 (", pc_per[1], "%)")) +
    ylab(paste0("PC3 (", pc_per[3], "%)")) +
    ggtitle(paste0("edgeR PCA of ", cps_id, " (PC1 vs PC3)")) +
    my_theme

  p23 <- ggplot(pca_df, aes(x = PC2, y = PC3, color = Group, label = Sample)) +
    geom_point(size = 5, alpha = 0.8) +
    geom_text_repel(size = 3, show.legend = FALSE, max.overlaps = 20) +
    xlab(paste0("PC2 (", pc_per[2], "%)")) +
    ylab(paste0("PC3 (", pc_per[3], "%)")) +
    ggtitle(paste0("edgeR PCA of ", cps_id, " (PC2 vs PC3)")) +
    my_theme

  output_pdf <- file.path(out_dir, paste0(cps_id, "_edgeR_PCA.pdf"))
  pdf(output_pdf, width = 8, height = 6)
  print(p12)
  print(p13)
  print(p23)
  dev.off()

  message(paste("  Successfully generated:", output_pdf))
}

message(paste("\nAll edgeR-based PCA plots completed. Output directory:", out_dir))
