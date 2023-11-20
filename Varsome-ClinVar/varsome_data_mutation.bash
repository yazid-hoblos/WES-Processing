#!/bin/bash

awk -F, '{if ($12 == "unknown" || $12 == "uncertain_significance" || $12 == "R1" || $12 == "R2") print}' reduced_variants.csv | cut -d, -f1,2,3,4,5,6,7,8,9,10,11,12 | grep -E "^NM" | sed 's/\.[0-9]:/:/g' | sort > temp1.csv

cut -d, -f2,3 varsome_data.csv > temp2.csv #varsome_data.csv is the output file of varsome_tor_accession.py ; varsome_data.csv must be sorted by variants identifiers (sort -t, -k1)>

paste -d, temp1.csv temp2.csv > temp3.csv

cols="variant,gene,chrom,pHGVS,details,patients,num_patients,num_hom,num_het,num_hem,frequency,consensus,varsome_consensus,varsome_categories,error_messages"

sed "1i$cols" temp3.csv > temp4.csv

mv temp4.csv varsome_extracted_data.csv

rm temp1.csv temp2.csv temp3.csv 
