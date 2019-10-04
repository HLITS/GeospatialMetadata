<?xml version="1.0" encoding="UTF-8"?>
 <xsl:stylesheet version="1.0" xmlns:marc="http://www.loc.gov/MARC21/slim"  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="marc">
    <xsl:import href="MARC21slimUtils.xsl"/>
     
     <!-- QUESTION : Is this the correct way to assert the doctype in the header?
     GW: Yes, it looks OK to me, assuming the 'doctype-system' attribute is accurate. 
     -->
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
    
    <!-- set date2_unclear when date2 contains any of u,#,|,\s -->
    <xsl:variable name="date2_unclear">
        <xsl:choose>
            <xsl:when test = "contains($date2, 'u') or contains($date2, '#') or contains($date2, '|') or contains($date2, ' ')">TRUE</xsl:when>
            <xsl:otherwise>FALSE</xsl:otherwise>
        </xsl:choose>
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
    
    <!-- set pubdate string 
         ...use in title -->
   
    <xsl:variable name="titlepubdatestring">
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
            <!--
            <xsl:when test="$datetype = 'm' and $date2_unclear = 'FALSE'">
                <xsl:value-of select="concat($date1,'-',$date2)"/>
            </xsl:when>
            -->
           <xsl:when test="$datetype = 'q' or $datetype ='m' and $date2_unclear = 'FALSE'">
                <xsl:value-of select="concat($date1,'-',$date2)"/>
            </xsl:when>
            <!-- If date2_unclear is true and/or other tests above did not apply, use default of just one date value for titlepubdatestring -->
            <xsl:otherwise>
                <xsl:value-of select="concat('[', $date1, ']')"/>
            </xsl:otherwise>       
        </xsl:choose>
    </xsl:variable>
    
    
    <xsl:variable name="pubdatestring">
        <!-- Use in <abstract> -->
        <xsl:choose>
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
            <xsl:when test="$datetype = 'm' and $date2_unclear ='FALSE'">
                <xsl:value-of select="concat(' between ', $date1,' and ',$date2)"/>
            </xsl:when>
            <xsl:when test="$datetype = 'q' and $date2_unclear ='FALSE'">
                <xsl:value-of select="concat(' between ', $date1,' and ',$date2, ' (approximate dates)')"/>
            </xsl:when>
            
            <!-- Set default case to approximate single date -->
            <xsl:otherwise>
                <xsl:value-of select="concat(' ca. ',$date1)"/>
            </xsl:otherwise>
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
    <xsl:variable name="primarylanguagecode" select="substring(marc:controlfield[@tag=008],35,3)"></xsl:variable>
    <xsl:variable name="language">
        <!-- Use in <abstract> -->
        <xsl:choose>
            <!-- set language text -->
            <xsl:when test="$primarylanguagecode = 'aar' ">Afar</xsl:when>
            <xsl:when test="$primarylanguagecode = 'abk' ">Abkhaz</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ace' ">Achinese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ach' ">Acoli</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ada' ">Adangme</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ady' ">Adygei</xsl:when>
            <xsl:when test="$primarylanguagecode = 'afa' ">Afroasiatic (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'afh' ">Afrihili (Artificial language)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'afr' ">Afrikaans</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ain' ">Ainu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'aka' ">Akan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'akk' ">Akkadian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'alb' ">Albanian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ale' ">Aleut</xsl:when>
            <xsl:when test="$primarylanguagecode = 'alg' ">Algonquian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'alt' ">Altai</xsl:when>
            <xsl:when test="$primarylanguagecode = 'amh' ">Amharic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ang' ">English, Old (ca. 450-1100)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'anp' ">Angika</xsl:when>
            <xsl:when test="$primarylanguagecode = 'apa' ">Apache languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ara' ">Arabic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'arc' ">Aramaic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'arg' ">Aragonese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'arm' ">Armenian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'arn' ">Mapuche</xsl:when>
            <xsl:when test="$primarylanguagecode = 'arp' ">Arapaho</xsl:when>
            <xsl:when test="$primarylanguagecode = 'art' ">Artificial (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'arw' ">Arawak</xsl:when>
            <xsl:when test="$primarylanguagecode = 'asm' ">Assamese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ast' ">Bable</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ath' ">Athapascan (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'aus' ">Australian languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ava' ">Avaric</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ave' ">Avestan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'awa' ">Awadhi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'aym' ">Aymara</xsl:when>
            <xsl:when test="$primarylanguagecode = 'aze' ">Azerbaijani</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bad' ">Banda languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bai' ">Bamileke languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bak' ">Bashkir</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bal' ">Baluchi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bam' ">Bambara</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ban' ">Balinese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'baq' ">Basque</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bas' ">Basa</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bat' ">Baltic (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bej' ">Beja</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bel' ">Belarusian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bem' ">Bemba</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ben' ">Bengali</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ber' ">Berber (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bho' ">Bhojpuri</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bih' ">Bihari (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bik' ">Bikol</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bin' ">Edo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bis' ">Bislama</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bla' ">Siksika</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bnt' ">Bantu (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bos' ">Bosnian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bra' ">Braj</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bre' ">Breton</xsl:when>
            <xsl:when test="$primarylanguagecode = 'btk' ">Batak</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bua' ">Buriat</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bug' ">Bugis</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bul' ">Bulgarian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'bur' ">Burmese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'byn' ">Bilin</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cad' ">Caddo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cai' ">Central American Indian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'car' ">Carib</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cat' ">Catalan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cau' ">Caucasian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ceb' ">Cebuano</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cel' ">Celtic (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cha' ">Chamorro</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chb' ">Chibcha</xsl:when>
            <xsl:when test="$primarylanguagecode = 'che' ">Chechen</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chg' ">Chagatai</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chi' ">Chinese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chk' ">Chuukese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chm' ">Mari</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chn' ">Chinook jargon</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cho' ">Choctaw</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chp' ">Chipewyan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chr' ">Cherokee</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chu' ">Church Slavic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chv' ">Chuvash</xsl:when>
            <xsl:when test="$primarylanguagecode = 'chy' ">Cheyenne</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cmc' ">Chamic languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cnr' ">Montenegrin</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cop' ">Coptic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cor' ">Cornish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cos' ">Corsican</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cpe' ">Creoles and Pidgins, English-based (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cpf' ">Creoles and Pidgins, French-based (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cpp' ">Creoles and Pidgins, Portuguese-based (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cre' ">Cree</xsl:when>
            <xsl:when test="$primarylanguagecode = 'crh' ">Crimean Tatar</xsl:when>
            <xsl:when test="$primarylanguagecode = 'crp' ">Creoles and Pidgins (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'csb' ">Kashubian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cus' ">Cushitic (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'cze' ">Czech</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dak' ">Dakota</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dan' ">Danish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dar' ">Dargwa</xsl:when>
            <xsl:when test="$primarylanguagecode = 'day' ">Dayak</xsl:when>
            <xsl:when test="$primarylanguagecode = 'del' ">Delaware</xsl:when>
            <xsl:when test="$primarylanguagecode = 'den' ">Slavey</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dgr' ">Dogrib</xsl:when>
            <xsl:when test="$primarylanguagecode = 'din' ">Dinka</xsl:when>
            <xsl:when test="$primarylanguagecode = 'div' ">Divehi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'doi' ">Dogri</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dra' ">Dravidian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dsb' ">Lower Sorbian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dua' ">Duala</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dum' ">Dutch, Middle (ca. 1050-1350)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dut' ">Dutch</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dyu' ">Dyula</xsl:when>
            <xsl:when test="$primarylanguagecode = 'dzo' ">Dzongkha</xsl:when>
            <xsl:when test="$primarylanguagecode = 'efi' ">Efik</xsl:when>
            <xsl:when test="$primarylanguagecode = 'egy' ">Egyptian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'eka' ">Ekajuk</xsl:when>
            <xsl:when test="$primarylanguagecode = 'elx' ">Elamite</xsl:when>
            <xsl:when test="$primarylanguagecode = 'eng' ">English</xsl:when>
            <xsl:when test="$primarylanguagecode = 'enm' ">English, Middle (1100-1500)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'epo' ">Esperanto</xsl:when>
            <xsl:when test="$primarylanguagecode = 'est' ">Estonian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ewe' ">Ewe</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ewo' ">Ewondo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fan' ">Fang</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fao' ">Faroese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fat' ">Fanti</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fij' ">Fijian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fil' ">Filipino</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fin' ">Finnish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fiu' ">Finno-Ugrian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fon' ">Fon</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fre' ">French</xsl:when>
            <xsl:when test="$primarylanguagecode = 'frm' ">French, Middle (ca. 1300-1600)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fro' ">French, Old (ca. 842-1300)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'frr' ">North Frisian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'frs' ">East Frisian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fry' ">Frisian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ful' ">Fula</xsl:when>
            <xsl:when test="$primarylanguagecode = 'fur' ">Friulian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gaa' ">Gã</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gay' ">Gayo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gba' ">Gbaya</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gem' ">Germanic (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'geo' ">Georgian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ger' ">German</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gez' ">Ethiopic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gil' ">Gilbertese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gla' ">Scottish Gaelic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gle' ">Irish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'glg' ">Galician</xsl:when>
            <xsl:when test="$primarylanguagecode = 'glv' ">Manx</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gmh' ">German, Middle High (ca. 1050-1500)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'goh' ">German, Old High (ca. 750-1050)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gon' ">Gondi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gor' ">Gorontalo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'got' ">Gothic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'grb' ">Grebo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'grc' ">Greek, Ancient (to 1453)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gre' ">Greek, Modern (1453-)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'grn' ">Guarani</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gsw' ">Swiss German</xsl:when>
            <xsl:when test="$primarylanguagecode = 'guj' ">Gujarati</xsl:when>
            <xsl:when test="$primarylanguagecode = 'gwi' ">Gwich'in</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hai' ">Haida</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hat' ">Haitian French Creole</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hau' ">Hausa</xsl:when>
            <xsl:when test="$primarylanguagecode = 'haw' ">Hawaiian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'heb' ">Hebrew</xsl:when>
            <xsl:when test="$primarylanguagecode = 'her' ">Herero</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hil' ">Hiligaynon</xsl:when>
            <xsl:when test="$primarylanguagecode = 'him' ">Western Pahari languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hin' ">Hindi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hit' ">Hittite</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hmn' ">Hmong</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hmo' ">Hiri Motu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hrv' ">Croatian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hsb' ">Upper Sorbian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hun' ">Hungarian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'hup' ">Hupa</xsl:when>
            <xsl:when test="$primarylanguagecode = 'iba' ">Iban</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ibo' ">Igbo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ice' ">Icelandic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ido' ">Ido</xsl:when>
            <xsl:when test="$primarylanguagecode = 'iii' ">Sichuan Yi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ijo' ">Ijo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'iku' ">Inuktitut</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ile' ">Interlingue</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ilo' ">Iloko</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ina' ">Interlingua (International Auxiliary Language Association)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'inc' ">Indic (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ind' ">Indonesian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ine' ">Indo-European (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'inh' ">Ingush</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ipk' ">Inupiaq</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ira' ">Iranian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'iro' ">Iroquoian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ita' ">Italian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'jav' ">Javanese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'jbo' ">Lojban (Artificial language)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'jpn' ">Japanese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'jpr' ">Judeo-Persian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'jrb' ">Judeo-Arabic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kaa' ">Kara-Kalpak</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kab' ">Kabyle</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kac' ">Kachin</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kal' ">Kalâtdlisut</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kam' ">Kamba</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kan' ">Kannada</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kar' ">Karen languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kas' ">Kashmiri</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kau' ">Kanuri</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kaw' ">Kawi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kaz' ">Kazakh</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kbd' ">Kabardian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kha' ">Khasi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'khi' ">Khoisan (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'khm' ">Khmer</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kho' ">Khotanese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kik' ">Kikuyu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kin' ">Kinyarwanda</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kir' ">Kyrgyz</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kmb' ">Kimbundu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kok' ">Konkani</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kom' ">Komi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kon' ">Kongo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kor' ">Korean</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kos' ">Kosraean</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kpe' ">Kpelle</xsl:when>
            <xsl:when test="$primarylanguagecode = 'krc' ">Karachay-Balkar</xsl:when>
            <xsl:when test="$primarylanguagecode = 'krl' ">Karelian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kro' ">Kru (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kru' ">Kurukh</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kua' ">Kuanyama</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kum' ">Kumyk</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kur' ">Kurdish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'kut' ">Kootenai</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lad' ">Ladino</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lah' ">Lahndā</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lam' ">Lamba (Zambia and Congo)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lao' ">Lao</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lat' ">Latin</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lav' ">Latvian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lez' ">Lezgian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lim' ">Limburgish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lin' ">Lingala</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lit' ">Lithuanian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lol' ">Mongo-Nkundu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'loz' ">Lozi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ltz' ">Luxembourgish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lua' ">Luba-Lulua</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lub' ">Luba-Katanga</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lug' ">Ganda</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lui' ">Luiseño</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lun' ">Lunda</xsl:when>
            <xsl:when test="$primarylanguagecode = 'luo' ">Luo (Kenya and Tanzania)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'lus' ">Lushai</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mac' ">Macedonian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mad' ">Madurese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mag' ">Magahi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mah' ">Marshallese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mai' ">Maithili</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mak' ">Makasar</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mal' ">Malayalam</xsl:when>
            <xsl:when test="$primarylanguagecode = 'man' ">Mandingo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mao' ">Maori</xsl:when>
            <xsl:when test="$primarylanguagecode = 'map' ">Austronesian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mar' ">Marathi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mas' ">Maasai</xsl:when>
            <xsl:when test="$primarylanguagecode = 'may' ">Malay</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mdf' ">Moksha</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mdr' ">Mandar</xsl:when>
            <xsl:when test="$primarylanguagecode = 'men' ">Mende</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mga' ">Irish, Middle (ca. 1100-1550)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mic' ">Micmac</xsl:when>
            <xsl:when test="$primarylanguagecode = 'min' ">Minangkabau</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mis' ">Miscellaneous languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mkh' ">Mon-Khmer (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mlg' ">Malagasy</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mlt' ">Maltese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mnc' ">Manchu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mni' ">Manipuri</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mno' ">Manobo languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'moh' ">Mohawk</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mon' ">Mongolian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mos' ">Mooré</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mul' ">Multiple languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mun' ">Munda (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mus' ">Creek</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mwl' ">Mirandese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'mwr' ">Marwari</xsl:when>
            <xsl:when test="$primarylanguagecode = 'myn' ">Mayan languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'myv' ">Erzya</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nah' ">Nahuatl</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nai' ">North American Indian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nap' ">Neapolitan Italian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nau' ">Nauru</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nav' ">Navajo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nbl' ">Ndebele (South Africa)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nde' ">Ndebele (Zimbabwe)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ndo' ">Ndonga</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nds' ">Low German</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nep' ">Nepali</xsl:when>
            <xsl:when test="$primarylanguagecode = 'new' ">Newari</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nia' ">Nias</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nic' ">Niger-Kordofanian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'niu' ">Niuean</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nno' ">Norwegian (Nynorsk)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nob' ">Norwegian (Bokmål)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nog' ">Nogai</xsl:when>
            <xsl:when test="$primarylanguagecode = 'non' ">Old Norse</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nor' ">Norwegian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nqo' ">N'Ko</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nso' ">Northern Sotho</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nub' ">Nubian languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nwc' ">Newari, Old</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nya' ">Nyanja</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nym' ">Nyamwezi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nyn' ">Nyankole</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nyo' ">Nyoro</xsl:when>
            <xsl:when test="$primarylanguagecode = 'nzi' ">Nzima</xsl:when>
            <xsl:when test="$primarylanguagecode = 'oci' ">Occitan (post-1500)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'oji' ">Ojibwa</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ori' ">Oriya</xsl:when>
            <xsl:when test="$primarylanguagecode = 'orm' ">Oromo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'osa' ">Osage</xsl:when>
            <xsl:when test="$primarylanguagecode = 'oss' ">Ossetic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ota' ">Turkish, Ottoman</xsl:when>
            <xsl:when test="$primarylanguagecode = 'oto' ">Otomian languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'paa' ">Papuan (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pag' ">Pangasinan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pal' ">Pahlavi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pam' ">Pampanga</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pan' ">Panjabi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pap' ">Papiamento</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pau' ">Palauan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'peo' ">Old Persian (ca. 600-400 B.C.)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'per' ">Persian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'phi' ">Philippine (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'phn' ">Phoenician</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pli' ">Pali</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pol' ">Polish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pon' ">Pohnpeian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'por' ">Portuguese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pra' ">Prakrit languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pro' ">Provençal (to 1500)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'pus' ">Pushto</xsl:when>
            <xsl:when test="$primarylanguagecode = 'que' ">Quechua</xsl:when>
            <xsl:when test="$primarylanguagecode = 'raj' ">Rajasthani</xsl:when>
            <xsl:when test="$primarylanguagecode = 'rap' ">Rapanui</xsl:when>
            <xsl:when test="$primarylanguagecode = 'rar' ">Rarotongan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'roa' ">Romance (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'roh' ">Raeto-Romance</xsl:when>
            <xsl:when test="$primarylanguagecode = 'rom' ">Romani</xsl:when>
            <xsl:when test="$primarylanguagecode = 'rum' ">Romanian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'run' ">Rundi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'rup' ">Aromanian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'rus' ">Russian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sad' ">Sandawe</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sag' ">Sango (Ubangi Creole)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sah' ">Yakut</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sai' ">South American Indian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sal' ">Salishan languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sam' ">Samaritan Aramaic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'san' ">Sanskrit</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sas' ">Sasak</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sat' ">Santali</xsl:when>
            <xsl:when test="$primarylanguagecode = 'scn' ">Sicilian Italian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sco' ">Scots</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sel' ">Selkup</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sem' ">Semitic (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sga' ">Irish, Old (to 1100)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sgn' ">Sign languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'shn' ">Shan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sid' ">Sidamo</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sin' ">Sinhalese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sio' ">Siouan (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sit' ">Sino-Tibetan (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sla' ">Slavic (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'slo' ">Slovak</xsl:when>
            <xsl:when test="$primarylanguagecode = 'slv' ">Slovenian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sma' ">Southern Sami</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sme' ">Northern Sami</xsl:when>
            <xsl:when test="$primarylanguagecode = 'smi' ">Sami</xsl:when>
            <xsl:when test="$primarylanguagecode = 'smj' ">Lule Sami</xsl:when>
            <xsl:when test="$primarylanguagecode = 'smn' ">Inari Sami</xsl:when>
            <xsl:when test="$primarylanguagecode = 'smo' ">Samoan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sms' ">Skolt Sami</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sna' ">Shona</xsl:when>
            <xsl:when test="$primarylanguagecode = 'snd' ">Sindhi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'snk' ">Soninke</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sog' ">Sogdian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'som' ">Somali</xsl:when>
            <xsl:when test="$primarylanguagecode = 'son' ">Songhai</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sot' ">Sotho</xsl:when>
            <xsl:when test="$primarylanguagecode = 'spa' ">Spanish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'srd' ">Sardinian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'srn' ">Sranan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'srp' ">Serbian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'srr' ">Serer</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ssa' ">Nilo-Saharan (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ssw' ">Swazi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'suk' ">Sukuma</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sun' ">Sundanese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sus' ">Susu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'sux' ">Sumerian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'swa' ">Swahili</xsl:when>
            <xsl:when test="$primarylanguagecode = 'swe' ">Swedish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'syc' ">Syriac</xsl:when>
            <xsl:when test="$primarylanguagecode = 'syr' ">Syriac, Modern</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tah' ">Tahitian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tai' ">Tai (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tam' ">Tamil</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tat' ">Tatar</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tel' ">Telugu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tem' ">Temne</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ter' ">Terena</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tet' ">Tetum</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tgk' ">Tajik</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tgl' ">Tagalog</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tha' ">Thai</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tib' ">Tibetan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tig' ">Tigré</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tir' ">Tigrinya</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tiv' ">Tiv</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tkl' ">Tokelauan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tlh' ">Klingon (Artificial language)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tli' ">Tlingit</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tmh' ">Tamashek</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tog' ">Tonga (Nyasa)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ton' ">Tongan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tpi' ">Tok Pisin</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tsi' ">Tsimshian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tsn' ">Tswana</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tso' ">Tsonga</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tuk' ">Turkmen</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tum' ">Tumbuka</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tup' ">Tupi languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tur' ">Turkish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tut' ">Altaic (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tvl' ">Tuvaluan</xsl:when>
            <xsl:when test="$primarylanguagecode = 'twi' ">Twi</xsl:when>
            <xsl:when test="$primarylanguagecode = 'tyv' ">Tuvinian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'udm' ">Udmurt</xsl:when>
            <xsl:when test="$primarylanguagecode = 'uga' ">Ugaritic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'uig' ">Uighur</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ukr' ">Ukrainian</xsl:when>
            <xsl:when test="$primarylanguagecode = 'umb' ">Umbundu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'und' ">Undetermined</xsl:when>
            <xsl:when test="$primarylanguagecode = 'urd' ">Urdu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'uzb' ">Uzbek</xsl:when>
            <xsl:when test="$primarylanguagecode = 'vai' ">Vai</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ven' ">Venda</xsl:when>
            <xsl:when test="$primarylanguagecode = 'vie' ">Vietnamese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'vol' ">Volapük</xsl:when>
            <xsl:when test="$primarylanguagecode = 'vot' ">Votic</xsl:when>
            <xsl:when test="$primarylanguagecode = 'wak' ">Wakashan languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'wal' ">Wolayta</xsl:when>
            <xsl:when test="$primarylanguagecode = 'war' ">Waray</xsl:when>
            <xsl:when test="$primarylanguagecode = 'was' ">Washoe</xsl:when>
            <xsl:when test="$primarylanguagecode = 'wel' ">Welsh</xsl:when>
            <xsl:when test="$primarylanguagecode = 'wen' ">Sorbian (Other)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'wln' ">Walloon</xsl:when>
            <xsl:when test="$primarylanguagecode = 'wol' ">Wolof</xsl:when>
            <xsl:when test="$primarylanguagecode = 'xal' ">Oirat</xsl:when>
            <xsl:when test="$primarylanguagecode = 'xho' ">Xhosa</xsl:when>
            <xsl:when test="$primarylanguagecode = 'yao' ">Yao (Africa)</xsl:when>
            <xsl:when test="$primarylanguagecode = 'yap' ">Yapese</xsl:when>
            <xsl:when test="$primarylanguagecode = 'yid' ">Yiddish</xsl:when>
            <xsl:when test="$primarylanguagecode = 'yor' ">Yoruba</xsl:when>
            <xsl:when test="$primarylanguagecode = 'ypk' ">Yupik languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'zap' ">Zapotec</xsl:when>
            <xsl:when test="$primarylanguagecode = 'zbl' ">Blissymbolics</xsl:when>
            <xsl:when test="$primarylanguagecode = 'zen' ">Zenaga</xsl:when>
            <xsl:when test="$primarylanguagecode = 'zha' ">Zhuang</xsl:when>
            <xsl:when test="$primarylanguagecode = 'znd' ">Zande languages</xsl:when>
            <xsl:when test="$primarylanguagecode = 'zul' ">Zulu</xsl:when>
            <xsl:when test="$primarylanguagecode = 'zun' ">Zuni</xsl:when>
            <xsl:when test="$primarylanguagecode = 'zxx' "></xsl:when>
            <xsl:when test="$primarylanguagecode = 'zza' ">Zaza</xsl:when>
            <xsl:when test="$primarylanguagecode = '' or not($primarylanguagecode)"></xsl:when>
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
               <language><xsl:value-of select="$primarylanguagecode"/></language>
                <abstract>This layer is a georeferenced raster image of the historic paper map entitled: <xsl:value-of select="$titleAandB"/>. It was published by: <xsl:value-of select="$publisher"/><xsl:value-of select="$pubdatestring"/>. <xsl:value-of select="$scale"/>. <xsl:if test="$language != ''"><xsl:value-of select="concat(' Map in ',$language,'.')"/></xsl:if> <xsl:if test="marc:datafield[@tag=041]/marc:subfield[@code='a'] != ''"><xsl:value-of select="concat(' ','Map in multiple languages.')"/></xsl:if>
                The image inside the map neatline is georeferenced to the surface of the earth and fit to the rProjection (EPSG: xxx_EPSG_xxx) coordinate system. All map features and collar and inset information are shown as part of the raster image, including any inset maps, profiles, statistical tables, directories, text, illustrations, index maps, legends, or other information associated with the principal map.                 
                
                This layer is part of a selection of digitally scanned and georeferenced historic maps from the Harvard Map Collection. These maps typically portray both natural and manmade features. The selection represents a range of geographies, originators, ground condition dates, scales, and map purposes.</abstract>
                <purpose>Historic paper maps can provide an excellent view of the changes that have occurred in the cultural and physical landscape.  The wide range of information provided on these maps make them useful in the study of historic geography, and urban and rural land use change.  As this map has been georeferenced, it can be used in a GIS as a source or background layer in conjunction with other GIS data.</purpose>
            </descript>
            
            
            <!-- ENHANCE - xsl:if for more date types -->
           
            <!-- GW new structure: Default to single date pattern if date2 is not well formed, regardless of datetype.-->
            <timeperd>
                <timeinfo>
                    <!-- Variable display fields for testing purposes -->
                    <date_type><xsl:value-of select="$datetype"/></date_type>
                    <date2_value><xsl:value-of select="$date2"/></date2_value>
                    <date2_unclear_test><xsl:value-of select="$date2_unclear"/></date2_unclear_test>
                    
                    <xsl:choose>
                        <xsl:when test="$date2_unclear = 'TRUE'">
                            <sngdate>
                                <caldate><xsl:value-of select="$date1"/></caldate>
                            </sngdate>
                        </xsl:when>
                        <xsl:when test = "$datetype = 'm' or $datetype = 'q' or $datetype = 'p' or $datetype = 'i' or $datetype = 'k' or $datetype = 'r' or $datetype = 't'">
                            <rngdates>
                                <begdate><xsl:value-of select="$date1"/></begdate>
                                <enddate><xsl:value-of select="$date2"/></enddate>
                            </rngdates>
                        </xsl:when>
                        <xsl:otherwise>
                            <sngdate>
                                <caldate><xsl:value-of select="$date1"/></caldate>
                            </sngdate>
                        </xsl:otherwise>
                    </xsl:choose>
                </timeinfo>
            </timeperd>
           <!-- End of GW new structure -->
            
            <!-- old date section
            <xsl:if test="$datetype = 's' or  $datetype = 'e' or ">
                <timeperd><datetypetag><xsl:value-of select="$datetype"/></datetypetag><date2unclear><xsl:value-of select="$date2_unclear"/></date2unclear>
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
            <xsl:if test="$datetype = 'm' or $datetype = 'q' and $date2_unclear = 'FALSE'">
                <timeperd><datetypetag><xsl:value-of select="$datetype"/></datetypetag><date2unclear><xsl:value-of select="$date2_unclear"/></date2unclear>
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
            End of old date section -->
            
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
