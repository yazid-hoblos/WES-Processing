#!/bin/bash

declare -A genes

while IFS=',' read -r line;do
genes[$(echo "$line" | cut -d ',' -f1)]=$(echo "$line" | cut -d ',' -f2-)
done < "categories.csv"

read -p "Target folder:" target

tail -n +2 "$target/reduced_variants.csv" | sort -t',' -k2 | awk -F, '{OFS=FS; if ($12 == "likely_pathogenic" || $12 == "pathogenic") print}' > "$target/temp.csv"

file=''
echo "gene,chromosome,num_patients,num_het,num_hom,patients,num_variants,${genes['Gene']}" > "$target/pathogenic_by_gene.csv"

gene=$(head -n 1 "$target/temp.csv" | cut -d ',' -f 2)
num_patients=$(head -n 1 "$target/temp.csv" | cut -d ',' -f 7)
num_het=$(head -n 1 "$target/temp.csv" | cut -d ',' -f 9)
num_hom=$(head -n 1 "$target/temp.csv" | cut -d ',' -f 8)
chrom=$(head -n 1 "$target/temp.csv" | cut -d ',' -f 3)
patients="$(head -n 1 "$target/temp.csv" | cut -d ',' -f 6)[$(head -n 1 "$target/temp.csv" | cut -d ',' -f 1)]"
num_var=1

tail -n +2 "$target/temp.csv" | awk -v num_var="$num_var" -v gene="$gene" -v chrom="$chrom" -v target="$target" -v num_patients="$num_patients" -v num_hom="$num_hom" -v num_het="$num_het" -v patients="$patients" -v file="$file" -v target="$target" -F',' '{
  if ($2 == gene) {
    num_patients=num_patients+$7
    num_hom=num_hom+$8
    num_het=num_het+$9
    patients= patients " | " $6 "[" $1 "]"
    num_var++ 
  } else {
    file = file gene "," chrom "," num_patients "," num_het "," num_hom "," patients "," num_var "\n"
    num_patients=$7
    num_hom=$8
    num_het=$9
    chrom=$3
    patients=$6 "[" $1 "]"
    num_var=1
  }
  gene = $2
}
END {
  file = file gene "," chrom "," num_patients "," num_het "," num_hom "," patients "," num_var
  print file >> (target"/pathogenic_by_gene.csv")
}'

rm "$target/temp.csv"

echo $(head -n 1 "$target/pathogenic_by_gene.csv") > "$target/tmp"

IFS=$'\n'
for line in $(tail -n +2 "$target/pathogenic_by_gene.csv");do
    gene=$(echo "$line" | cut -d ',' -f1)
    echo "$line,${genes[$gene]}" >> "$target/tmp" 
done
mv "$target/tmp" "$target/pathogenic_by_gene.csv"