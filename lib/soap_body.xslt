<?xml version="1.0"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <xsl:template match="/">
    <xsl:copy-of select="//soap:Body/*[1]"/>
  </xsl:template>
</xsl:transform>
