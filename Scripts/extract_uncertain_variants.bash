#!/bin/bash

 awk -F, '{if ($12 == "unknown" || $12 == "uncertain_significance" || $12 == "R1" || $12 == "R2") print}' reduced_variants.csv | cut -d, -f1 | grep -E "^NM" | sed 's/\.[0-9]:/:/g' > uncertaing_variants.txt
