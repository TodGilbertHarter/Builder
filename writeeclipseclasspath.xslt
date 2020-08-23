<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
	xmlns:tsi="urn:com.tradedesksoftware.builder.eclipse"
	>

	<xsl:output method='text' indent='no'/>

	<xsl:template match='/'>
		<classpath>
			<xsl:apply-templates/>
		</classpath>
	</xsl:template>

</xsl:stylesheet>
