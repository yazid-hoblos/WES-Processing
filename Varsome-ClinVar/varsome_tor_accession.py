from tbselenium.tbdriver import TorBrowserDriver
from stem import Signal
from stem.control import Controller
import re, time

variants_file = input("Enter the path for the file with the variants to be queried: ")
output = input("Enter the path wanted for the output file: ")

variants = []

with open(variants_file, "r") as o: #Extraction of the variants from the file
    for variant in o:
        variants.append(variant)


print(str(len(variants))+" variants are found.")

results=[]

url = 'https://stable-api.varsome.com/lookup/'
tbb_dir = "/mnt/c/Users/user/Documents/tor-browser"

driver = TorBrowserDriver(tbb_dir, headless=False) #initiation of the tor browser
i=0
with open (output,'w') as w:
    while i < len(variants):
        annotation_page = url + variants[i].strip() + "/hg19?add-ACMG-annotation=1&&annotation-mode=germline" #accessing each variant ACMG annotation with the specified query parameters
        try:
            driver.get(annotation_page)
        except Exception: #this is intended to prevent disruptions caused by sudden internet instabilities 
            print("Connection Issue")
            time.sleep(3)
            continue
        
        if "HTTP 429 Too Many Request" in driver.page_source: #Create new identity when blocked for too many requests
            driver.quit()
            driver = TorBrowserDriver(tbb_dir, headless=True)
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
        
        #if len(clinvar) > 0:
        #    with open("/mnt/c/Users/user/Desktop/WES_project/web-part/alpha2.txt",'w') as alpha:
        #        alpha.write(driver.page_source)
        #    alpha.close()
        
        
        pattern = r'classifications\".*?\"classifications'
        categories_regex = re.search(pattern, driver.page_source, re.DOTALL) #regex to extract the categories for the variant
        print(i+1) #outputting the progress of the query process
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


     