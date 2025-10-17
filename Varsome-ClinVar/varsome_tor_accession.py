from tbselenium.tbdriver import TorBrowserDriver
from stem import Signal
from stem.control import Controller
import re, time
import argparse
import os
import sys

# Command-line arguments for input/output and Tor Browser directory
parser = argparse.ArgumentParser(description='Query Varsome stable API over Tor for variant ACMG annotations')
parser.add_argument('-i', '--input', required=True, help='Path to file with variants to be queried (one per line)')
parser.add_argument('-t', '--tor-dir', required=True, help='Path to Tor Browser (tbb) directory used by tbselenium')

parser.add_argument('-o', '--output', default='varsome_extracted_data.csv', help='Path for the output CSV file to write')
parser.add_argument('--interactive', action='store_true', help='Start Tor Browser in headless mode')
args = parser.parse_args()

variants_file = args.input
output = args.output
tbb_dir = args.tor_dir
headless = not(args.interactive)

if not os.path.exists(variants_file):
    print(f"Input file not found: {variants_file}")
    sys.exit(1)

variants = []
with open(variants_file, "r") as o: #Extraction of the variants from the file
    for variant in o:
        if variant.strip():
            variants.append(variant.strip())

print(str(len(variants))+" variants are found.")

results=[]

url = 'https://stable-api.varsome.com/lookup/'

# Normalize tor browser path and verify it exists and is a directory
tbb_dir = os.path.abspath(os.path.expanduser(tbb_dir))
if not os.path.isdir(tbb_dir):
    print(f"Error: TBB path is not a directory: {tbb_dir}\nProvide the path to your Tor Browser folder (the folder that contains the 'browser' subfolder). Example: /path/to/tor-browser/")
    sys.exit(2)

driver = TorBrowserDriver(tbb_dir, headless=headless) #initiation of the tor browser
i=0
with open (output,'w') as w:
    while i < len(variants):
        print(f'Processing variant: {variants[i].strip()}   ({i+1}/{len(variants)})')
        annotation_page = url + variants[i].strip() + "/hg19?add-ACMG-annotation=1&&annotation-mode=germline" #accessing each variant ACMG annotation with the specified query parameters
        try:
            driver.get(annotation_page)
        except Exception: #this is intended to prevent disruptions caused by sudden internet instabilities 
            print("Connection Issue")
            time.sleep(3)
            continue
        
        if "HTTP 429 Too Many Request" in driver.page_source: #Create new identity when blocked for too many requests
            driver.quit()
            driver = TorBrowserDriver(tbb_dir, headless=headless)
            continue
        
            
        verdict = re.findall(r"verdict.*\b", driver.page_source) #regex to find the verdict
        
        clinvar_verdict=''
        clinvar_review=''
        #clinvar = re.findall(r"clinical_significance.*\n.*", driver.page_source)
        clinvar_matches = re.findall(r"clinical_significance.*?\[.*?\]", driver.page_source, re.DOTALL)
        review = re.findall(r"review_status.*", driver.page_source)
        if len(clinvar_matches) > 0:
            #clinvar_verdict = clinvar[0].split("\n")[1].split("\">\"")[1].split("\"<")[0]
            clinvar_raw = clinvar_matches[0].split('\n')
            index=1
            clinvar_verdict=clinvar_raw[index].split("\">\"")[1].split("\"<")[0]
            index+=1
            while index < len(clinvar_raw)-1:
                clinvar_verdict=clinvar_verdict+";"+clinvar_raw[index].split("\">\"")[1].split("\"<")[0]
                index+=1
            clinvar_review = review[0].split("\">\"")[1].split("\"<")[0]
        
        
        pattern = r'classifications\".*?\"classifications'
        categories_regex = re.search(pattern, driver.page_source, re.DOTALL) #regex to extract the categories for the variant
        # print(i+1) #outputting the progress of the query process
        if len(verdict) == 0: #if an error message is returned
            if "::" in re.findall(r"detail.*\b", driver.page_source)[0]:
                error=re.findall(r"detail.*\b", driver.page_source)[0].split("::")[1].split(".\"<")[0]
            else:
                error=re.findall(r"detail.*\b", driver.page_source)[0].split("\">\"")[1].split(". P")[0]
            results.append((variants[i].strip(),'not found'))
            categories='none'
        else:
            error=''
            filtered_categories=categories_regex.group(0).split('\n')
            n=len(filtered_categories)-4
            categories=filtered_categories[n].split("\">\"")[1].split("\"<")[0]
            n-=1
            while n > 0: #extract all categories and store them seperated by spaces
                categories=categories+" "+filtered_categories[n].split("\">\"")[1].split("\"<")[0]
                n-=1
            if '{' in verdict[1]:
                #print(l[0]+"  -  "+variants[i].strip())
                results.append((variants[i].strip(),verdict[2].split("\">\"")[1].split("\"<")[0]))
            else:
                results.append((variants[i].strip(),verdict[1].split("\">\"")[1].split("\"<")[0]))
        w.write(results[i][0]+','+results[i][1]+','+categories+','+clinvar_verdict+','+clinvar_review.replace(',',';')+','+error+'\n') #write into the output file
        i += 1


     
