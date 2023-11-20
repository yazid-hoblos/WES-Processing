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
    return mim_number, preferred_title

with open("p_lp_gene_names.txt", "r") as f:
    genes = f.read().splitlines()

for i, gene in enumerate(genes, start=1):
    url = f"https://api.omim.org/api/entry/search?search={gene}&sort=score&limit=1&apiKey={api_key}"
    response = requests.get(url)
    mim_number, preferred_title = extract_info(response.text)

    with open('mim_numbers.txt', 'a', newline='') as csvfile:
        writer = csv.writer(csvfile, delimiter='\t')
        writer.writerow([gene,mim_number, preferred_title])
    
    if i % 500 == 0:  
        time.sleep(30)




