<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <xsl:template name = "MARC_language_codes">
        <xsl:choose>
            <!-- set language text -->
            <xsl:when test="'fre' "><xsl:value-of select = "French"/></xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>