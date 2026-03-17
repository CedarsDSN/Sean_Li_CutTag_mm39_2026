library(MAnorm2)
library(ggplot2)
library(ggrepel)

# --- 1. Path configuration ---
master_dir <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/manorm2_master_counts"
out_dir <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/PCA_master"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

all_matrix_files <- list.files(master_dir, pattern = "_master_counts_profile_bins\\.xls$", full.names = TRUE)

if (length(all_matrix_files) == 0) {
  stop(paste("No master matrix files found in:", master_dir))
}

message(paste("Detected", length(all_matrix_files), "master matrices. Starting PCA generation..."))

# --- 2. Parameters ---
min_mean_count <- 10
min_global_occupancy <- 2
top_n_variable_peaks <- 2000
min_peaks_required <- 2000

# --- 3. Main PCA loop ---
for (mat_file in all_matrix_files) {

  cps_id <- sub(".*(CPS[0-9]+)_master_counts_profile_bins\\.xls$", "\\1", basename(mat_file))
  message(paste("\nProcessing:", cps_id))

  data <- read.table(mat_file, header = TRUE, sep = "\t", check.names = FALSE)
  data <- data[!(data$chrom %in% c("chrM", "chrUn")) & !grepl("_random", data$chrom), ]

  count_cols <- grep("read_cnt$", colnames(data), value = TRUE)
  occ_cols   <- grep("occupancy$", colnames(data), value = TRUE)
  sample_names <- gsub("\\.read_cnt$", "", count_cols)

  if (length(count_cols) == 0 || length(count_cols) != length(occ_cols)) {
    message("WARNING: ", cps_id, " has empty or mismatched count/occupancy columns. Skipping.")
    next
  }

  raw_counts <- data[, count_cols, drop = FALSE]
  raw_occ    <- data[, occ_cols, drop = FALSE]

  raw_mean <- rowMeans(raw_counts, na.rm = TRUE)
  global_occ_sum <- rowSums(raw_occ, na.rm = TRUE)

  keep_idx <- (raw_mean > min_mean_count) & (global_occ_sum >= min_global_occupancy)
  data_filtered <- data[keep_idx, , drop = FALSE]

  if (nrow(data_filtered) < min_peaks_required) {
    message(paste("WARNING:", cps_id, "has too few high-confidence peaks (", nrow(data_filtered), "). Skipping PCA."))
    next
  }

  message(paste("  Retained", nrow(data_filtered), "high-confidence peaks. Running normalization..."))

  norm_data <- MAnorm2::normalize(data_filtered, count = count_cols, occupancy = occ_cols)
  pca_input_full <- norm_data[, count_cols, drop = FALSE]

  row_vars <- apply(pca_input_full, 1, var, na.rm = TRUE)
  top_peaks <- order(row_vars, decreasing = TRUE)[seq_len(top_n_variable_peaks)]
  pca_input <- pca_input_full[top_peaks, , drop = FALSE]

  pca_res <- prcomp(t(pca_input), scale. = FALSE)
  pc_var <- pca_res$sdev^2
  pc_per <- round(pc_var / sum(pc_var) * 100, 1)

  pca_df <- as.data.frame(pca_res$x[, 1:3, drop = FALSE])
  pca_df$Sample <- sample_names
  pca_df$Group <- sub("_[0-9]+\\.rmdup$", "", pca_df$Sample)
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
    ggtitle(paste0("PCA of ", cps_id, " (PC1 vs PC2)")) +
    my_theme

  p13 <- ggplot(pca_df, aes(x = PC1, y = PC3, color = Group, label = Sample)) +
    geom_point(size = 5, alpha = 0.8) +
    geom_text_repel(size = 3, show.legend = FALSE, max.overlaps = 20) +
    xlab(paste0("PC1 (", pc_per[1], "%)")) +
    ylab(paste0("PC3 (", pc_per[3], "%)")) +
    ggtitle(paste0("PCA of ", cps_id, " (PC1 vs PC3)")) +
    my_theme

  p23 <- ggplot(pca_df, aes(x = PC2, y = PC3, color = Group, label = Sample)) +
    geom_point(size = 5, alpha = 0.8) +
    geom_text_repel(size = 3, show.legend = FALSE, max.overlaps = 20) +
    xlab(paste0("PC2 (", pc_per[2], "%)")) +
    ylab(paste0("PC3 (", pc_per[3], "%)")) +
    ggtitle(paste0("PCA of ", cps_id, " (PC2 vs PC3)")) +
    my_theme

  output_pdf <- file.path(out_dir, paste0(cps_id, "_PCA.pdf"))
  pdf(output_pdf, width = 8, height = 6)
  print(p12)
  print(p13)
  print(p23)
  dev.off()

  message(paste("  Successfully generated:", output_pdf))
}

message(paste("\nAll MAnorm2-based PCA plots completed. Output directory:", out_dir))
