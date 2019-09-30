
READ ME


------------
| Folders: |
------------
- OLD: archived versions of various files
- MASTERFILES: copies of masterfiles **DO NOT DELETE ANYTHING IN THIS FOLDER**
- outputs_**: the folder that follows this naming convention is the current working directory for the script. 
- arcmapExports_batch**: the folder that follows this naming convention holds the FGDC xml files exported from ArcMap for the current batch.
- reformatDatesOnCSV: this folder contains the script to fix the date format on the master CDP and OnSite spreadsheets. Only use this script if the dates in the master spreadsheet are formatted as yyyy_mm_dd instead of yyyymmdd. 
- .ipynb_checkpoints: archived, previous edits of the python script

----------
| Files: |
----------
- MARC21slimUtils.xsl: XSLT stylesheet **DO NOT DELETE/ALTER THIS FILE**
- csvReader.ipynb: the python script **DO NOT DELETE/ALTER THIS FILE**
- xml_to_edit.csv: a list of the OwnerSuppliedNames for the xml files that you wish to edit using the script. Cell A1 must be 'file_name'. The OwnerSuppliedNames are listed in Column A.
- 'newCDP.csv': master spreadsheet for CDP files
- 'newOnSite.csv': master spreadsheet for OnSite files
- 'working_MARC21slim2FGDC_20180518': current version of the XSLT script


------------------------------------
| To-Do Before Running The Script: |
------------------------------------
- Make sure that the 'filePath' variable in the script matches the file path to the current outputs_** folder name.
- Make sure that the script has the name of the current XSLT script
- Place a copy of the XSLT stylesheet ('MARC21slimUtils') is in the outputs_** folder. A copy can be found in the MASTERFILES folder.
- Create an empty folder named 'final' in the outputs_** folder. This is where the final, updated metadata files will be after the scrpit is run.
- Make sure that the script is pointing to the correct master spreadsheet (CDP or OnSite).
- Copy and paste the files in arcmapExports_batch** into the outputs_** folder. This allows you to maintain a copy of unaltered FGDC xml files in case there is an error and the process must be redone.