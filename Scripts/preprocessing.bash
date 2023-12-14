#!/bin/bash

read -p "Enter source path: " source # list of fastq files
read -p "Enter destination path: " target

for file in $source/*;do

    file_name=$(basename -- $file)     
    fastqc -o "$target/fastqc_reports/$file_name fastqc_report_R1" "${file_name%"_input_R1.fastq"}"
    fastqc -o "$target/fastqc_reports/$file_name fastqc_report_R2" "${file_name%"_input_R2.fastq"}"

    path="$target/$file_name"
    trimmomatic PE "${file_name%"_input_R1.fastq"}" "${file_name%"_input_R2.fastq"}" "${path%"_output_R1_paired.fastq"}" "${path%"_output_R1_unpaired.fastq"}" "${path%"_output_R2_paired.fastq"}" "${path%"_output_R2_unpaired.fastq"}" ILLUMINACLIP:adapters.fasta:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    bwa mem -t 4 -R "@RG\tID:sample1\tSM:sample1" reference.fasta "${path%"_output_R1_paired.fastq"}" "${path%"_output_R2_paired.fastq"}" | samtools view -bS - >  "${path%"_aligned.bam"}"
    
    samtools sort "${path%"_aligned.bam"}" -o "${path%"_aligned_sorted.bam"}"
    samtools index "${path%"_aligned_sorted.bam"}"
    
    gatk --java-options "-Xmx4g" HaplotypeCaller -R reference.fasta -I "${path%"_aligned_sorted.bam"}" -O "${path%"_raw_variants.vcf"}"
    gatk VariantFiltration -R reference.fasta -V "${path%"_raw_variants.vcf"}" --filter-expression "QD < 2.0 || FS > 60.0 || MQ < 40.0" --filter-name "basic_filter" -O "${path%"_filtered_variants.vcf"}"
    
    final_path="$target/SNVs/$file_name"
    bcftools query -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%QUAL\t%FILTER\t%INFO/DP\t%INFO/AB\n' "${path%"_filtered_variants.vcf"}" > "${final_path%"_variants.tsv"}"

done

