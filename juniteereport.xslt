<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

	<xsl:output method='text' indent='no' omit-xml-declaration='yes'/>
	<xsl:strip-space elements="*"/>

	<xsl:template match='/'>
		<xsl:apply-templates select='*'/>
		<xsl:text/>Summary: tests run <xsl:value-of select="sum(testsuite/@tests)"/>
		<xsl:text/> tests failed <xsl:value-of select="sum(testsuite/@failures)"/>
		<xsl:text/> errors <xsl:value-of select="sum(testsuite/@errors)"/>
		<xsl:text>&#xA;</xsl:text>
	</xsl:template>

	<xsl:template match='testcase'>
		<xsl:text/>Test case: <xsl:value-of select='@name'/> runtime <xsl:value-of select='@time'/><xsl:text>&#xA;</xsl:text>
		<xsl:apply-templates select='failures'/>
		<xsl:apply-templates select='successes'/>
		<xsl:apply-templates select='results'/>
		<xsl:text>---------------------------------------------------------&#xA;&#xA;</xsl:text>
	</xsl:template>

	<xsl:template match='failure'>
		<xsl:text/>Failures: <xsl:value-of select='@count'/><xsl:text>&#xA;</xsl:text>
		<xsl:apply-templates select='defect'/>
	</xsl:template>

	<xsl:template match='defects[@type="error"]'>
		<xsl:text/>Errors: <xsl:value-of select='@count'/><xsl:text>&#xA;</xsl:text>
		<xsl:apply-templates select='defect'/>
	</xsl:template>

	<xsl:template match='defect'>
		<xsl:apply-templates select='test'/>
		<xsl:text/>Trace: <xsl:value-of select='trace'/><xsl:text>&#xA;</xsl:text>
	</xsl:template>

	<xsl:template match='successes'>
		<xsl:text/>Successes: <xsl:value-of select='@count'/><xsl:text>&#xA;</xsl:text>
		<xsl:apply-templates select='test'/>
	</xsl:template>

	<xsl:template match='test'>
		<xsl:text/>Test: <xsl:value-of select='.'/><xsl:text>&#xA;</xsl:text>
	</xsl:template>

	<xsl:template match='results'>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match='failures'>
		<xsl:text/>Some Tests Failed: total <xsl:value-of select='runcount'/> failures <xsl:value-of select='failcount'/> errors <xsl:value-of select='errorcount'/><xsl:text>&#xA;</xsl:text>
	</xsl:template>

	<xsl:template match='success'>
		<xsl:text/>All Tests Succeeded: total <xsl:value-of select='runcount'/><xsl:text>&#xA;</xsl:text>
	</xsl:template>

</xsl:stylesheet>