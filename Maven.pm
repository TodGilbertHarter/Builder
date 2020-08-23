package Maven;

use strict;
use base qw(Step);
use IO::All;
use XML::LibXML;
use XML::LibXSLT;

sub execute {
	my ($self) = @_;

	my $mdeps = $self->_getPOMDeps($self->builder()->getScalarProperty('maven.pom'));
	for my $dep (@$mdeps) {
		$self->builder()->addProperty('build.dependency');
	}
}

sub add {
	my ($self) = @_;
	
	my $mdeps = $self->_getPOMDeps($self->builder()->getScalarProperty('maven.pom'));
	my $pf = $self->genPath($self->builder()->getScalarProperty('builder.config.module'));
	my $io = io($pf);
	"" > $io unless -f $io; # create if it doesn't exist
	foreach my $mdep (@$mdeps) {
		"$mdep\n" >> $io;
	}
}

sub addString {
	my ($self,$pomstr) = @_;
	
	my $mdeps = $self->scanPomString($pomstr);
	my $pf = $self->genPath($self->builder()->getScalarProperty('builder.config.module'));
	my $io = io($pf);
	foreach my $mdep (@$mdeps) {
		"$mdep\n" >> $io;
	}
}

sub scanPomString {
	my ($self,$pomstring) = @_;

	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_string($pomstring);
	my $xslt = XML::LibXSLT->new();
	my $xsltfile = $self->genPath($self->builder()->getScalarProperty('maven.xslt'));
	my $instyle_doc = $parser->parse_file($xsltfile);
	my $instylesheet = $xslt->parse_stylesheet($instyle_doc);
	my $rdoc = $instylesheet->transform($doc);
	my $results = $instylesheet->output_string($rdoc);
	my @mdeps = split("\n",$results);
	$self->debug("POM provided dependencies\n$results");
	return \@mdeps;
}

sub _getPOMDeps {
	my ($self,$pomfile) = @_;

	my $pomstr = io($pomfile)->slurp();
	return $self->scanPomString($pomstr);

#	my $parser = XML::LibXML->new();
#	my $doc = $parser->parse_file($pomfile);
#	my $xslt = XML::LibXSLT->new();
#	my $instyle_doc = $parser->parse_file($self->builder()->getProperty('builder.lib')."/pomdeps.xslt");
#	my $instylesheet = $xslt->parse_stylesheet($instyle_doc);
#	my $rdoc = $instylesheet->transform($doc);
#	my $results = $instylesheet->output_string($rdoc);
#	my @mdeps = split("\n",$results);
#	$self->debug("POM provided dependencies\n$results");
#	return \@mdeps;
}

1;

__END__

=head1 NAME

Maven - Dilettante Maven integration module

=head1 DESCRIPTION

This module extracts depdendencies from a Maven POM and builds a corresponding set of Dilettante dependency property entries from
the dependencies section of the POM. It does not traverse parent POMs, nor does it pay any attention to dependencyManagement, so
the results will generally need to be edited somewhat to be useful. The resulting dependencies are inserted into the builder
build.dependency property.

The add() action additionally inserts the new dependencies into the project's build.properties file.

The pom to be scanned is specified via the 'maven.pom' property.

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
