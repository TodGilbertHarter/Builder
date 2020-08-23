#! /usr/bin/perl

use strict;
use lib "/mnt/deltaopt/development/builder";
use Builder;
use Maven;
use IO::All;
use Archive::Zip qw(:ERROR_CODES);

my $builder = Builder->new();
$builder->init();
my $maven = Maven->new('builder' => $builder);
my @poms = grep(/.*\.pom$/,io('.')->all(0));
foreach my $pom (@poms) {
	$pom =~ /(.*)\.pom$/;
	my $basename = $1;
	my $fname = '';
	if(-f "$basename.jar") {
		$fname = "$basename.jar";
	} elsif(-f "$basename.war") {
		$fname = "$basename.war";
	} elsif(-f "$basename.ear") {
		$fname = "$basename.ear";
	}
	if($fname ne '') {
		my $zip = Archive::Zip->new();
		if($zip->read($fname) == AZ_OK) {
			my @members = $zip->membersMatching('pom.xml$');
			my $zippom = pop(@members);
			if($zippom ne '') {
				my $contents = $zippom->contents();
				my $deps = $maven->scanPomString($contents);
				my $out = io("$basename.dependencies");
				$builder->{'step'} = 'reposcan';
				$builder->info("Created $basename.dependencies");
				pop(@$deps)."\n" > $out;
				"$_\n" >> $out for @$deps;
				$out->close();
			}
		}
	}
}

__END__

=head1 NAME

reposcan.pl - Dilettante Maven repository scanner

=head1 SYNOPSIS

./reposcan.pl

=head1 DESCRIPTION

Scan maven repository, extract the POM from each artifact, and build a .dependencies file containing the resolved list of
dependencies for each one.

=head1 AUTHOR

Tod G. Harter

=head1 LICENSE

This software is Copyright (C) 2016 TD Software Inc. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
