library(edgeR)
library(ChIPseeker)
library(GenomicRanges)
library(GenomicFeatures)

# =========================================================
# 1. Receive SLURM Array ID
# =========================================================
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("Need task ID")
task_id <- as.numeric(args[1])

# =========================================================
# 2. Path configuration
# =========================================================
txdb <- loadDb("/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/mm39_vM38_pc_lnc_miRNA.sqlite")
gene_map <- readRDS("/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/GENCODE_vM38_GeneMap.rds")

metadata_file <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/metadata_form/Metadata_Comparison.csv"
quant_dir <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/quantification/CTK4me1"
output_dir <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/edgeR_DE_results/CTK4me1"

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

qc_pdf_dir <- file.path(output_dir, "edgeR_QC_Plots")
dir.create(qc_pdf_dir, showWarnings = FALSE, recursive = TRUE)

# =========================================================
# 3. Parameter configuration
# =========================================================
metadata <- read.csv(metadata_file, stringsAsFactors = FALSE, check.names = FALSE)
metadata <- metadata[metadata$histone_marker == "CTK4me1", , drop = FALSE]

if (task_id > nrow(metadata)) stop("Task ID out of range")

min_occ_n <- 2

# =========================================================
# 4. Define single-comparison function
# =========================================================
process_edgeR_comp <- function(row_data) {
  comp_id <- trimws(as.character(row_data[["comp"]]))
  cps_id <- trimws(as.character(row_data[["Concensus_peak"]]))
  g1_name <- trimws(as.character(row_data[["group1"]]))
  g2_name <- trimws(as.character(row_data[["group2"]]))
  histone_mark <- trimws(as.character(row_data[["histone_marker"]]))

  histone_label <- gsub("[^A-Za-z0-9._-]", "_", histone_mark)

  # =========================================================
  # Quantification file
  # =========================================================
  file_path <- file.path(quant_dir, paste0(cps_id, "_seacr_consensus_profile_bins.xls"))
  if (!file.exists(file_path)) {
    message("### [ERROR] Cannot find quantification file: ", file_path)
    return(NULL)
  }

  data <- read.table(
    file_path,
    header = TRUE,
    sep = "\t",
    check.names = FALSE,
    stringsAsFactors = FALSE,
    quote = "",
    comment.char = ""
  )

  original_cols <- colnames(data)
  colnames(data) <- gsub("-", "_", colnames(data))

  g1_pattern <- gsub(";", "|", gsub("-", "_", g1_name))
  g2_pattern <- gsub(";", "|", gsub("-", "_", g2_name))

  g1_counts <- grep(paste0("^(", g1_pattern, ").*read_cnt$"), colnames(data))
  g2_counts <- grep(paste0("^(", g2_pattern, ").*read_cnt$"), colnames(data))
  g1_occs   <- grep(paste0("^(", g1_pattern, ").*occupancy$"), colnames(data))
  g2_occs   <- grep(paste0("^(", g2_pattern, ").*occupancy$"), colnames(data))

  message("**************************************************")
  message(paste0("Processing Comparison ", comp_id, ": ", g1_name, " vs ", g2_name))
  message(paste0("Using quantification file: ", file_path))
  message(paste0("Group 1 matched Count columns: ", paste(original_cols[g1_counts], collapse = ", ")))
  message(paste0("Group 2 matched Count columns: ", paste(original_cols[g2_counts], collapse = ", ")))

  if (length(g1_counts) == 0 || length(g2_counts) == 0) {
    stop("Column matching failed. Please check metadata group names vs quantification matrix column names.")
  }
  if (length(g1_counts) != length(g1_occs)) {
    stop("Group 1 Count columns and Occupancy columns do not match.")
  }
  if (length(g2_counts) != length(g2_occs)) {
    stop("Group 2 Count columns and Occupancy columns do not match.")
  }
  message("**************************************************")

  counts_g1 <- data[, g1_counts, drop = FALSE]
  counts_g2 <- data[, g2_counts, drop = FALSE]
  occ_g1    <- data[, g1_occs, drop = FALSE]
  occ_g2    <- data[, g2_occs, drop = FALSE]

  occ_n_g1 <- rowSums(occ_g1 > 0, na.rm = TRUE)
  occ_n_g2 <- rowSums(occ_g2 > 0, na.rm = TRUE)

  # =========================================================
  # edgeR-style filtering
  # =========================================================
  peak_id_all <- paste(data$chrom, data$start, data$end, sep = "_")

count_mat <- cbind(counts_g1, counts_g2)
rownames(count_mat) <- peak_id_all
  
  colnames(count_mat) <- c(
    paste0("G1_", seq_len(ncol(counts_g1))),
    paste0("G2_", seq_len(ncol(counts_g2)))
  )

  group <- factor(
    c(rep("G1", ncol(counts_g1)), rep("G2", ncol(counts_g2))),
    levels = c("G1", "G2")
  )

  design <- model.matrix(~ group)

  y0 <- DGEList(counts = count_mat)

  keep_expr <- filterByExpr(y0, design = design)
  keep_occ <- (occ_n_g1 + occ_n_g2) >= min_occ_n
#  keep <- keep_expr & keep_occ
  keep <- keep_expr



  count_mat_sub <- count_mat[keep, , drop = FALSE]
data_filtered <- data[keep, , drop = FALSE]
data_filtered$peak_id <- paste(data_filtered$chrom, data_filtered$start, data_filtered$end, sep = "_")

  matched_g1_counts <- paste(original_cols[g1_counts], collapse = " | ")
  matched_g2_counts <- paste(original_cols[g2_counts], collapse = " | ")
  matched_g1_occs   <- paste(original_cols[g1_occs], collapse = " | ")
  matched_g2_occs   <- paste(original_cols[g2_occs], collapse = " | ")

  filter_stats <- data.frame(
    Comparison_ID = comp_id,
    CPS = cps_id,
    Histone_Mark = histone_mark,
    Group1 = g1_name,
    Group2 = g2_name,
    Matched_G1_Counts = matched_g1_counts,
    Matched_G2_Counts = matched_g2_counts,
    Matched_G1_Occs   = matched_g1_occs,
    Matched_G2_Occs   = matched_g2_occs,
    Total_Peaks = nrow(data),
    After_filterByExpr = sum(keep_expr, na.rm = TRUE),
    After_Occupancy_Filter = sum(keep_occ, na.rm = TRUE),
    Final_Tested_Peaks = sum(keep, na.rm = TRUE),
    Min_Occupied_Replicates = min_occ_n,
    stringsAsFactors = FALSE
  )

  cat(paste0("\n[edgeR filter summary] Comparison ", comp_id, "\n"))
  cat(paste0("  Total peaks: ", nrow(data), "\n"))
  cat(paste0("  After filterByExpr: ", sum(keep_expr, na.rm = TRUE), "\n"))
  cat(paste0("  After occupancy filter: ", sum(keep_occ, na.rm = TRUE), "\n"))
  cat(paste0("  Final tested peaks: ", sum(keep, na.rm = TRUE), "\n"))

  if (nrow(count_mat_sub) == 0) {
    stop("No peaks remain after filtering.")
  }

  # =========================================================
  # Differential test by edgeR
  # =========================================================
  y <- DGEList(counts = count_mat_sub, group = group)
  y <- calcNormFactors(y)

  design <- model.matrix(~ group)
  colnames(design) <- make.names(colnames(design))

  y <- estimateDisp(y, design)
  fit <- glmQLFit(y, design, robust = TRUE)


  # logFC is defined as Group1 - Group2 to match file naming: Group1_vs_Group2
#qlf <- glmQLFTest(fit, coef = "groupG2")
qlf <- glmQLFTest(fit, contrast = c(0, -1))

tt <- topTags(qlf, n = Inf, sort.by = "none")
res <- as.data.frame(tt$table)

peak_id <- rownames(res)

if (is.null(peak_id) || length(peak_id) == 0) {
  stop("No rownames found in edgeR result table.")
}

coord <- strsplit(peak_id, "_", fixed = TRUE)
coord_len <- unique(lengths(coord))

if (!all(coord_len == 3)) {
  stop("peak_id format is invalid. Expected chrom_start_end.")
}

coord <- do.call(rbind, coord)

final_res <- data.frame(
  chrom = coord[, 1],
  start = as.numeric(coord[, 2]),
  end   = as.numeric(coord[, 3]),
  logFC = res$logFC,
  logCPM = res$logCPM,
  F = res$F,
  pvalue = res$PValue,
  padj = res$FDR,
  peak_id = peak_id,
  stringsAsFactors = FALSE
)
  
  
  # =========================================================
  # Annotation
  # =========================================================
  peaks_gr <- GRanges(
    seqnames = final_res$chrom,
    ranges = IRanges(final_res$start, final_res$end)
  )
  mcols(peaks_gr) <- final_res[, 4:ncol(final_res)]

  peakAnno <- annotatePeak(
    peaks_gr,
    tssRegion = c(-3000, 3000),
    TxDb = txdb,
    overlap = "all",
    addFlankGeneInfo = TRUE,
    flankDistance = 3000
  )

  res_df <- as.data.frame(peakAnno)
  res_df[] <- lapply(res_df, function(x) {
    if (is.list(x)) sapply(x, paste, collapse = ";") else x
  })
  res_df$geneId <- gsub("\\..*", "", res_df$geneId)
  res_df$SYMBOL <- gene_map$SYMBOL[match(res_df$geneId, gene_map$geneId)]

  res_df$Comparison_ID <- comp_id
  res_df$CPS <- cps_id
  res_df$Histone_Mark <- histone_mark
  res_df$Direction <- ifelse(
  is.na(res_df$logFC), NA,
  ifelse(res_df$logFC > 0, "Group1_Higher",
         ifelse(res_df$logFC < 0, "Group2_Higher", "No_Change"))
)
  output_name <- file.path(
    output_dir,
    paste0(cps_id, "_Comp", comp_id, "_", histone_label, "_", g1_name, "_vs_", g2_name, "_edgeR_results.txt")
  )
  write.table(res_df, output_name, quote = FALSE, row.names = FALSE, sep = "\t")

  # =========================================================
  # Summary statistics
  # =========================================================
  sig_peaks <- res_df[res_df$padj < 0.05 & !is.na(res_df$padj), , drop = FALSE]

  if (nrow(sig_peaks) > 0) {
    valid_genes <- sig_peaks[!is.na(sig_peaks$SYMBOL) & sig_peaks$SYMBOL != "", , drop = FALSE]

    if (nrow(valid_genes) > 0) {
      ordered_symbols <- unique(valid_genes$SYMBOL[order(valid_genes$padj)])
      num_genes <- min(10, length(ordered_symbols))
      top_10_genes <- paste(ordered_symbols[1:num_genes], collapse = ", ")
    } else {
      top_10_genes <- "None"
    }

    anno_types <- gsub(" \\(.*", "", sig_peaks$annotation)
    anno_dist <- as.data.frame(table(anno_types))
    anno_str <- paste(apply(anno_dist, 1, function(x) paste0(x[1], ":", x[2])), collapse = "; ")

#    g2_high_data <- sig_peaks[sig_peaks$logFC > 0, , drop = FALSE]
#    g1_high_data <- sig_peaks[sig_peaks$logFC < 0, , drop = FALSE]

    g1_high_data <- sig_peaks[sig_peaks$logFC > 0, , drop = FALSE]
    g2_high_data <- sig_peaks[sig_peaks$logFC < 0, , drop = FALSE]
    g2_dist <- as.data.frame(table(factor(g2_high_data$seqnames, levels = levels(as.factor(res_df$seqnames)))))
    g1_dist <- as.data.frame(table(factor(g1_high_data$seqnames, levels = levels(as.factor(res_df$seqnames)))))

    dist_table <- data.frame(
      Chromosome = g2_dist$Var1,
      G2_Higher_Count = g2_dist$Freq,
      G1_Higher_Count = g1_dist$Freq,
      Comparison_ID = comp_id,
      CPS = cps_id,
      Histone_Mark = histone_mark,
      Comparison_Name = paste0(g1_name, "_vs_", g2_name)
    )

    summary_row <- data.frame(
      Comparison_ID = comp_id,
      CPS = cps_id,
      Histone_Mark = histone_mark,
      Group1_Ref = g1_name,
      Group2_Test = g2_name,
      Total_Sig = nrow(sig_peaks),
      Higher_in_G2 = nrow(g2_high_data),
      Higher_in_G1 = nrow(g1_high_data),
      Top_10_Genes = top_10_genes,
      Anno_Distribution = anno_str,
      stringsAsFactors = FALSE
    )
  } else {
    summary_row <- data.frame(
      Comparison_ID = comp_id,
      CPS = cps_id,
      Histone_Mark = histone_mark,
      Group1_Ref = g1_name,
      Group2_Test = g2_name,
      Total_Sig = 0,
      Higher_in_G2 = 0,
      Higher_in_G1 = 0,
      Top_10_Genes = "None",
      Anno_Distribution = "None",
      stringsAsFactors = FALSE
    )
    dist_table <- NULL
  }

  return(list(
    summary = summary_row,
    dist_table = dist_table,
    filter_stats = filter_stats,
    cps_id = cps_id,
    comp_id = comp_id,
    histone_mark = histone_mark,
    histone_label = histone_label
  ))
}

# =========================================================
# 5. Run current task
# =========================================================
result <- process_edgeR_comp(metadata[task_id, ])

# =========================================================
# 6. Write output files
# =========================================================
if (!is.null(result)) {
  write.csv(
    result$summary,
    file.path(output_dir, paste0(result$cps_id, "_Comp", result$comp_id, "_", result$histone_label, "_edgeR_summary.csv")),
    row.names = FALSE,
    quote = FALSE
  )

  write.csv(
    result$filter_stats,
    file.path(output_dir, paste0(result$cps_id, "_Comp", result$comp_id, "_", result$histone_label, "_edgeR_filter_stats.csv")),
    row.names = FALSE,
    quote = FALSE
  )

  if (!is.null(result$dist_table)) {
    write.csv(
      result$dist_table,
      file.path(output_dir, paste0(result$cps_id, "_Comp", result$comp_id, "_", result$histone_label, "_edgeR_dist.csv")),
      row.names = FALSE,
      quote = FALSE
    )
  }
}
