package CXF;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;
	foreach my $wsdl ($self->cxfwsdl()) {
		my $command = $self->cxfbin()."wsdl2java";
#		my @args = ['-verbose','-client','-d',$self->cxfoutputdir(),$wsdl];
		my $wsdlloc = $self->wsdlloc();
		my $args = join(' ',('-verbose',"-wsdlLocation $wsdlloc",'-d',$self->cxfoutputdir(),$wsdl));
		$self->info("$command $args");
		my $error = '';
		$error = 'Failed to Run wsdl2Java.' if system("$command $args");
		$self->error($error) if $error ne '';
	}
}

sub wsdlloc {
	my ($self) = @_;

	my $wsdl = $self->builder->getScalarProperty('cxf.wsdl.location');
#	$self->error("WHAT THE FUCK IS IT '$wsdl'\n"); exit(-1);
	return $wsdl;
}

sub cxfwsdl {
	my ($self) = @_;

	my $wsdl = $self->builder->getScalarProperty('cxf.wsdl.dir');
	my @wsdl = io($wsdl)->all();
	my @wsdl2 = grep { $_ !~ "svn" } (@wsdl);
	return @wsdl2;
}

sub cxfoutputdir {
	my ($self) = @_;
	return $self->builder->getScalarProperty('cxf.outputdir');
}

sub cxfnamespace {
	my ($self) = @_;
	return $self->builder->getScalarProperty('cxf.namespace');
}

sub cxfbin {
	my ($self) = @_;
	return $self->builder->getScalarProperty('cxf.bin');
}

sub cxfdir {
	my ($self) = @_;
	my $axis = $self->builder->getScalarProperty('cxf.lib');
	my @allfiles = grep /.*\.jar$/, io($axis)->all();
	return join(":", @allfiles);
}

sub addlibdir {
	my ($self) = @_;
	return $self->builder->genClassPath(0);
}
1;

__END__

=head1 NAME

CXF - Dilletante CXF command support

=head1 DESCRIPTION

Provides actions used to invoke the various CXF command tools, specifically WSDL2Java. This is
virtually a drop-in replacement for the Axis2 module, it simply substitutes the Apache CXF versions
of things for the Axis2 ones. The generated client stubs SHOULD be functionally identical, give or take.

=head2 CONFIGURATION

There are several attributes used to configure aspects of Java code generation.

=over 4

=item cxf.wsdl.dir

This is the path to the directory containing WSDL files to be used for code generation.

=item cxf.outputdir

This is the path to the output directory where generated java source files will be placed.

=item cxf.namespace

This is the namespace used to generate the package names for the generated code.

=item cxf.lib

This is the path to the directory containing cxf jars.

=item cxf.bin

This is the path to the directory containing cxf binaries.

=back

=head1 USE

Call CXF to generate code from a WSDL file.

step.cxf=CXF
build.steps=cxf
cxf.wsdl.dir=${basedir}/WSDL
cxf.outputdir=${target}/webservice
cxf.namespace=com.yournamespace.webservice
cxf.lib=/server/cxf/lib

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
