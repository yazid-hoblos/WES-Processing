import requests
import csv
import xml.etree.ElementTree as ET
import time

api_key = "W8hnefmATYOYSGFqrgHdfQ"

def extract_info(xml_string):
    root = ET.fromstring(xml_string)
    mim_number_element = root.find('.//mimNumber')
    mim_number = mim_number_element.text if mim_number_element is not None else None
    preferred_title_element = root.find('.//preferredTitle')
    preferred_title = preferred_title_element.text if preferred_title_element is not None else None

    phenotype_maps = root.findall('.//phenotypeMap')
    phenotypes = []
    for phenotype_map in phenotype_maps:
        phenotype = phenotype_map.find('phenotype').text if phenotype_map.find('phenotype') is not None else None
        phenotype_mim_number = phenotype_map.find('phenotypeMimNumber').text if phenotype_map.find('phenotypeMimNumber') is not None else None
        phenotype_mapping_key = phenotype_map.find('phenotypeMappingKey').text if phenotype_map.find('phenotypeMappingKey') is not None else None
        phenotype_inheritance = phenotype_map.find('phenotypeInheritance').text if phenotype_map.find('phenotypeInheritance') is not None else None
        phenotypes.append((phenotype, phenotype_mim_number, phenotype_mapping_key, phenotype_inheritance))

    return mim_number, preferred_title, phenotypes

with open("p_lp_mim_numbers.txt", "r") as f:
    mims = f.read().splitlines()

for i, mim in enumerate(mims, start=1):
    if mim=='':
        continue
    url = f"https://api.omim.org/api/entry?mimNumber={mim}&apiKey={api_key}&include=geneMap"
    response = requests.get(url)
    mim_number, preferred_title, phenotypes = extract_info(response.text)

    for phenotype in phenotypes:
        with open('diseases.txt', 'a', newline='') as csvfile:
            writer = csv.writer(csvfile, delimiter='\t')
            writer.writerow([mim_number, preferred_title, phenotype[0], phenotype[1], phenotype[2], phenotype[3]])

    if i % 500 == 0:  
        time.sleep(30)




