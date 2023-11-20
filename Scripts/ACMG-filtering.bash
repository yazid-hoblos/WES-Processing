#!/bin/bash

# Part I

read -p "Enter source path: " source
read -p "Enter destination path: " target
flag=0

if [ -s "$target/whole_data.tsv" ];then rm "$target/whole_data.tsv";fi

for file in $source/*;do  
   file_name=$(basename -- $file)
   id=${file_name:4: -10}     
   data=$(grep -E "^(.*?\s){7}(APC|RET|BRCA1|BRCA2|PALB2|SDHD|SDHAF2|SDHC|SDHB|MAX|TMEM127|BMPR1A|SMAD4|TP53|MLH1|MSH2|MSH6|PMS2|MEN1|MUTYH|NF2|STK11|PTEN|RB1|TSC1|TSC2|VHL|WT1|FBN1|TGFBR1|TGFBR2|SMAD3|ACTA2|MYH11|PKP2|DSP|DSC2|TMEM43|DSG2|RYR2|CASQ2|TRDN|TNNT2|LMNA|FLNC|TTN|BAG3|DES|RBM20|TNNC1|COL3A1|LDLR|APOB|PCSK9|MYH7|MYBPC3|TNNI3|TPM1|MYL3|ACTC1|PRKAG2|MYL2|KCNQ1|KCNH2|SCN5A|BTD|GLA|OTC|GAA|HFE|ACVRL1|ENG|RYR1|CACNA1S|HNF1A|RPE65|ATP7B|TTR)\s" $file | sed "s/^/$id\/\t/g")
   if [ -n "$1" -a "$1" == '-i' ];then 
        head -n 1 $file > "$target/mutated_$file_name"
        echo "$data" | cut -f2-  >> "$target/mutated_$file_name" 
   fi
   if [ $(awk -F'\t' '{print NF; exit}' $file) -gt 40 ];then
        if [ $flag -eq 0 ];then flag=1 cols=$(cut -f14- $file | head -n 1);fi
        data=$(echo "$data" | awk -F'\t' '{OFS=FS; gsub(/\r/,"",$0) ; $125=$11;$126=$12; print}' | cut -f 1,2,3,4,5,6,7,8,9,10,13-)
   fi
   echo "$data" >>  "$target/whole_data.tsv"
done

columns="ID\tchrom\tpos\tref\talt\tAB\tcHGVS\tpHGVS\tgene\talleles\tconsensus\tDP\t"$cols"\tgnomad_exomes_AF\tgnomad_genomes_AF"
sed -i "1i$columns" "$target/whole_data.tsv" 
sed 's/\t/,/g' "$target/whole_data.tsv" | awk -F, 'BEGIN{OFS=","}{if ($6 == 0) $6 = 1; print}' > "$target/whole_data.csv"

# Part II

tail -n +2 "$target/whole_data.csv" | sort -t',' -k7 > "$target/temp.csv"

file=''
reduced_file=''
echo "variants,gene,chromosome,pHGVS,details,patients,numPatients,num_hom,num_het,num_hem,consensus,$(head -n 1 "$target/whole_data.csv" | cut -d ',' -f13-)" > "$target/variants.csv"
echo "variants,gene,chromosome,pHGVS,details,patients,numPatients,num_hom,num_het,num_hem,consensus,$(head -n 1 "$target/whole_data.csv" | cut -d ',' -f13-)" > "$target/reduced_variants.csv"


head="$(head -n 1 "$target/temp.csv")"
IFS=',' read -ra fields <<< "$head"	

patient="${fields[0]}" AB="${fields[5]}" DP="${fields[11]}" allele="${fields[9]}"
variant="${fields[6]}"
all_patients="$patient $AB $DP $allele"
variant_details=$(echo "$head" | awk -F ',' 'BEGIN{OFS=","}{print $9","$2","$8","$3" "$4"->"$5}')
other_details="$(echo "$head" | awk -F ',' '{print $11}'),$(echo $head | cut -d ',' -f13-)"
num_patients=1
if [ $allele == "hom" ];then num_hom=1 num_het=0 num_hem=0;elif [ $allele == "het" ];then num_hom=0 num_het=1 num_hem=0;else num_hem=1 num_hom=0 num_het=0;fi


if (( $( echo "${fields[5]} >= 0.2" | bc -l) )) && (( "${fields[11]}" >=15 ));then
    reduced_all_patients="$patient $AB $DP $allele"
    reduced_num_patients=1
    if [ $allele == "hom" ];then reduced_num_hom=1 reduced_num_het=0 reduced_num_hem=0;elif [ $allele == "het" ];then reduced_num_hom=0 reduced_num_het=1 reduced_num_hem=0;else reduced_num_hem=1 reduced_num_hom=0 reduced_num_het=0;fi
    initiated=1
else
    initiated=0
    reduced_num_patients=0
    reduced_num_hem=0 reduced_num_het=0 reduced_num_hom=0
fi


tail -n +2 "$target/temp.csv" | awk -v target=$target -v initiated=$initiated -v variant=$variant -v all_patients="$all_patients" -v reduced_all_patients="$reduced_all_patients" -v variant_details="$variant_details" -v other_details="$other_details" -v file="$file" -v reduced_file="$reduced_file" -v num_patients=$num_patients -v num_hom=$num_hom -v num_het=$num_het -v num_hem=$num_hem -v reduced_num_patients=$reduced_num_patients -v reduced_num_hom=$reduced_num_hom -v reduced_num_het=$reduced_num_het -v reduced_num_hem=$reduced_num_hem -F',' '{
  if ($7 == variant) {
    all_patients = all_patients " ; " $1 " " $6 " " $12 " " $10
    num_patients++
    if ($10 == "hom") {num_hom++} else if ($10 == "het") {num_het++} else {num_hem++}
    
    if ($6 >= 0.2 && $12 >= 15){
        if (initiated == 1){
            reduced_all_patients = reduced_all_patients " ; " $1 " " $6 " " $12 " " $10
            reduced_num_patients++
            if ($10 == "hom") {reduced_num_hom++} else if ($10 == "het") {reduced_num_het++} else {reduced_num_hem++}
        }
        else {
            reduced_all_patients = $1 " " $6 " " $12 " " $10
            reduced_num_patients=1
            if ($10 == "hom") {reduced_num_hom=1;reduced_num_het=0;reduced_num_hem=0} else if ($10 =="het") {reduced_num_het=1;reduced_num_hom=0;reduced_num_hem=0} else {reduced_num_hem=1;reduced_num_het=0;reduced_num_hom=0}
            initiated=1
        }
    }
  } else {
        file = file variant "," variant_details "," all_patients "," num_patients "," num_hom "," num_het "," num_hem "," other_details "\n"
        all_patients = $1 " " $6 " " $12 " " $10
        num_patients=1
        if ($10 == "hom") {num_hom=1;num_het=0;num_hem=0} else if ($10 == "het") {num_het=1;num_hom=0;num_hem=0} else {num_hem=1;num_hom=0;num_het=0}
        

        if (initiated==1){ reduced_file = reduced_file variant "," variant_details "," reduced_all_patients "," reduced_num_patients "," reduced_num_hom "," reduced_num_het "," reduced_num_hem "," other_details "\n" }
        if ($6 >= 0.2 && $12 >= 15){    
            reduced_all_patients = $1 " " $6 " " $12 " " $10
            reduced_num_patients=1
            if ($10 == "hom") {reduced_num_hom=1;reduced_num_het=0;reduced_num_hem=0} else if ($10 == "het") {reduced_num_het=1;reduced_num_hom=0;reduced_num_hem=0} else {reduced_num_hem=1;reduced_num_hom=0;reduced_num_het=0}
            initiated=1
        }else{
            initiated=0
        }  
        variant_details = $9 "," $2 "," $8 "," $3 " " $4 "->" $5
        other_details = $11 
        for (i = 13; i <= NF; i++) {
        other_details = other_details "," $(i) 
        }  
  }
  variant = $7
}
END {
  file = file variant "," variant_details "," all_patients "," num_patients "," num_hom "," num_het "," num_hem "," other_details 
  if (initiated==1) {reduced_file = reduced_file variant "," variant_details "," reduced_all_patients "," reduced_num_patients "," reduced_num_hom "," reduced_num_het "," reduced_num_hem "," other_details}
  print file >> (target"/variants.csv")
  print reduced_file >> (target"/reduced_variants.csv")
}'

rm "$target/temp.csv"