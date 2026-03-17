library(MAnorm2)
library(ChIPseeker)
library(GenomicRanges)
library(GenomicFeatures)

# --- 1. Receive SLURM Array ID ---
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("Need task ID")
task_id <- as.numeric(args[1])

# --- 2. Path configuration ---
txdb <- loadDb("/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/mm39_vM38_pc_lnc_miRNA.sqlite")
gene_map <- readRDS("/common/lix5lab/reference/Mus_musculus/GENCODE/mm39/GENCODE_vM38_GeneMap.rds")

metadata_file <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/script/metadata_form/Metadata_Comparison.csv"
master_dir <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/manorm2_master_counts"
output_dir <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/manorm2_master_results"

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# --- 3. Parameter configuration ---
metadata <- read.csv(metadata_file, stringsAsFactors = FALSE)
if (task_id > nrow(metadata)) stop("Task ID out of range")

low_quantile_cutoff <- 0.1
min_occ_n <- 2
min_mean_count <- 10
max_cv <- 1.0

# --- 4. 定义单组分析函数 ---
process_manorm2_comp <- function(row_data) {
  comp_id <- trimws(row_data[["comp"]])
  
  # 兼容你的表头可能是 CPS 或者 Concensus_peak
  cps_id <- if ("CPS" %in% names(row_data)) trimws(row_data[["CPS"]]) else trimws(row_data[["Concensus_peak"]])
  g1_name <- trimws(row_data[["group1"]])
  g2_name <- trimws(row_data[["group2"]])

  histone_mark <- trimws(as.character(row_data[[ncol(row_data)]]))

  histone_label <- gsub("[^A-Za-z0-9._-]", "_", histone_mark)
  
  # 🌟 核心修改 1：指向 Master Matrix 🌟
  file_path <- file.path(master_dir, paste0(cps_id, "_master_counts_profile_bins.xls"))
  if (!file.exists(file_path)) {
    message("### [ERROR] 找不到文件: ", file_path)
    return(NULL)
  }

  data <- read.table(file_path, header = TRUE, sep = "\t", check.names = FALSE)
  
  original_cols <- colnames(data)
  colnames(data) <- gsub("-", "_", colnames(data))

  g1_pattern <- gsub(";", "|", gsub("-", "_", g1_name))
  g2_pattern <- gsub(";", "|", gsub("-", "_", g2_name))

  # 从 Master Matrix 庞大的列中，利用正则精准抠出当前 Comparison 需要的列
  g1_counts <- grep(paste0("^(", g1_pattern, ").*read_cnt$"), colnames(data))
  g2_counts <- grep(paste0("^(", g2_pattern, ").*read_cnt$"), colnames(data))
  g1_occs   <- grep(paste0("^(", g1_pattern, ").*occupancy$"), colnames(data))
  g2_occs   <- grep(paste0("^(", g2_pattern, ").*occupancy$"), colnames(data))
  
  message("**************************************************")
  message(paste0("正在处理 Comparison ", comp_id, ": ", g1_name, " vs ", g2_name))
  message(paste0("Group 1 (", g1_name, ") 匹配到的 Count 列: ", paste(original_cols[g1_counts], collapse = ", ")))
  message(paste0("Group 2 (", g2_name, ") 匹配到的 Count 列: ", paste(original_cols[g2_counts], collapse = ", ")))

  # 基础完整性检查
  if(length(g1_counts) == 0 || length(g2_counts) == 0) {
    stop(paste("列匹配失败！请检查 Metadata 与 Master Matrix 列名是否一致。"))
  }
  if(length(g1_counts) != length(g1_occs)) {
    stop("Group 1 的 Count 列和 Occupancy 列数量不匹配！")
  }
  if(length(g2_counts) != length(g2_occs)) {
    stop("Group 2 的 Count 列和 Occupancy 列数量不匹配！")
  }
  message("**************************************************")
  
  counts_g1 <- data[, g1_counts, drop = FALSE]
  counts_g2 <- data[, g2_counts, drop = FALSE]
  occ_g1    <- data[, g1_occs, drop = FALSE]
  occ_g2    <- data[, g2_occs, drop = FALSE]

  g1_mean <- rowMeans(counts_g1, na.rm = TRUE)
  g2_mean <- rowMeans(counts_g2, na.rm = TRUE)
  total_sum <- rowSums(cbind(counts_g1, counts_g2), na.rm = TRUE)

  calc_cv <- function(mat) {
    apply(mat, 1, sd, na.rm = TRUE) / (rowMeans(mat, na.rm = TRUE) + 1)
  }
  cv1 <- calc_cv(counts_g1)
  cv2 <- calc_cv(counts_g2)

  occ_n_g1 <- rowSums(occ_g1 > 0, na.rm = TRUE)
  occ_n_g2 <- rowSums(occ_g2 > 0, na.rm = TRUE)

  # 1. basic filter
  low_cutoff <- quantile(total_sum, low_quantile_cutoff, na.rm = TRUE)
  basic_keep <- total_sum > low_cutoff

  # 2. quality filter
  quality_keep <- ((g1_mean >= min_mean_count) & (cv1 <= max_cv)) |
                ((g2_mean >= min_mean_count) & (cv2 <= max_cv))

  # 3. occupancy filter
  occupancy_keep <- (occ_n_g1 + occ_n_g2) >= min_occ_n
  # Final keep
  keep <- basic_keep & occupancy_keep & quality_keep
  data_filtered <- data[keep, , drop = FALSE]
  # =========================================================
  # filter stats 输出
  # =========================================================
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
    
    # 👇 四道硬核防线，直接写进表格 👇
    Matched_G1_Counts = matched_g1_counts,
    Matched_G2_Counts = matched_g2_counts,
    Matched_G1_Occs   = matched_g1_occs,
    Matched_G2_Occs   = matched_g2_occs,
    
    Total_Peaks = nrow(data),
    After_Basic_Filter = sum(basic_keep, na.rm = TRUE),
    After_Occupancy_Filter = sum(occupancy_keep, na.rm = TRUE),
    After_Quality_Filter = sum(quality_keep, na.rm = TRUE),
    Final_Tested_Peaks = sum(keep, na.rm = TRUE),
    Basic_Threshold_TotalSum = round(low_cutoff, 2),
    Min_Occupied_Replicates = min_occ_n,
    Min_Mean_Count = min_mean_count,
    Max_CV = max_cv,
    stringsAsFactors = FALSE
  )  

  cat(paste0("\n[Monitor] Comparison ", comp_id, " filter summary:\n"))
  cat(paste0("  Total peaks: ", nrow(data), "\n"))
  cat(paste0("  After basic filter: ", sum(basic_keep, na.rm = TRUE), "\n"))
  cat(paste0("  After quality filter: ", sum(quality_keep, na.rm = TRUE), "\n"))
  cat(paste0("  After occupancy filter: ", sum(occupancy_keep, na.rm = TRUE), "\n"))
  cat(paste0("  Final tested peaks: ", sum(keep, na.rm = TRUE), "\n"))
  cat(paste0("  Bottom ", low_quantile_cutoff * 100, "% total_sum cutoff: ", round(low_cutoff, 2), "\n"))

  # --- 画 CV 质检图 ---
  qc_pdf_dir <- file.path(output_dir, "QC_Plots")
  dir.create(qc_pdf_dir, showWarnings = FALSE)
  cv_pdf <- file.path(qc_pdf_dir, paste0("Comp", comp_id, "_cv_Diagnostic.pdf"))

  pdf(cv_pdf, width = 10, height = 5)
  par(mfrow = c(1, 2))
  hist(cv1[g1_mean > min_mean_count], breaks = 100, col = "skyblue", main = "Group 1 CV Distribution", xlim = c(0, 1.5), xlab = "CV")
  abline(v = max_cv, col = "red", lwd = 2, lty = 2)
  legend("topright", legend = paste("CV =", max_cv, "Cutoff"), col = "red", lty = 2, lwd = 2)

  hist(cv2[g2_mean > min_mean_count], breaks = 100, col = "lightcoral", main = "Group 2 CV Distribution", xlim = c(0, 1.5), xlab = "CV")
  abline(v = max_cv, col = "red", lwd = 2, lty = 2)
  legend("topright", legend = paste("CV =", max_cv, "Cutoff"), col = "red", lty = 2, lwd = 2)
  dev.off()

  # --- 重新定位过滤后数据的列索引 ---
  g1_counts_f <- grep(paste0("^(", g1_pattern, ").*read_cnt$"), colnames(data_filtered))
  g2_counts_f <- grep(paste0("^(", g2_pattern, ").*read_cnt$"), colnames(data_filtered))
  g1_occs_f   <- grep(paste0("^(", g1_pattern, ").*occupancy$"), colnames(data_filtered))
  g2_occs_f   <- grep(paste0("^(", g2_pattern, ").*occupancy$"), colnames(data_filtered))

  # =========================================================
  # MAnorm2 原生归一化流程
  # =========================================================
  norm <- MAnorm2::normalize(data_filtered, count = g1_counts_f, occupancy = g1_occs_f)
  norm <- MAnorm2::normalize(norm, count = g2_counts_f, occupancy = g2_occs_f)

  conds <- list(
    G1 = bioCond(norm[g1_counts_f], norm[g1_occs_f], name = g1_name),
    G2 = bioCond(norm[g2_counts_f], norm[g2_occs_f], name = g2_name)
  )

  # 确定归一化锚点 (常染色体 & 全占据)
  occ_g1_f <- data_filtered[, g1_occs_f, drop = FALSE]
  occ_g2_f <- data_filtered[, g2_occs_f, drop = FALSE]
  occ_n_g1_f <- rowSums(occ_g1_f > 0, na.rm = TRUE)
  occ_n_g2_f <- rowSums(occ_g2_f > 0, na.rm = TRUE)

  autosome <- !(data_filtered$chrom %in% c("chrX", "chrY"))
  common_peak_idx <- autosome & (occ_n_g1_f == ncol(occ_g1_f)) & (occ_n_g2_f == ncol(occ_g2_f))

  n_common <- sum(common_peak_idx, na.rm = TRUE)
  frac_common_filtered <- n_common / nrow(data_filtered)
  frac_common_total <- n_common / nrow(data)

  cat(paste0("  Common peaks for normalization: ", n_common, "\n"))
  cat(paste0("  Fraction of tested peaks used as anchors: ", round(frac_common_filtered, 4), "\n"))
  cat(paste0("  Fraction of total peaks used as anchors: ", round(frac_common_total, 4), "\n")) 
 
  filter_stats$Common_Peaks_For_Norm <- n_common
  filter_stats$Frac_Common_of_Filtered <- round(frac_common_filtered, 4)
  filter_stats$Frac_Common_of_Total <- round(frac_common_total, 4)

  # 执行原生归一化
   conds <- normBioCond(conds, common.peak.regions = common_peak_idx)

# --- 先尝试 parametric；若不收敛或有数值 warning 则切换到 local regression ---
# =========================================================
# 先尝试 parametric；若不收敛或出现数值 warning，则切到 local regression
# =========================================================
fit_log <- capture.output(
  conds_param <- tryCatch(
    fitMeanVarCurve(
      conds,
      method = "parametric",
      occupy.only = TRUE,
      max.iter = 100,
      init.coef = c(0.1, 10)
    ),
    error = function(e) e
  )
)

# 打印 parametric 拟合日志
cat(paste(fit_log, collapse = "\n"), "\n")

param_converged <- any(grepl("Converged\\.", fit_log))

if (inherits(conds_param, "error") || !param_converged) {
  message("⚠️ Parametric fit failed or did not converge. Switching to modified local regression.")

  fit_log_local <- capture.output(
    conds_local <- tryCatch({
      tmp_conds <- fitMeanVarCurve(
        conds,
        method = "local regression",
        occupy.only = FALSE
      )

      tmp_conds <- estimatePriorDf(
        tmp_conds,
        occupy.only = TRUE
      )

      tmp_conds
    },
    error = function(e) e)
  )

  # 打印 modified local 拟合日志
  cat(paste(fit_log_local, collapse = "\n"), "\n")

  if (inherits(conds_local, "error")) {
    stop("Modified local regression fit also failed.")
  }

  conds <- conds_local
  fit_method_used <- "local_allIntervals_rePriorDf"

} else {
  conds <- conds_param
  fit_method_used <- "parametric"
}

message("Mean-variance fitting method used: ", fit_method_used)
cat(paste0("  Mean-variance fit method used: ", fit_method_used, "\n"))
filter_stats$MeanVar_Fit_Method <- fit_method_used



diag_pdf <- file.path(qc_pdf_dir, paste0("Comp", comp_id, "_MeanVar_Diagnostic.pdf"))
pdf(diag_pdf, width = 6, height = 6)
plotMeanVarCurve(conds, subset = "occupied")
dev.off()

  # 差异检验
  res <- diffTest(conds[[2]], conds[[1]])
  final_res <- cbind(data_filtered[, 1:3], res)

  # --- ChIPseeker 注释 ---
  peaks_gr <- GRanges(seqnames = final_res$chrom, ranges = IRanges(final_res$start, final_res$end))
  mcols(peaks_gr) <- final_res[, 4:ncol(final_res)]
  peakAnno <- annotatePeak(peaks_gr, tssRegion = c(-3000, 3000), TxDb = txdb,
                           overlap="all", addFlankGeneInfo = TRUE, flankDistance = 3000)

  res_df <- as.data.frame(peakAnno)
  res_df[] <- lapply(res_df, function(x) if(is.list(x)) sapply(x, paste, collapse = ";") else x)
  res_df$geneId <- gsub("\\..*", "", res_df$geneId)
  res_df$SYMBOL <- gene_map$SYMBOL[match(res_df$geneId, gene_map$geneId)]
  
  res_df$Comparison_ID <- comp_id
  res_df$CPS <- cps_id
  res_df$Histone_Mark <- histone_mark

  cps_label <- sub("^cps", "CPS", cps_id, ignore.case = TRUE)
  output_name <- file.path(
  output_dir,
  paste0(cps_label, "_Comp", comp_id, "_", histone_label, "_", g1_name, "_vs_", g2_name, "_results.txt")
)
  write.table(res_df, output_name, quote = FALSE, row.names = FALSE, sep = "\t")

  # --- 统计逻辑 ---
  sig_peaks <- res_df[res_df$padj < 0.05 & !is.na(res_df$padj), ]
  if (nrow(sig_peaks) > 0) {
    valid_genes <- sig_peaks[!is.na(sig_peaks$SYMBOL) & sig_peaks$SYMBOL != "", ]
    if (nrow(valid_genes) > 0) {
      ordered_symbols <- unique(valid_genes$SYMBOL[order(valid_genes$padj)])
      num_genes <- min(10, length(ordered_symbols))
      top_10_genes <- paste(ordered_symbols[1:num_genes], collapse = ", ")
    } else { top_10_genes <- "None" }

    anno_types <- gsub(" \\(.*", "", sig_peaks$annotation)
    anno_dist <- as.data.frame(table(anno_types))
    anno_str <- paste(apply(anno_dist, 1, function(x) paste0(x[1], ":", x[2])), collapse = "; ")

    g2_high_data <- sig_peaks[sig_peaks$Mval > 0, ]
    g1_high_data <- sig_peaks[sig_peaks$Mval < 0, ]
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
  cps_label = cps_label,
  comp_id = comp_id,
  histone_mark = histone_mark,
  histone_label = histone_label
))


}

# --- 5. 执行当前 Task ---
result <- process_manorm2_comp(metadata[task_id, ])

# --- 6. 独立输出中间文件供后续合并 ---

if (!is.null(result)) {
  write.csv(
    result$summary,
    file.path(output_dir, paste0(result$cps_label, "_Comp", result$comp_id, "_", result$histone_label, "_summary.csv")),
    row.names = FALSE,
    quote = FALSE
  )

  write.csv(
    result$filter_stats,
    file.path(output_dir, paste0(result$cps_label, "_Comp", result$comp_id, "_", result$histone_label, "_filter_stats.csv")),
    row.names = FALSE,
    quote = FALSE
  )

  if (!is.null(result$dist_table)) {
    write.csv(
      result$dist_table,
      file.path(output_dir, paste0(result$cps_label, "_Comp", result$comp_id, "_", result$histone_label, "_dist.csv")),
      row.names = FALSE,
      quote = FALSE
    )
  }
}

