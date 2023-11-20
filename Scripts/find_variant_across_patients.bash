#!/bin/bash

read -p "Input variant: " variant
read -p "Output file name: " output
read -p "Source folder: " source
read -p "Destination folder: " target

for file in $source/*;do 
    if grep -q $variant $file;then 
        file_name=$(basename -- $file)
        id=${file_name:0: -10} 
        grep $variant $file | sed "s/^/$id\t/g" | sed 's/\t/,/g' >> "$target/$output.csv"
    fi
done

if ! [ -s "$target/$output.csv" ];then echo "NOT FOUND";fi