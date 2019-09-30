<?xml version="1.0" encoding="UTF-8"?>
 <xsl:stylesheet version="1.0" xmlns:marc="http://www.loc.gov/MARC21/slim"  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="marc">
    <xsl:import href="MARC21slimUtils.xsl"/>
     
     <!-- QUESTION : Is this the correct way to assert the doctype in the header? -->
     <xsl:output method="xml" encoding="UTF-8" indent="yes" doctype-system="http://www.fgdc.gov/metadata/fgdc-std-001-1998.dtd"/>
     
     <!-- ENHANCE - DATETYPE LOGIC and DATES OUTPUT / 
            -add logic for codes: i, k, p, r, t. n, c, d, u
            -add logic for converting uu and null values 
            -add logic for 'q' - questionable date when not a range
          ENHANCE - MANUSCRIPT
          - update abstract "produced", remove publisher; update source publisher "no publisher" = abstract "publisher unknown" src "unknown", 
                    place of publication "no place of publication" = src "unknown";
            update date currency statement "production date"
          ENHANCE - DUPLICATE KEYWORDS
          - build in logic to remove duplicates
          ENHANCE - when a map is extracted from something, from note in other citation
          ENHANCE - untitled maps, fix [] and update abstract text
          UPDATE - no publisher to publisher unknown for published items
          UPDATE - SCALE
          -fix double punctuation after some instances of Scale e.g. "Scale not given."
     -->

<xsl:template match="/">
    <metadata>
        <xsl:apply-templates/>
    </metadata>
</xsl:template>
 
<xsl:template name="chopPunctuationBackWithoutPeriod">
     <xsl:param name="chopString"/>
     <xsl:param name="punctuation">
         <xsl:text>:,;/] </xsl:text>
     </xsl:param>
     <xsl:variable name="length" select="string-length($chopString)"/>
     <xsl:choose>
         <xsl:when test="$length=0"/>
         <xsl:when test="contains($punctuation, substring($chopString,$length,1))">
             <xsl:call-template name="chopPunctuation">
                 <xsl:with-param name="chopString" select="substring($chopString,1,$length - 1)"/>
                 <xsl:with-param name="punctuation" select="$punctuation"/>
             </xsl:call-template>
         </xsl:when>
         <xsl:when test="not($chopString)"/>
         <xsl:otherwise>
             <xsl:value-of select="$chopString"/>
         </xsl:otherwise>
     </xsl:choose>
 </xsl:template>

 <xsl:template name="createNamePersonal">
     <xsl:variable name="AuthorA" select="marc:subfield[@code='a']"></xsl:variable>
     <xsl:variable name="AuthorD" select="marc:subfield[@code='d']"></xsl:variable>
     
     <xsl:variable name="AuthorAChop">
         <xsl:call-template name="chopPunctuationBackWithoutPeriod">
             <xsl:with-param name="chopString">
                 <xsl:value-of select="$AuthorA"/>
             </xsl:with-param>
         </xsl:call-template>
     </xsl:variable>
     
    <xsl:variable name="subfieldAEndValue" select="substring($AuthorAChop, string-length($AuthorAChop),1)" />
    <xsl:variable name="subfieldASpaceValue" select="substring($AuthorAChop, string-length($AuthorAChop)-2,1)" /> 
 
    
    <xsl:variable name="AuthorAMinusPeriod">
        <xsl:if test="$subfieldAEndValue = '.'">
            <xsl:choose>
                <xsl:when test="$subfieldASpaceValue = ' '">
                    <xsl:value-of select="$AuthorAChop" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring($AuthorAChop, 1, string-length($AuthorAChop)-1)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
     </xsl:variable>
  
     <xsl:variable name="AuthorAFinal">
         <xsl:choose>
             <xsl:when test="$AuthorAMinusPeriod != ''"><xsl:value-of select="$AuthorAMinusPeriod"></xsl:value-of></xsl:when>
             <xsl:otherwise><xsl:value-of select="$AuthorAChop"/></xsl:otherwise>
         </xsl:choose>
     </xsl:variable>
  
     <xsl:variable name="AuthorDChop">
         <xsl:call-template name="chopPunctuationBack">
             <xsl:with-param name="chopString">
                 <xsl:value-of select="$AuthorD"/>
             </xsl:with-param>
         </xsl:call-template>
     </xsl:variable>
     
     <xsl:variable name="AuthorPrint">
         <xsl:choose>
             <xsl:when test="$AuthorDChop != ''"><xsl:value-of select="concat($AuthorAFinal,', ',$AuthorDChop)"/></xsl:when>
             <xsl:otherwise><xsl:value-of select="$AuthorAFinal"/></xsl:otherwise>
         </xsl:choose>
     </xsl:variable>
     
     <origin><xsl:value-of select="$AuthorPrint" /></origin>
</xsl:template>
     
<xsl:template name="createNameCorporate">
         <xsl:variable name="AuthorA" select="marc:subfield[@code='a']"></xsl:variable>
         <xsl:variable name="AuthorD" select="marc:subfield[@code='d']"></xsl:variable>
         
         <xsl:variable name="AuthorAChop">
             <xsl:call-template name="chopPunctuationBack">
                 <xsl:with-param name="chopString">
                     <xsl:value-of select="$AuthorA"/>
                 </xsl:with-param>
             </xsl:call-template>
         </xsl:variable>
         
         <xsl:variable name="AuthorDChop">
             <xsl:call-template name="chopPunctuationBack">
                 <xsl:with-param name="chopString">
                     <xsl:value-of select="$AuthorD"/>
                 </xsl:with-param>
             </xsl:call-template>
         </xsl:variable>
         
         <xsl:variable name="AuthorPrint">
             <xsl:choose>
                 <xsl:when test="$AuthorDChop != ''"><xsl:value-of select="concat($AuthorAChop,', ',$AuthorDChop)"/></xsl:when>
                 <xsl:otherwise><xsl:value-of select="$AuthorAChop"/></xsl:otherwise>
             </xsl:choose>
         </xsl:variable>
         
         <origin><xsl:value-of select="$AuthorPrint" /></origin>
 </xsl:template>

<xsl:template match="marc:record">
    <xsl:variable name="titleA" select="marc:datafield[@tag=245]/marc:subfield[@code='a']"></xsl:variable>
    <xsl:variable name="titleAChop">
        <xsl:call-template name="chopPunctuationBack">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$titleA"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="titleB" select="marc:datafield[@tag=245]/marc:subfield[@code='b']"></xsl:variable>
    <xsl:variable name="titleBChop">
        <xsl:call-template name="chopPunctuationBack">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$titleB"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="scale" select="marc:datafield[@tag=255]/marc:subfield[@code='a']"></xsl:variable>
    <xsl:variable name="scaleDenominator" select="marc:datafield[@tag=034]/marc:subfield[@code='b']"></xsl:variable>
    <xsl:variable name="scaleDenominatorText">
        <xsl:choose>
            <xsl:when test="$scaleDenominator != ''"><xsl:value-of select="$scaleDenominator"/></xsl:when>
            <xsl:otherwise>Scale not given</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    
    <xsl:variable name="titleAandB">
        <xsl:choose>
            <xsl:when test="$titleBChop != ''"><xsl:value-of select="concat($titleAChop,' : ',$titleBChop)"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$titleAChop"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
        
    <!-- identify datetype MARC code -->
    <xsl:variable name="datetype" select="substring(marc:controlfield[@tag=008],7,1)"></xsl:variable>
    
    <!-- set date1 pubdate -->
     <xsl:variable name="date1">
                <xsl:value-of select="substring(marc:controlfield[@tag=008],8,4)"/>
     </xsl:variable>
    
    <!-- set date2 pubdate -->
    <xsl:variable name="date2">
                <xsl:value-of select="substring(marc:controlfield[@tag=008],12,4)"/>
    </xsl:variable>
    
    <!-- set approximate date indicator-->
    <!-- if 264 $$c or 260 $$c contains '?' or 'between' or "ca." or 
        "date of publication not identified" or "or" or "after" -->
    
    <xsl:variable name="c264text">
        <xsl:value-of select="marc:datafield[@tag=264][@ind2=1]/marc:subfield[@code='c']"/>
    </xsl:variable>
    
    <xsl:variable name="c260text">
        <xsl:value-of select="marc:datafield[@tag=260]/marc:subfield[@code='c']"/>
    </xsl:variable>
    
    <xsl:variable name="c26Xtext">
        <xsl:choose>
            <xsl:when test="$c264text != ''">
                <xsl:value-of select="$c264text"/>
            </xsl:when>
            <xsl:when test="$c260text != ''">
                <xsl:value-of select="$c260text"/>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="approximatedate">
        <xsl:choose>
            <xsl:when test="contains($c26Xtext,'between') or contains($c26Xtext,'?') or contains($c26Xtext,'or') or contains($c26Xtext,'ca.') or contains($c26Xtext,'after')">TRUE</xsl:when>
            <xsl:otherwise>FALSE</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- set currentness reference text for main citation area -->
    
    <xsl:variable name="datecurrentnesstext">
        <xsl:choose>
            <xsl:when test="$approximatedate = 'TRUE'">source map approximate publication date</xsl:when>
            <xsl:otherwise>source map publication date</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- set currentness reference text for source citation area -->
    
    <xsl:variable name="scdatecurrentnesstext">
        <xsl:choose>
            <xsl:when test="$approximatedate = 'TRUE'">approximate publication date</xsl:when>
            <xsl:otherwise>publication date</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- set pubdate string -->
    
    <xsl:variable name="titlepubdatestring">
        <!-- use in <title> -->
        <xsl:choose>
            <!-- set single date/exact -->
            <xsl:when test="$datetype = 's' and $approximatedate = 'FALSE'">
                <xsl:value-of select="$date1"/>
            </xsl:when>
            <!-- set single date/approximate -->
            <xsl:when test="$datetype = 's' and $approximatedate = 'TRUE'">
                <xsl:value-of select="concat('ca. ',$date1)"/>
            </xsl:when>
            <!-- set detailed date / take only year -->
            <xsl:when test="$datetype = 'e'">
                <xsl:value-of select="$date1"/>
            </xsl:when>
            <!-- set date range -->
            <xsl:when test="$datetype = 'm'">
                <xsl:value-of select="concat($date1,'-',$date2)"/>
            </xsl:when>
            <xsl:when test="$datetype = 'q'">
                <xsl:value-of select="concat($date1,'-',$date2)"/>
            </xsl:when>
            
            <!-- NOT DONE set default -->
            
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="pubdatestring">
        <!-- Use in <abstract> -->
        <xsl:choose>
            <!-- set single date/exact -->
            <xsl:when test="$datetype = 's' and $approximatedate = 'FALSE'">
                <xsl:value-of select="concat(' in ',$date1)"/>
            </xsl:when>
            <!-- set single date/approximate -->
            <xsl:when test="$datetype = 's' and $approximatedate = 'TRUE'">
                <xsl:value-of select="concat(' ca. ',$date1)"/>
            </xsl:when>
            <!-- set detailed date / take only year -->
            <xsl:when test="$datetype = 'e'">
                <xsl:value-of select="concat(' in ',$date1)"/>
            </xsl:when>
            <!-- set date range -->
            <xsl:when test="$datetype = 'm'">
                <xsl:value-of select="concat(' between ', $date1,' and ',$date2)"/>
            </xsl:when>
            <xsl:when test="$datetype = 'q'">
                <xsl:value-of select="concat(' between ', $date1,' and ',$date2)"/>
            </xsl:when>
            
            <!-- NOT DONE set default -->
            
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="b260" select="marc:datafield[@tag=260]/marc:subfield[@code='b']"></xsl:variable>
    <xsl:variable name="b260Chop">
        <xsl:call-template name="chopPunctuationBack">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$b260"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="b264" select="marc:datafield[@tag=264][@ind2=1]/marc:subfield[@code='b']"></xsl:variable>
    <xsl:variable name="b264Chop">
        <xsl:call-template name="chopPunctuationBack">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$b264"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="a260" select="marc:datafield[@tag=260]/marc:subfield[@code='a']"></xsl:variable>
    <xsl:variable name="a260Chop">
        <xsl:call-template name="chopPunctuationFront">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$a260"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="a264" select="marc:datafield[@tag=264][@ind2=1]/marc:subfield[@code='a']"></xsl:variable>
    <xsl:variable name="a264Chop">
        <xsl:call-template name="chopPunctuationFront">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$a264"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="a260ChopBoth">
        <xsl:call-template name="chopPunctuationBack">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$a260Chop"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="a264ChopBoth">
        <xsl:call-template name="chopPunctuationBack">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$a264Chop"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="b260ChopBoth">
        <xsl:call-template name="chopPunctuationFront">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$b260Chop"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="b264ChopBoth">
        <xsl:call-template name="chopPunctuationFront">
            <xsl:with-param name="chopString">
                <xsl:value-of select="$b264Chop"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    
    <!-- ENHANCE - Add more logic for manuscripts:
      publisher unknown vs. not published
      place of publication unknown vs. not place of publication --> 
    
    <xsl:variable name="publisher">
        <xsl:choose>
            <xsl:when test="$b260ChopBoth != ''"><xsl:value-of select="$b260ChopBoth"/></xsl:when>
            <xsl:when test="$b264ChopBoth != ''"><xsl:value-of select="$b264ChopBoth"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="'no publisher'"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="placeOfPublication">
        <xsl:choose>
            <xsl:when test="$a260Chop != ''"><xsl:value-of select="$a260ChopBoth"/></xsl:when>
            <xsl:when test="$a264Chop != ''"><xsl:value-of select="$a264ChopBoth"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="'place of publication unknown'"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- set material language 
        ENHANCE - refine/test multiple language contigency in abstract - 
        Test - G5834_A425_1739_A6 prints 'Map in French. Map in Multiple languages.'
    -->
    <xsl:variable name="primarylanguagecode" select="substring(marc:controlfield[@tag=008],36,3)"></xsl:variable>
    <xsl:variable name="language">
        <!-- Use in <abstract> -->
        <xsl:choose>
            <!-- set language text -->
            <xsl:when test="$primarylanguagecode = 'ara'">Arabic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chi'">Chinese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cze'">Czech</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dut'">Dutch</xsl:when>
            <xsl:when test="$primarylanguagecode = 'eng'">English</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fre'">French</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ger'">German</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gre'">Greek</xsl:when>
            <xsl:when test="$primarylanguagecode = 'heb'">Hebrew</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hun'">Hungarian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ita'">Italian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'jpn'">Japanese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lat'">Latin</xsl:when> 
            <xsl:when test="$primarylanguagecode = 'per'">Persian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'por'">Portuguese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'rus'">Russian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'spa'">Spanish</xsl:when>       
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="HOLLISPermlink" select="marc:controlfield[@tag=001]"></xsl:variable>
    <xsl:variable name="file1" select="document('rLayerID_export.xml')"/>
    
        <idinfo>
            <citation>
                <citeinfo>
                    <origin>Harvard Map Collection, Harvard Library</origin>
                    <xsl:for-each select="marc:datafield[@tag=100]">
                        <xsl:call-template name="createNamePersonal"/>
                    </xsl:for-each>
                    <xsl:for-each select="marc:datafield[@tag=110] |marc:datafield[@tag=111]">
                        <xsl:call-template name="createNameCorporate"/>
                    </xsl:for-each>
                    <xsl:for-each select="marc:datafield[@tag=700]">
                        <xsl:call-template name="createNamePersonal"/>
                    </xsl:for-each>
                    <xsl:for-each select="marc:datafield[@tag=710] |marc:datafield[@tag=711]">
                        <xsl:call-template name="createNameCorporate"/>
                    </xsl:for-each>                
                

                    <pubdate>xxx_PubMonth_xxx</pubdate>

                    <title><xsl:value-of select="$titleAChop" />, <xsl:value-of select="$titlepubdatestring" /> (Raster Image)</title>
                    
                    <geoform>map</geoform>

               <pubinfo>
                    <pubplace>Cambridge, Massachusetts</pubplace>
                    <publish>Harvard Map Collection, Harvard Library</publish>
                </pubinfo>
                    
                    <onlink>http://hgl.harvard.edu:8080/HGL/jsp/HGL.jsp?action=VColl&amp;VCollName=rLayerID</onlink>

                </citeinfo>
            </citation>
           
            <descript>
               
                <abstract>This layer is a georeferenced raster image of the historic paper map entitled: <xsl:value-of select="$titleAandB"/>. It was published by: <xsl:value-of select="$publisher"/><xsl:value-of select="$pubdatestring"/>. <xsl:value-of select="$scale"/>. <xsl:if test="$language != ''"><xsl:value-of select="concat(' Map in ',$language,'.')"/></xsl:if> <xsl:if test="marc:datafield[@tag=041]/marc:subfield[@code='a'] != ''"><xsl:value-of select="concat(' ','Map in multiple languages.')"/></xsl:if>
                    
                    The image inside the map neatline is georeferenced to the surface of the earth and fit to the rProjection (EPSG: xxx_EPSG_xxx) coordinate system. All map features and collar and inset information are shown as part of the raster image, including any inset maps, profiles, statistical tables, directories, text, illustrations, index maps, legends, or other information associated with the principal map. 
                    
                This layer is part of a selection of digitally scanned and georeferenced historic maps from the Harvard Map Collection. These maps typically portray both natural and manmade features. The selection represents a range of geographies, originators, ground condition dates, scales, and map purposes.</abstract>
                <purpose>Historic paper maps can provide an excellent view of the changes that have occurred in the cultural and physical landscape.  The wide range of information provided on these maps make them useful in the study of historic geography, and urban and rural land use change.  As this map has been georeferenced, it can be used in a GIS as a source or background layer in conjunction with other GIS data.</purpose>
            </descript>
            
            
            <!-- ENHANCE - xsl:if for more date types -->
            
            <xsl:if test="$datetype = 's'">
                <timeperd>
                    <timeinfo>
                        <sngdate>
                            <caldate><xsl:value-of select="$date1"/></caldate>
                        </sngdate>
                    </timeinfo>
                    <current><xsl:value-of select="$datecurrentnesstext"/></current>
                </timeperd>
            </xsl:if>
            <xsl:if test="$datetype = 'e'">
                <timeperd>
                    <timeinfo>
                        <sngdate>
                            <caldate><xsl:value-of select="$date1"/><xsl:value-of select="$date2"/></caldate>
                        </sngdate>
                    </timeinfo>
                    <current><xsl:value-of select="$datecurrentnesstext"/></current>
                </timeperd>
            </xsl:if>
            <xsl:if test="$datetype = 'm'">
                <timeperd>
                    <timeinfo>
                        <rngdates>
                            <begdate><xsl:value-of select="$date1"/></begdate>
                            <enddate><xsl:value-of select="$date2"/></enddate>
                        </rngdates>
                    </timeinfo>
                    <current><xsl:value-of select="$datecurrentnesstext"/></current>
                </timeperd>
            </xsl:if>
            <xsl:if test="$datetype = 'q'">
                <timeperd>
                    <timeinfo>
                        <rngdates>
                            <begdate><xsl:value-of select="$date1"/></begdate>
                            <enddate><xsl:value-of select="$date2"/></enddate>
                        </rngdates>
                    </timeinfo>
                    <current><xsl:value-of select="$datecurrentnesstext"/></current>
                </timeperd>
            </xsl:if>
            <status>
                <progress>Complete</progress>
                <update>None planned</update>
            </status>
            <spdom>
                <xsl:copy-of select="$file1/metadata/idinfo/spdom/bounding"/>
            </spdom>
            <keywords>
                    <theme>
                        <themekt>LCSH</themekt>
                        <themekey>Maps</themekey>
                        
                        <xsl:for-each select="marc:datafield[@tag=650] [@ind2=0]">
                        <themekey><xsl:value-of select="marc:subfield[@code='a']" /></themekey>
                        </xsl:for-each>
                        <xsl:for-each select="marc:datafield[@tag=655] [@ind2=7]">
                        <xsl:variable name="genre"><xsl:value-of select="marc:subfield[@code='a']"/></xsl:variable>
                        <xsl:variable name="thesaurus"><xsl:value-of select="marc:subfield[@code='2']"/></xsl:variable>
                        <xsl:if test="$genre != 'Maps.' and $thesaurus = 'lcgft'"> 
                            <!--  Strip ending periods in 655s -->
                            <xsl:variable name="a655"><xsl:value-of select="marc:subfield[@code='a']" /></xsl:variable>
                            <xsl:variable name="a655Chop">
                                <xsl:call-template name="chopPunctuationBack">
                                    <xsl:with-param name="chopString">
                                        <xsl:value-of select="$a655"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:variable>
                        <themekey><xsl:value-of select="$a655Chop" /></themekey>
                        </xsl:if>
                        </xsl:for-each>
                    </theme>
                                
                    <theme>
                        <!-- ENHANCE - Add logic for converting LCSH to ISOs? -->
                        <themekt>ISO 19115 Topic Category</themekt>
                        <themekey>imageryBaseMapsEarthCover</themekey>
                    </theme>
                    <!-- ENHANCE - Check for null 
                    
                    World maps are an exception
                    -->
                    <place>
                        <placekt>LCSH</placekt>
                        <xsl:for-each select="marc:datafield[@tag=651] [@ind2=0]">
                        <placekey><xsl:value-of select="marc:subfield[@code='a']" /></placekey>
                        </xsl:for-each>
                    </place>
            </keywords>
            <accconst>None</accconst>
            <useconst>For educational, non-commercial use only.</useconst>
            <ptcontac>
                <cntinfo>
                    <cntorgp>
                        <cntorg>Harvard Map Collection, Harvard Library</cntorg>
                    </cntorgp>
                    <cntpos>Harvard Geospatial Library</cntpos>
                    <cntaddr>
                        <addrtype>mailing and physical address</addrtype>
                        <address>Harvard Map Collection</address>
                        <address>Pusey Library</address>
                        <address>Harvard University</address>
                        <city>Cambridge</city>
                        <state>MA</state>
                        <postal>02138</postal>
                        <country>USA</country>
                    </cntaddr>
                    <cntvoice>617-495-2417</cntvoice>
                    <cntfax>617-496-0440</cntfax>
                    <cntemail>hgl_ref@hulmail.harvard.edu</cntemail>
                    <hours>Monday - Friday, 10:30 am - 4:30 pm EST-USA</hours>
                </cntinfo>
            </ptcontac>
            <native>xxx_SoftwareVersion_xxx</native>
            
            <!-- ENHANCE - <crossref> need to figure out logic for multi-sheet maps-->

        </idinfo>

    <dataqual>
        <attracc>
            <attraccr>The georeferenced raster is a faithfully reproduced digital image of the original source map. Some differences may be detected between the source graphic used and the raster image due to the RGB values assigned that particular color. The intent is to recreate those colors as near as possible.</attraccr>
        </attracc>
        <complete>Data completeness for raster digital image files reflect content of the source graphic. Features may have been eliminated or generalized on the source graphic due to scale and legibility constraints</complete>
        <posacc>
            <horizpa>
                <horizpar>The horizontal positional accuracy of a raster image is approximately the same as the accuracy of the published source map.  The lack of a greater accuracy is largely the result of the inaccuracies with the original measurements and possible distortions in the original paper map document. xxx_GeoRefNote_xxx There may also be errors introduced during the digitizing and georeferencing process. In most cases, however, errors in the raster image are small compared with sources of error in the original map graphic.  
                    
                    The RMS error for this map is rRMS rUnits.  This value describes how consistent the transformation is between the different control points (links).  The RMS error is only an assessment of the accuracy of the transformation.
               </horizpar>
            </horizpa>
        </posacc>
        <lineage>
            <srcinfo>
                <srccite>
                    <citeinfo>
                        <xsl:for-each select="marc:datafield[@tag=100]">
                            <xsl:call-template name="createNamePersonal"/>
                        </xsl:for-each>
                        <xsl:for-each select="marc:datafield[@tag=110] |marc:datafield[@tag=111]">
                            <xsl:call-template name="createNameCorporate"/>
                        </xsl:for-each>
                        <xsl:for-each select="marc:datafield[@tag=700]">
                            <xsl:call-template name="createNamePersonal"/>
                        </xsl:for-each>
                        <xsl:for-each select="marc:datafield[@tag=710] |marc:datafield[@tag=711]">
                            <xsl:call-template name="createNameCorporate"/>
                        </xsl:for-each>   
                        <pubdate><xsl:value-of select="$date1"/></pubdate>
                        <title><xsl:value-of select="$titleAandB"/></title>
                        <geoform>map</geoform>
                        <pubinfo>
                            <pubplace><xsl:value-of select="$placeOfPublication"/></pubplace>
                            <publish><xsl:value-of select="$publisher"/></publish>
                        </pubinfo>
                        <othercit><xsl:value-of select="marc:datafield[@tag=300]/marc:subfield[@code='a']"/><xsl:text> </xsl:text><xsl:value-of select="marc:datafield[@tag=300]/marc:subfield[@code='b']"/><xsl:text> </xsl:text><xsl:value-of select="marc:datafield[@tag=300]/marc:subfield[@code='c']"/></othercit>
                        <onlink>http://id.lib.harvard.edu/alma/<xsl:value-of select="$HOLLISPermlink"/>/catalog</onlink>
                    </citeinfo>
                </srccite>
                <xsl:choose>
                    <xsl:when test="$scaleDenominator != ''"><srcscale><xsl:value-of select="$scaleDenominatorText"/></srcscale></xsl:when>
                </xsl:choose>
                <typesrc>paper</typesrc>
                
                
                <!-- ENHANCE - xsl:if for different date types for source dates -->
                
                <srctime>                
                    <xsl:if test="$datetype = 's'">
                        <timeinfo>
                            <sngdate>
                                <caldate><xsl:value-of select="$date1"/></caldate>
                            </sngdate>
                        </timeinfo>
                        <srccurr><xsl:value-of select="$scdatecurrentnesstext"/></srccurr>
                    </xsl:if>
                <xsl:if test="$datetype = 'e'">
                    <timeinfo>
                            <sngdate>
                                <caldate><xsl:value-of select="$date1"/><xsl:value-of select="$date2"/></caldate>
                            </sngdate>
                    </timeinfo>
                    <srccurr><xsl:value-of select="$scdatecurrentnesstext"/></srccurr>
                    </xsl:if>
                <xsl:if test="$datetype = 'm'">
                    <timeinfo>
                            <rngdates>
                                <begdate><xsl:value-of select="$date1"/></begdate>
                                <enddate><xsl:value-of select="$date2"/></enddate>
                            </rngdates>
                    </timeinfo>
                    <srccurr><xsl:value-of select="$scdatecurrentnesstext"/></srccurr>
                </xsl:if>
                <xsl:if test="$datetype = 'q'">
                    <timeinfo>
                        <rngdates>
                            <begdate><xsl:value-of select="$date1"/></begdate>
                            <enddate><xsl:value-of select="$date2"/></enddate>
                        </rngdates>
                    </timeinfo>
                    <srccurr><xsl:value-of select="$scdatecurrentnesstext"/></srccurr>
                </xsl:if>
                   
                    
                </srctime>
                <srccitea>Paper Map</srccitea>
                <srccontr>Source map for raster image</srccontr>
            </srcinfo>
            <procstep>
                <procdesc>Production of this raster image began with the scanning of the paper map on a high-resolution scanner: (Betterlight, Super8K2 scanning back camera and ViewFinder capture software). Maps were photographed at a copy stand. A vacuum easel and/or Plexiglas or points were used to secure loose maps. Foldouts and bound volumes were supported using cradles and built up foam core and matt board supports. The imaging specification was designed to produce detailed "Archival Master" images that, to the extent possible, are faithful reproductions of the originals, that capture the fine detail present in the originals, and that allow for detailed screen reproduction and print reproduction at up 1:1. Images in this collection were processed using: Adobe Photoshop/Aware JPEG2000 Content Creation Workstation. Images were saved as lossless JPEG2000 files to reduce storage needs and to facilitate variable size viewing. Color and tonal corrections were made using Adobe Photoshop. Image files were viewed on a calibrated monitor. Editing was performed in an ISO 3664 compliant proofing environment.</procdesc>
                <srcused>Paper Map</srcused>
                <procdate>2016</procdate>
                <srcprod>JP2 Map Image</srcprod>
                <proccont>
                    <cntinfo>
                        <cntorgp>
                            <cntorg>Harvard Library</cntorg>
                        </cntorgp>
                        <cntpos>Imaging Services</cntpos>
                        <cntaddr>
                            <addrtype>mailing and physical address</addrtype>
                            <address>Widener Library</address>
                            <address>Ground Floor, Room G-81</address>
                            <address>Harvard Yard</address>
                            <city>Cambridge</city>
                            <state>MA</state>
                            <postal>02138</postal>
                            <country>USA</country>
                        </cntaddr>
                        <cntvoice>617-495-3995</cntvoice>
                        <cntemail>imaging@fas.harvard.edu</cntemail>
                        <hours>Monday - Friday, 9:00 am - 5:00 pm ET-USA (phone &amp; email)</hours>
                    </cntinfo>
                </proccont>
            </procstep>
            <procstep>
                <procdesc>Using xxx_SoftwareVersion_xxx, the digital JPEG2000 image was georeferenced to common points located on digital vector shapefiles. For this image, the following vector shapefiles were used as a base map for reference: rDataSources. The base map data is projected in the rProjection (EPSG: xxx_EPSG_xxx) coordinate system, and the image was subsequently georeferenced to the same projection.
                    
                    A world file (.j2w) was automatically generated and saved in association with the digital image. See 'Horizontal Accuracy' for the RMS error of this image. Please note that the projection will need to be defined by the user in order to display the image with other projected data and the world file will need to be stored in the same root directory as the image.</procdesc>
                <srcused>JP2 Map Image</srcused> 
                <procdate>xxx_Production_Date_xxx</procdate>
                <srcprod>Georeferenced Raster Data</srcprod>
                <proccont>
                    <cntinfo>
                        <cntorgp>
                            <cntorg>Harvard Geospatial Library</cntorg>
                        </cntorgp>
                        <cntpos>Geospatial Data Technical Assistant</cntpos>
                        <cntaddr>
                            <addrtype>mailing and physical address</addrtype>
                            <address>Harvard University Information Technology</address>
                            <address>Library Technology Services</address>
                            <address>90 Mount Auburn Street</address>
                            <city>Cambridge</city>
                            <state>MA</state>
                            <postal>02138</postal>
                            <country>USA</country>
                        </cntaddr>
                        <cntvoice>617-495-2417</cntvoice>
                        <cntfax>617-496-0440</cntfax>
                        <cntemail>hgl_ref@hulmail.harvard.edu</cntemail>
                        <hours>Monday - Friday, 10:30 am - 4:30 pm EST-USA</hours>
                    </cntinfo>
                </proccont>
            </procstep>
        </lineage>
    </dataqual>

    <xsl:copy-of select="$file1/metadata/spdoinfo"/>

    <xsl:copy-of select="$file1/metadata/spref"/>

    <eainfo>
        <overview>
            <eaover>The indexes reference a color palette of RGB values from 0 through 255, representing the color value from the original paper sheet map. The colors on that sheet can represent relief, drainage, vegetation, populated places, cultural features, coastal hydrography, transportation features (roads, railroads, tracks and trails), spot elevations and boundaries. The colors are sometimes explained in a legend that is incorporated into the map inset or collar.</eaover>
            <eadetcit>Not applicable.</eadetcit>
        </overview>
    </eainfo>
    <distinfo>
        <distrib>
            <cntinfo>
                <cntorgp>
                    <cntorg>Harvard University Information Technology</cntorg>
                </cntorgp>
                <cntpos>Harvard Geospatial Library</cntpos>
                <cntaddr>
                    <addrtype>mailing and physical address</addrtype>
                    <address>Library Technology Services</address>
                    <address>90 Mount Auburn Street</address>
                    <city>Cambridge</city>
                    <state>MA</state>
                    <postal>02138</postal>
                    <country>USA</country>
                </cntaddr>
                <cntvoice>617-495-2417</cntvoice>
                <cntfax>617-496-0440</cntfax>
                <cntemail>hgl_ref@hulmail.harvard.edu</cntemail>
                <hours>Monday - Friday, 9:00 am - 4:00 pm EST-USA</hours>
            </cntinfo>
        </distrib>
        <resdesc>Downloadable Data</resdesc>
        <distliab>Although this data set has been developed by Harvard University, no warranty expressed or implied is made by the University as to the accuracy of the data and related materials. The act of distribution shall not constitute any such warranty, and no responsibility is assumed by the University in the use of this data, or related materials.</distliab>
        <stdorder>
            <digform>
                <digtinfo>
                    <formname>JPEG2000</formname>
                    <filedec>ZIP</filedec>
                </digtinfo>
                <digtopt>
                    <onlinopt>
                        <computer>
                            <networka>
                                <networkr>http://hgl.harvard.edu/</networkr>
                            </networka>
                        </computer>
                    </onlinopt>
                </digtopt>
            </digform>
            <fees>None</fees>
        </stdorder>
    </distinfo>
    <metainfo>
       <metd>xxx_todaysdate_xxx</metd>
       <metc>
            <cntinfo>
                <cntorgp>
                    <cntorg>Harvard Geospatial Library</cntorg>
                </cntorgp>
                <cntpos>Geospatial Metadata Librarian</cntpos>
                <cntaddr>
                    <addrtype>mailing and physical address</addrtype>
                    <address>Harvard University Information Technology</address>
                    <address>Library Technology Services</address>
                    <address>90 Mount Auburn Street</address>
                    <city>Cambridge</city>
                    <state>MA</state>
                    <postal>02138</postal>
                    <country>USA</country>
                </cntaddr>
                <cntvoice>617-495-2417</cntvoice>
                <cntfax>617-496-0440</cntfax>
                <cntemail>hgl_ref@hulmail.harvard.edu</cntemail>
                <hours>Monday - Friday, 10:30 am - 4:30 pm EST-USA</hours>
            </cntinfo>
        </metc>
        <metstdn>
            FGDC Content Standard for Digital Geospatial Metadata
        </metstdn>
        <metstdv>FGDC-STD-001-1998</metstdv>
        <mettc>local time</mettc>
    </metainfo>




    </xsl:template>
</xsl:stylesheet>
<!--http://creativecommons.org/licenses/zero/1.0/
Creative Commons 1.0 Universal
The person who associated a work with this document has dedicated this work to the 
Commons by waiving all of his or her rights to the work under copyright law and all 
related or neighboring legal rights he or she had in the work, to the extent allowable by law. 
-->
