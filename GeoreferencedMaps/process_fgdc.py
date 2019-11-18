# **MAKE SURE THAT 'MARC21slimUtils' XSLT STYLESHEET IS IN THE 'outputs' FOLDER BEFORE RUNNING THIS SCRIPT!**
# https://lxml.de/xpathxslt.html
# lxml only supports XSLT 1 -- Saxon HE (open source version) has some Python support  https://www.saxonica.com/saxon-c/index.xml

import csv
import lxml.etree as ET
import datetime
import urllib.request

filePath = 'C:/Users/mam466/Desktop/HGL/metadataCreationScript2/outputs/'

a = 1

# open batch csv file with list of xml files (exported FGDC records from ArcGIS) for editing
with open('xml_to_edit.csv') as xmlList:
    XMLreader = csv.DictReader(xmlList)
    # iterate over list
    for line in XMLreader:

        # open csv file containing target information pulled from Dani's georef spreadsheets (CDP or OnSite csv)
        with open('newCDP.csv') as csvFile:

            # parse as a dictionary (OwnerSuppliedName can be used as a key)
            CSVreader = csv.DictReader(csvFile)
            for row in CSVreader:
                # match current XML file to information pulled from georef csv using OwnerSuppliedName as a key
                if row['OwnerSuppliedName'] == line['file_name']:

                     # ***** _____update XSLT_____ *****
                    # update XSLT file so that it contains current XML file that is being edited
                    # Read in the file
                    with open('single_sheet_MARC21slim2FGDC_20190104.xsl', 'r') as file:
                        filedata = file.read()

                        # Replace the target string with current XML file name
                        filedata = filedata.replace(
                            'rLayerID', line['file_name'])
                        # insert current date
                        todaysdate = str(datetime.date.today())
                        todaysdate = todaysdate.replace('-', '')
                        filedata = filedata.replace(
                            'xxx_todaysdate_xxx', todaysdate)

                    # Write the file out again
                    with open(filePath + 'outputXSLT.xsl', 'w') as file:
                        file.write(filedata)
                    print(line['file_name'] + ' XSLT updated')

                    # ***** _____run XSLT_____ *****

                    f_xsl = filePath + 'outputXSLT.xsl'
                    f_xml = filePath + line['file_name'] + '_APIdownload.xml'
                    f_out = filePath + line['file_name'] + '_XSLToutput.xml'

                    # download MARC record from API
                    HOLLIS = (row['HOLLIS'])

                    if len(HOLLIS) == 9:
                        urllib.request.urlretrieve(
                            'http://webservices.lib.harvard.edu/rest/marc/hollis/' + row['HOLLIS'], f_xml)
                        print('MARC record downloaded from API')
                    elif len(HOLLIS) == 8:
                        urllib.request.urlretrieve(
                            'http://webservices.lib.harvard.edu/rest/marc/hollis/0' + row['HOLLIS'], f_xml)
                        print('MARC record downloaded from API')
                    elif len(HOLLIS) == 7:
                        urllib.request.urlretrieve(
                            'http://webservices.lib.harvard.edu/rest/marc/hollis/00' + row['HOLLIS'], f_xml)
                        print('MARC record downloaded from API')
                    else:
                        print(
                            'Error with ' + line['file_name'] + ' HOLLIS number. PLEASE CHECK!')
                        print('The HOLLIS number is ' +
                              len(HOLLIS) + ' numbers long')

                    dom = ET.parse(f_xml)
                    xslt = ET.parse(f_xsl)
                    transform = ET.XSLT(xslt)
                    newdom = transform(dom)
                    newdom.write(f_out, pretty_print=True,
                                 xml_declaration=True, encoding='UTF-8')

                    print('XSLT transformation run')

                    # ***** _____update FGDC record with target infomration_____ *****
                    # open and parse current XML file using ElementTree library
                    with open(filePath + line['file_name']+'_XSLToutput.xml', encoding="utf8") as f:
                        tree = ET.parse(f)
                        root = tree.getroot()

                        # index in to: /metadata/idinfo/citation/citeinfo/onlink - 'rLayerID'
                        #target1 = root[0][0][0][8]
                        # index in to: /metadata/idinfo/descript/abstract – rProjection
                        #target2 = root[0][1][0]
                        # index in to: /metadata/idinfo/native - xxx_SoftwareVersion_xxx
                        #target3 = root[0][9]
                        # index in to: /metadata/dataqual/posacc/horizpa/horizpar - rRMS rUnits
                        #target4 = root[1][2][0][0]
                        # index in to: /metadata/dataqual/lineage/procstep/procdesc – rDataSources rProjection
                        #target5 = root[1][3][1][0]

                        #target1.text = target1.text.replace('http://hgl.harvard.edu:8080/HGL/jsp/HGL.jsp?action=VColl&VCollName=rLayerID','http://hgl.harvard.edu:8080/HGL/jsp/HGL.jsp?action=VColl&VCollName=' + row['OwnerSuppliedName'])
                        # target2.text = target2.text.replace(''This layer is a georeferenced raster image of the historic paper map entitled: Ducatus Chablasius et Lacus Lemanus cum regionibus adjacentibus / It was published by: [Apud Haeredes Ioannes Blaeu], in 1682. Scale [ca. 1:220,000].\n                    \n                The image inside the map neatline is georeferenced to the surface of the earth and fit to the rProjection coordinate system. All map collar and inset information is also available as part of the raster image, including any inset maps, profiles, statistical tables, directories, text, illustrations, index maps, legends, or other information associated with the principal map. \n                    \n                This map shows features such as drainage, cities and other human settlements, territorial boundaries, shoreline features, and more.  rRelief  Includes also\n                    \n                This layer is part of a selection of digitally scanned and georeferenced historic maps from the Harvard Map Collection. These maps typically portray both natural and manmade features. The selection represents a range of originators, ground condition dates, scales, and map purposes.', )
                        #target3.text = target3.text.replace('xxx_SoftwareVersion_xxx', row['ArcGIS_version'])
                        #target4.text = target4.text.replace
                        #target5.text = target5.text.replace

                    tree.write(filePath + '/final/' + line['file_name']+'.xml',
                               xml_declaration=True, method='xml', encoding="utf8")

                    # ***___manually update target information contained in text blocks in current XML using Python___***
                    with open(filePath + '/final/' + line['file_name']+'.xml', 'r', encoding="utf8") as file2:
                        filedata = file2.read()

                        filedata = filedata.replace(
                            'rLayerID', row['OwnerSuppliedName'])

                        SoftwareVersion = str(row['ArcGIS_version'])
                        if SoftwareVersion.upper().isupper() == False:
                            filedata = filedata.replace(
                                'xxx_SoftwareVersion_xxx', 'ArcMap ' + row['ArcGIS_version'])
                        else:
                            filedata = filedata.replace(
                                'xxx_SoftwareVersion_xxx', row['ArcGIS_version'])

                        filedata = filedata.replace(
                            'xxx_EPSG_xxx', row['EPSG_code'])

                        projection = row['Coord_Syst']
                        projection = projection.replace('_', ' ')
                        filedata = filedata.replace('rProjection', projection)

                        filedata = filedata.replace('rRMS', row['RMS_error '])

                        RMS0 = row['RMS_error ']
                        if RMS0 == '0':
                            filedata = filedata.replace(
                                'rUnits', row['units'] + '. The RMS error for this map is listed as 0 because at least 4 control points must be used to calculate an RMS error')
                        else:
                            filedata = filedata.replace('rUnits', row['units'])

                        basemap = row['Georeferenced_to..']
                        basemap = basemap.replace('_', ' ')
                        filedata = filedata.replace('rDataSources', basemap)

                        rightnow = datetime.datetime.now()
                        currentyear = str(rightnow.year)
                        currentmonth = str(rightnow.month)
                        if len(currentmonth) == 1:
                            PubMonth = currentyear + '0' + currentmonth
                        else:
                            PubMonth = currentyear + currentmonth
                        filedata = filedata.replace(
                            'xxx_PubMonth_xxx', PubMonth)

                        # use conditional statement to search for Notes
                        if row['notes'] == '':
                            filedata = filedata.replace(
                                'xxx_GeoRefNote_xxx', '')
                        else:
                            filedata = filedata.replace(
                                'xxx_GeoRefNote_xxx', '\n\n\t\t\tGeoreferencing note: '+row['notes']+'\n\n\t\t\t')

                    with open(filePath + '/final/' + line['file_name'] + '.xml', 'w+', encoding="utf8") as file3:
                        file3.write(filedata)

                    print(line['file_name'] + ' FGDC record edited')
                    if a == 1:
                        print(str(a) + ' FGDC record updated \n')
                    else:
                        print(str(a) + ' FGDC records updated\n')
                    a = a+1

xmlList.close()
file.close()
csvFile.close()
f.close()
file2.close()
file3.close()


print('Metadata creation process complete')
