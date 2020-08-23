#! /usr/bin/perl

use strict;
use XML::LibXML;
use XML::LibXSLT;

my $parser = XML::LibXML->new();
my $doc = $parser->parse_file("classpath");
my $xslt = XML::LibXSLT->new();
my $sd = "eclipseclasspath.xslt";
my $style_doc = $parser->parse_file($sd);
my $stylesheet = $xslt->parse_stylesheet($style_doc);
my $results = $stylesheet->transform($doc);
print "GETTING RESULTS ARE: ".$stylesheet->output_string($results);

my $root = $doc->documentElement();
$root->appendChild($doc->createElement($_)) for qw(fee fie foe fum);

print "AFTER ADDING STUFF ".$doc->serialize();
