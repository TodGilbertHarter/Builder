<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

	<xsl:output method='text' indent='no' omit-xml-declaration='yes'/>
	<xsl:strip-space elements="*"/>

	<xsl:template match='/'>
		<xsl:apply-templates select='project/dependencyManagement/dependencies'/>
	</xsl:template>

	<xsl:template match='dependency'>
		<xsl:variable name='type'>
			<xsl:choose>
				<xsl:when test='type'><xsl:value-of select='type'/></xsl:when>
				<xsl:otherwise>jar</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name='scope'>
			<xsl:choose>
				<xsl:when test='scope'><xsl:value-of select='scope'/></xsl:when>
				<xsl:otherwise>compile</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:text/>build.dependency=<xsl:value-of select='groupId'/>:<xsl:value-of select='artifactId'/>:<xsl:value-of select='version'/>:<xsl:value-of select='$type'/>:<xsl:value-of select='$scope'/><xsl:text>&#xA;</xsl:text>
	</xsl:template>

</xsl:stylesheet>