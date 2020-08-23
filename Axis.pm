package Axis;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;
	foreach my $wsdl ($self->axiswsdl()) {
		my $java = $self->getScalarProperty('build.java') . ' -cp';
		my @wsdl2java = ($java, $self->axisdir(),'org.apache.axis.wsdl.WSDL2Java -o', $self->axisoutputdir(), '-d Application -s -S false -a --typeMappingVersion','1.2', $wsdl);
		$java =	join(" ", @wsdl2java);
		$self->info($java);
		$self->error('Failed to Run WSDL2Java.') if system $java;
	}
}

sub axiswsdl {
	my ($self) = @_;

	my $wsdl = $self->builder->getScalarProperty('axis.wsdl.dir');
	my @wsdl = io($wsdl)->all();
	my @wsdl2 = grep { $_ !~ "svn" } (@wsdl);
	return @wsdl2;
}

sub axisoutputdir {
	my ($self) = @_;
	return $self->builder->getScalarProperty('axis.outputdir');
}

sub axisnamespace {
	my ($self) = @_;
	return $self->builder->getScalarProperty('axis.namespace');
}

sub axisdir {
	my ($self) = @_;
	my $axis = $self->builder->getScalarProperty('axis.lib');
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

Axis - Dilletante Axis command support

=head1 DESCRIPTION

Provides actions used to invoke the various Axis command tools, specifically WSDL2Java.

=head2 CONFIGURATION

There are several attributes used to configure aspects of Java code generation.

=over 4

=item axis.wsdl.dir

This is the path to the directory containing WSDL files to be used for code generation.

=item axis.outputdir

This is the path to the output directory where generated java source files will be placed.

=item axis.namespace

This is the namespace used to generate the package names for the generated code.

=item axis.lib

This is the path to the directory containing axis jars.

=back

=head1 USE

Call Axis to generate code from a WSDL file.

step.axis=Axis
build.steps=axis
axis.wsdl.dir=${basedir}/WSDL
axis.outputdir=${target}/webservice
axis.namespace=com.yournamespace.webservice
axis.lib=/server/axis/lib

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
