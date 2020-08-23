<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

	<xsl:output method='text' indent='no'/>

	<xsl:template match='/'>
		<xsl:apply-templates select='*/classpathentry[@kind = "lib"]'/>
	</xsl:template>

	<xsl:template match="classpathentry"><xsl:value-of select="@path"/>:</xsl:template>

</xsl:stylesheet>