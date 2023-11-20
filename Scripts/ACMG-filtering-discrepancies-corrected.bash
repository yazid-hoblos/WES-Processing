#!/bin/bash

read -p "Enter source path: " source
read -p "Enter destination path: " target
flag=0 
patients=500
males=268
females=232

tail -n +2 "$source/whole_data.csv" | sort -f -t',' -k7 > "$target/temp.csv"

file=''
reduced_file=''
echo "variants,gene,chromosome,pHGVS,details,patients,numPatients,num_hom,num_het,num_hem,frequency,consensus,$(head -n 1 "$source/whole_data.csv" | cut -d ',' -f13-)" > "$target/variants.csv"
echo "variants,gene,chromosome,pHGVS,details,patients,numPatients,num_hom,num_het,num_hem,frequency,consensus,$(head -n 1 "$source/whole_data.csv" | cut -d ',' -f13-)" > "$target/reduced_variants.csv"


head="$(head -n 1 "$target/temp.csv")"
IFS=',' read -ra fields <<< "$head"	
patient="${fields[0]}" AB="${fields[5]}" DP="${fields[11]}" allele="${fields[9]}"
variant="${fields[6]}"
chrom="${fields[1]}"
all_patients="$patient $AB $DP $allele"
variant_details=$(echo "$head" | awk -F ',' 'BEGIN{OFS=","}{print $9","$2","$8","$3" "$4"->"$5}')
consensus=$(echo "$head" | awk -F ',' '{print $11}')
other_details="$(echo $head | cut -d ',' -f13-)"
num_patients=1
if [ $allele == "hom" ];then num_hom=1 num_het=0 num_hem=0;elif [ $allele == "het" ];then num_hom=0 num_het=1 num_hem=0;else num_hem=1 num_hom=0 num_het=0;fi


if (( $( echo "${fields[5]} >= 0.2" | bc -l) )) && (( "${fields[11]}" >=15 ));then
    reduced_all_patients="$patient $AB $DP $allele"
    reduced_consensus=$(echo "$head" | awk -F ',' '{print $11}')
    reduced_num_patients=1
    if [ $allele == "hom" ];then reduced_num_hom=1 reduced_num_het=0 reduced_num_hem=0;elif [ $allele == "het" ];then reduced_num_hom=0 reduced_num_het=1 reduced_num_hem=0;else reduced_num_hem=1 reduced_num_hom=0 reduced_num_het=0;fi
    initiated=1
else
    reduced_consensus=""
    initiated=0
    reduced_num_patients=0
    reduced_num_hem=0 reduced_num_het=0 reduced_num_hom=0
fi


total_alleles=$(($patients*2))
chr_X_alleles=$(($females*2+$males))
chr_Y_alleles=$males


tail -n +2 "$target/temp.csv" | awk -v target=$target -v initiated=$initiated -v reduced_consensus="$reduced_consensus" -v consensus="$consensus" -v variant=$variant -v all_patients="$all_patients" -v reduced_all_patients="$reduced_all_patients" -v variant_details="$variant_details" -v other_details="$other_details" -v file="$file" -v reduced_file="$reduced_file" -v num_patients=$num_patients -v num_hom=$num_hom -v num_het=$num_het -v num_hem=$num_hem -v reduced_num_patients=$reduced_num_patients -v reduced_num_hom=$reduced_num_hom -v reduced_num_het=$reduced_num_het -v reduced_num_hem=$reduced_num_hem -v total_alleles=$total_alleles -v chrom=$chrom -v chr_X_alleles=$chr_X_alleles -v chr_Y_alleles=$chr_Y_alleles -F',' '{
  if ($7 == variant) {
    all_patients = all_patients ";" $1 " " $6 " " $12 " " $10
    if (!match(consensus,$11)) {consensus = consensus "; " $11}
    num_patients++
    if ($10 == "hom") {num_hom++} else if ($10 == "het") {num_het++} else {num_hem++}
    
    if ($6 >= 0.2 && $12 >= 15){
        if (initiated == 1){
            reduced_all_patients = reduced_all_patients ";" $1 " " $6 " " $12 " " $10
            if (!match(reduced_consensus,$11)) {reduced_consensus = reduced_consensus "; " $11}
            reduced_num_patients++
            if ($10 == "hom") {reduced_num_hom++} else if ($10 == "het") {reduced_num_het++} else {reduced_num_hem++}
        }
        else {
            reduced_all_patients = $1 " " $6 " " $12 " " $10
            reduced_consensus=$11
            reduced_num_patients=1
            if ($10 == "hom") {reduced_num_hom=1;reduced_num_het=0;reduced_num_hem=0} else if ($10 =="het") {reduced_num_het=1;reduced_num_hom=0;reduced_num_hem=0} else {reduced_num_hem=1;reduced_num_het=0;reduced_num_hom=0}
            initiated=1
        }
    }
  } else {
        if (chrom == "X"){
            freq=((num_hom*2)+num_het+num_hem)/chr_X_alleles
        }else if (chrom == "Y"){
            freq=((num_hom*2)+num_het+num_hem)/chr_Y_alleles
        }else{
            freq=(num_hom+num_het+num_hem)/total_alleles
        }
        file = file variant "," variant_details "," all_patients "," num_patients "," num_hom "," num_het "," num_hem "," freq "," consensus "," other_details "\n"
        all_patients = $1 " " $6 " " $12 " " $10
        num_patients=1
        if ($10 == "hom") {num_hom=1;num_het=0;num_hem=0} else if ($10 == "het") {num_het=1;num_hom=0;num_hem=0} else {num_hem=1;num_hom=0;num_het=0}

        if (initiated==1){ 
            if (chrom == "X"){
                reduced_freq=((reduced_num_hom*2)+reduced_num_het+reduced_num_hem)/chr_X_alleles
            }else if (chrom == "Y"){
                reduced_freq=((reduced_num_hom*2)+reduced_num_het+reduced_num_hem)/chr_Y_alleles
            }else{
                reduced_freq=(reduced_num_hom+reduced_num_het+reduced_num_hem)/total_alleles
            }
            reduced_file = reduced_file variant "," variant_details "," reduced_all_patients "," reduced_num_patients "," reduced_num_hom "," reduced_num_het "," reduced_num_hem "," reduced_freq "," reduced_consensus "," other_details "\n" 
        }
        if ($6 >= 0.2 && $12 >= 15){    
            reduced_all_patients = $1 " " $6 " " $12 " " $10
            reduced_consensus=$11
            reduced_num_patients=1
            if ($10 == "hom") {reduced_num_hom=1;reduced_num_het=0;reduced_num_hem=0} else if ($10 == "het") {reduced_num_het=1;reduced_num_hom=0;reduced_num_hem=0} else {reduced_num_hem=1;reduced_num_hom=0;reduced_num_het=0}
            initiated=1
        }else{
            reduced_consensus=""
            initiated=0
        } 
        variant_details = $9 "," $2 "," $8 "," $3 " " $4 "->" $5
        consensus = $11
        other_details = "" 
        for (i = 13; i <= NF; i++) {
        other_details = other_details "," $(i) 
        }   
  }
  variant = $7
}
END {
    if (chrom == "X"){
        freq=((num_hom*2)+num_het+num_hem)/chr_X_alleles
    }else if (chrom == "Y"){
        freq=((num_hom*2)+num_het+num_hem)/chr_Y_alleles
    }else{
        freq=(num_hom+num_het+num_hem)/total_alleles
    }
    file = file variant "," variant_details "," all_patients "," num_patients "," num_hom "," num_het "," num_hem "," freq "," consensus "," other_details 
    if (initiated==1) {
        if (chrom == "X"){
            reduced_freq=((reduced_num_hom*2)+reduced_num_het+reduced_num_hem)/chr_X_alleles
        }else if (chrom == "Y"){
            reduced_freq=((reduced_num_hom*2)+reduced_num_het+reduced_num_hem)/chr_Y_alleles
        }else{
            reduced_freq=(reduced_num_hom+reduced_num_het+reduced_num_hem)/total_alleles
        }
        reduced_file = reduced_file variant "," variant_details "," reduced_all_patients "," reduced_num_patients "," reduced_num_hom "," reduced_num_het "," reduced_num_hem "," reduced_freq "," reduced_consensus "," other_details
    }
    print file >> (target"/variants.csv")
    print reduced_file >> (target"/reduced_variants.csv")
}'

rm "$target/temp.csv"
