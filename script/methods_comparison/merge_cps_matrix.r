# --- 1. 配置基础路径 ---
counts_dir <- "/common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/manorm2_counts"
# 建议新建一个文件夹存放这些大矩阵，免得和 54 个散装文件混在一起
output_dir <- file.path(counts_dir, "Merged_CPS_Matrices")
dir.create(output_dir, showWarnings = FALSE)

# --- 2. 自动嗅探所有的 CPS ID ---
# 扫出所有的 _profile_bins.xls 文件
all_files <- list.files(counts_dir, pattern = "_profile_bins\\.xls$")

# 【核心魔法】：用正则表达式从文件名(如 comp52_CPS1_profile_bins.xls) 中把 "CPS1" 抠出来
# 这行代码会自动提取所有的 CPS 名字，并用 unique() 去重
cps_ids <- unique(sub(".*_(.*)_profile_bins\\.xls$", "\\1", all_files))

message(paste("🎯 总共自动检测到", length(cps_ids), "个 CPS 集合:", paste(cps_ids, collapse=", ")))

# --- 3. 开启全自动大循环！ ---
for (cps_id in cps_ids) {
  message(paste("\n🚀 正在拼接:", cps_id, "..."))
  
  output_file <- file.path(output_dir, paste0(cps_id, "_all_samples_profile_bins.xls"))
  
  # 找出属于当前这个 cps_id 的所有碎片文件
  file_pattern <- paste0("_", cps_id, "_profile_bins\\.xls$")
  cps_files <- list.files(counts_dir, pattern = file_pattern, full.names = TRUE)
  
  if (length(cps_files) == 0) next # 防止意外跳过
  
  # 读入第一个文件作为骨架 (只保留 chrom, start, end)
  base_data <- read.table(cps_files[1], header = TRUE, sep = "\t", check.names = FALSE)
  final_matrix <- base_data[, 1:3]
  
  # 遍历这个 CPS 下所有的文件，横向吸纳新的样本
  for (f in cps_files) {
    tmp_data <- read.table(f, header = TRUE, sep = "\t", check.names = FALSE)
    colnames(tmp_data) <- gsub("-", "_", colnames(tmp_data)) # 规范化列名
    
    cnt_cols <- grep("read_cnt$", colnames(tmp_data), value = TRUE)
    for (col in cnt_cols) {
      if (!(col %in% colnames(final_matrix))) {
        final_matrix[[col]] <- tmp_data[[col]]
      }
    }
  }
  
  # 保存当前 CPS 的大矩阵
  write.table(final_matrix, output_file, sep = "\t", quote = FALSE, row.names = FALSE)
  message(paste("✅", cps_id, "拼接完成！共包含", ncol(final_matrix) - 3, "个样本。"))
}

message("\n🎉 恭喜！所有 CPS 的大矩阵已全部生成，保存在: ", output_dir)
