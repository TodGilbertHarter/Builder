#! /usr/bin/perl

use strict;
use Properties;
use Data::Dumper;

my $p = Properties->new('name' => '');
$p->addProperty('builder.home' => '/foofoo');
$p->readProps('testin.properties');
#print "DONE READING PROPERTIES\n";
#print Dumper($p);
#print($p->dump());
#print "DONE DUMPING PROPERTIES\n";
$p->writeProps('test.properties');

print "GETTING step.test ".$p->getProperty('step.test')."\n";