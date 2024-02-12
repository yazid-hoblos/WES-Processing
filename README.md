# WES-Processing

This repository contains scripts for the analysis of SNP variants data from Whole Exome Sequencing (WES). The repository is structured as follows:

- [ACMG Variants Filtering](#Scripts)
- [VarSome-ClinVar Data Extraction](#Varsome-ClinVar)
- [OMIM-DO Data Extraction](#OMIM-DO)
- [Plots Visualization](#plots.Rmd)

## ACMG Variant Filtering
The `Scripts` folder contains scripts for the processing of variants from WES files, filtering ACMG variants, quality-based filtering, variants data reshaping, and frequency calculation. Srpits for the detection of specific variants or genes in patients' files and for other purposes could be found as well. 

### Usage
```bash
./ACMG-filtering-discrepancies-corrected.sh -i <source folder> -o <target folder>
```

## Varsome-ClinVar Data Extraction
The `Varsome-ClinVar` folder provides a script for the extraction of the Varsome and ClinVar annotations of a given list of variants. A script is provided for data reshaping.

### Usage
```bash
python3 varsome_tor_accession.py variants.txt varsome_clinvar_data.csv
```
## Plots Visualization
An R script is provided for the visualization of several plots relevant for WES secondary findings analysis.
![stacked_updated](https://github.com/yazid-hoblos/WES-Processing/assets/125372209/fe3fe297-e66b-4da9-baf1-ec94c9ea32ee)
![new_AR_updated](https://github.com/yazid-hoblos/WES-Processing/assets/125372209/9612d9c1-6847-4016-ab57-320cb4aaba40)
![AD_genes_updated](https://github.com/yazid-hoblos/WES-Processing/assets/125372209/ea3a9c66-f4b7-4e66-869c-6f4d7e020375)
![new_mutation_types_updated](https://github.com/yazid-hoblos/WES-Processing/assets/125372209/ae2fa0a0-f56a-4d62-8719-47ab14a2ef12)
![AB-DP](https://github.com/yazid-hoblos/WES-Processing/assets/125372209/a2135a96-f88a-484a-9df6-4a07f342f241)

## OMIM-DO Data Extraction
The `OMIM-DO` folder provides scripts for the extraction of the diseases that correspond to a given list of genes.

### Usage
```bash
python3 extract_mims.py genes.txt mims.tsv
python3 extract_diseases.py mims.tsv diseases.tsv
```




