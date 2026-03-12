cd /common/lix5lab/Li_Xue_Cut_Tag_06162022/Analysis_WYZ/mm39/manorm2_master_results/ || exit 1

rm -f All_Comparisons_Summary.csv All_Filter_Stats.csv All_Chromosome_Dist.csv

first_summary=$(ls CPS*_Comp*_summary.csv | head -n 1)
head -n 1 "$first_summary" > All_Comparisons_Summary.csv
awk 'FNR>1' CPS*_Comp*_summary.csv | sort -t, -k1,1n >> All_Comparisons_Summary.csv

first_filter=$(ls CPS*_Comp*_filter_stats.csv | head -n 1)
head -n 1 "$first_filter" > All_Filter_Stats.csv
awk 'FNR>1' CPS*_Comp*_filter_stats.csv | sort -t, -k1,1n >> All_Filter_Stats.csv

first_dist=$(ls CPS*_Comp*_dist.csv 2>/dev/null | head -n 1)
if [ -n "$first_dist" ]; then
    head -n 1 "$first_dist" > All_Chromosome_Dist.csv
    awk 'FNR>1' CPS*_Comp*_dist.csv | sort -t, -k1,1n >> All_Chromosome_Dist.csv
fi

for f in CPS*_Comp*; do
    [ -e "$f" ] || continue
    cps=$(echo "$f" | cut -d'_' -f1)
    mkdir -p "$cps"
    mv "$f" "$cps"/
done
