# updateLACensus.py
# Gerald Walden
# 4/8/2022
# - Place metadata snippet files in 'snippets' folder
#   * Confirm snippet file paths in code below
# - Place xml files to be updated in 'source' folder
# - Updated versions of the 'source' xml files will be save to the 'updated' folder

'''
Description:
Iterates through geospatial xml files and iterate through many of the changes
described ocd n the "Latin American Census Datasets 2021" Wiki page (https://wiki.harvard.edu/confluence/x/7wfaE), currently steps 6-22; omitting step 17 for now. Step 23 also done manually for now.
* Step 4 (UTF-BOM) can be done on a folder of XML files using fixBOM.py
* To do: Integrate step 5 (XML DTD declaration)
'''
import datetime
import os
import re
from lxml import etree as et

'''
 Define working_directory path -- can be altered as needed. 
 This variable is used in the main() method toward the bottom of the file.
 Use in case the script is not finding the correct path. 
'''
working_directory = "/Bolivia_2012/python"

'''
-Themekey snippet files are grouped together in a dictionary
-Other snippet files are just identified with a file path. 

***themekeys dictionaries:
LCSH themekey files exist for each shapefile subject area, e.g.: 'housing', 
'migration', etc. Program will try to identify which themekey file to apply 
to each XML file by matching the filename to the subject (filename case insensitive)

For example, the code will match the dictionary entry "demographic" with 
"EVBOLIVIA2012DEMOGRAPHIC.xml", and will therefore apply the snippet file 
at the path "snippet/LCSH_themekeys_demographic.txt".

Obviously this relies on consistent naming between the dictionary keys and 
snippet files. If the xml file was instead called 
"EVBOLIVIA2012DEMOGRAPHY.xml", this process would fail to match (unless the 
dictionary key was also changed to "demography")

If this approach proves not to work, an alternative would be to prompt the 
user for which snippet file to use.
'''


themekeys = {
	"demographic":"snippet/LCSH_themekeys_demographic.txt",
	"economic" : "snippet/LCSH_themekeys_economic.txt",
	"housing" : "snippet/LCSH_themekeys_housing.txt",
	"migration" : "snippet/LCSH_themekeys_migration.txt",
	"social": "snippet/LCSH_themekeys_social.txt",
}

snippet_pubinfo = "snippet/pubinfo.txt"
snippet_timeperd = "snippet/timeperd.txt"
snippet_placekey = "snippet/LCSH_placekey.txt"
snippet_metainfo = "snippet/metainfo.txt"
snippet_ptcontac = "snippet/ptcontac.txt"
snippet_dataqual = "snippet/dataqual.txt"
snippet_distinfo = "snippet/distinfo.txt"

origin = et.fromstring("<origin>Instituto Nacional de Estadística (Bolivia)</origin>")

def announce(fname, txt):
	print(f"\n{fname} -- {txt}")

def errorMsg(txt):
	print("...error:", txt)

def runProcess(fname, fpath):
	'''
	Open a geospatial xml file and iterate through many of the changes
	described on the "Latin American Datasets 2021" Wiki page, currently steps 6-22; omitting step 17 for now, as it involves using ArcCatalog, not an existing 'snippet' file. Step 23 also done manually for now.
	(https://wiki.harvard.edu/confluence/x/7wfaE)

	'''
	
	fname = fname[:-4]

	with open(fpath, encoding="utf-8") as xmlfile:
		xml = et.parse(xmlfile)
		root = xml.getroot()
		idinfo=root.find("idinfo")
		citeinfo1 = root.find(".//citation/citeinfo")

		announce(fname, "Add origin tag")
		try:
			citeinfo1.insert(1, origin)
		except Exception as e:
			errorMsg(e)
		
		#Confirm title -- prompt for layer name to append to title
		citetitle = citeinfo1.find("title")
		print(f"\n{fname} -- Current title: ", citetitle.text)
		resp = input("Update title with layer name (y/n)?  ")
		if resp.lower() == "y":
			newTitle=input("Enter layer name (e.g. demographic, social, etc.):  ")
			citetitle.text = citetitle.text + " - " + newTitle.capitalize()
			print("Updated title:", citetitle.text)
		
		announce(fname, "Append //citeinfo/pubinfo after geoform")
		try:
			with open(snippet_pubinfo, encoding="utf-8") as pubinfoSnippet:
				#parse snippet file into xml
				pi = et.parse(pubinfoSnippet)
				pubinfo=pi.getroot()
				#Find the position of citeinfo child-element 'geoform' -- use this 'index' to insert 'pubinfo' in the appropriate position
				insertAt = citeinfo1.index(citeinfo1.find("geoform")) + 1
				citeinfo1.insert(insertAt,pubinfo)
		except Exception as e: 
			errorMsg(e)

		announce(fname, "Append //citeinfo/onlink")
		try: 
			filename = fname.lower()
			onlink = et.fromstring("<onlink>https://hgl.harvard.edu/catalog/harvard-" + filename +"</onlink>")
			citeinfo1.append(onlink)
		except Exception as e: 
			errorMsg(e)

		announce(fname, "Update timeperd")
		try:
			#get index of current timeperd element
			timeperdIndex=idinfo.index(idinfo.find("timeperd"))
			timeperd=root.find("idinfo/timeperd")
			idinfo.remove(timeperd)
				
			with open(snippet_timeperd, encoding="utf-8") as timeperdSnippet:
				tp = et.parse(timeperdSnippet)
				timeperd=tp.getroot()
				idinfo.insert(timeperdIndex, timeperd)
		except Exception as e: 
			errorMsg(e)
			
		
		announce(fname, "Add themekeys")
		keywords = idinfo.find("keywords")
		try: 
			for tk in themekeys.keys():
				# Try to match themekey snippet to appropriate file based on filename
				# get snippet filename w/o file extension
				tk_match = re.search(tk, fname.lower())
				
				#print(tk_match)
				if tk_match:
					print(f"{fname} matches to themekey snippet {tk}")
					try: 
						with open(themekeys[tk], encoding="utf-8") as tkSnippet:
							tk_el = et.parse(tkSnippet)
							tkroot = tk_el.getroot()
							keywords.insert(1, tkroot)
					except Exception as e1:
						print("    ...error:", e1)
		except Exception as e:
			errorMsg(e)

		announce(fname, "Add LCSH Placekey")
		try:
			with open(snippet_placekey, encoding="utf-8") as pkSnippet:
				pk = et.parse(pkSnippet)
				pkroot = pk.getroot()
				keywords.append(pkroot)
		except Exception as e:
			errorMsg(e)

		announce(fname, "Replace accconst")
		try:
			newAccconst = et.fromstring("<accconst>Restricted. Access is granted to Harvard University Affiliates only. Affiliates are limited to current faculty, staff and students.</accconst>")
			accconst = idinfo.find("accconst")
			accindex = idinfo.index(accconst)
			idinfo.remove(accconst)
			idinfo.insert(accindex,newAccconst)
		except Exception as e:
			errorMsg(e)

		announce(fname, "Replace useconst")
		try:
			newUseconst = et.fromstring("<useconst>For educational non-commercial use only.</useconst>")
			useconst = idinfo.find("useconst")
			useindex = idinfo.index(useconst)
			idinfo.remove(useconst)
			idinfo.insert(useindex,newUseconst)
		except Exception as e:
			errorMsg(e)

		announce(fname, "Replace ptcontac")
		try:
			ptcontac = idinfo.find("ptcontac")
			ptcindex = idinfo.index(ptcontac)
			idinfo.remove(ptcontac)
			with open(snippet_ptcontac, encoding="utf-8") as ptSnippet:
				pt = et.parse(ptSnippet)
				ptroot = pt.getroot()
				idinfo.insert(ptcindex, ptroot)
		except Exception as e:
			errorMsg(e)

		announce(fname, "Add dataqual section following metadata/idinfo")
		try:
			with open(snippet_dataqual, encoding="utf-8") as dqSnippet:
				dq = et.parse(dqSnippet)
				dqroot = dq.getroot()
				root.insert(1,dqroot)
		except Exception as e:
			errorMsg(e)

		# <spdo>, <spref> could be added, if first exported from shapefile
		# See step 17 on https://wiki.harvard.edu/confluence/x/7wfaE

		announce(fname, "Replace enttypl")
		try:
			enttypl = root.find(".//enttypl")
			etlOld = enttypl.text
			enttypl.text = fname
			etlNew=enttypl.text
			print(f"{etlOld} ==> {etlNew}")
		except Exception as e:
			errorMsg(e)

		announce(fname, "Replace enttypd")
		try:
			enttypd = root.find(".//enttypd")
			etdOld = enttypd.text
			enttypd.text = citetitle.text
			etdNew = enttypd.text
			print(f"{etdOld} ==> {etdNew}")
		except Exception as e:
			errorMsg(e)

		announce(fname, "Add distinfo following eainfo")
		try:
			eainfoIndex = root.index(root.find("eainfo"))
			with open(snippet_distinfo, encoding="utf-8") as diSnippet:
				di = et.parse(diSnippet)
				diRoot = di.getroot()
				root.insert(eainfoIndex+1, diRoot)
		except Exception as e:
			errorMsg(e)

		announce(fname, "Replace metainfo")
		try:
			metainfo = root.find(".//metainfo")
			miIndex = root.index(metainfo)
			root.remove(metainfo)
			with open(snippet_metainfo, encoding="utf-8") as miSnippet:
				mi = et.parse(miSnippet)
				miRoot = mi.getroot()
				root.insert(miIndex, miRoot)
		except Exception as e:
			errorMsg(e)

		announce(fname, "Update metainfo/metd with today's date")
		#zero-pad int n to two places: f'{n:02}'
		#zero-pad str n to two places: f.zfill(2)
		try:
			date = datetime.datetime.now()
			metdText = (f"{date.year}{date.month:02}{date.day:02}")
			metd = root.find(".//metainfo/metd")
			metd.text = metdText
		except Exception as e:
			errorMsg(e)

		# Could ArcPy retrieve column names for use in attr tags?

		#------------------------------------------------

		# - Create 'update' folder if it doesn't already exist
		# - Save updated xml files to 'updated'
		if not os.path.isdir("updated"):
			os.mkdir("updated")

		outputFileName = fname + ".xml"
		outputFilePath = os.path.join("updated", outputFileName)
		xml.write(outputFilePath, encoding="utf-8", xml_declaration=True)

def main():
	# Create list of metadata files to process (in 'source' directory)
	#  Set working directory if necessary
	#os.chdir(working_directory)
	metadata_files = []
	for f in os.listdir("source"):
		if f.endswith(".xml"):
			metadata_files.append(f)

	for filename in metadata_files:
		filepath = os.path.join("source", filename)
		runProcess(filename, filepath)

if __name__ == "__main__": 
	main()
