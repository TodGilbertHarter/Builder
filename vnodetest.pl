#! /usr/bin/perl

use strict;
use Data::Dumper;
use ValueNode;

my $vnode = ValueNode->new('name' => 'top');
$vnode->addValue('foob');
$vnode->addValue('boob');
$vnode->getValue();
my $bnode = ValueNode->new('name' => 'bottom');
$bnode->addValue('quixotic');
$vnode->addChild($bnode);
$vnode->addChild(ValueNode->new('name' => 'superbottom'));
print Dumper($vnode);

print "CHILD IS ".$vnode->getChild('bottom')->getName();

$vnode->removeChild('bottom');

$vnode->replaceValue('torpedo');

print Dumper($vnode);
