package Axis2;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;
	foreach my $wsdl ($self->axiswsdl()) {
		my $command = $self->axisbin()."WSDL2java";
		my @args = ['-uri',$wsdl,'-d','adb','-s'];
		my $args = join(' ',('-uri',$wsdl,'-p',$self->axisnamespace(),'-o',$self->axisoutputdir(),'-d','adb','-s'));
		$self->info("$command $args");
		my $error = '';
		$error = 'Failed to Run WSDL2Java.' if system("$command $args");
		$self->error($error) if $error ne '';
	}
}

sub axiswsdl {
	my ($self) = @_;

	my $wsdl = $self->builder->getScalarProperty('axis2.wsdl.dir');
	my @wsdl = io($wsdl)->all();
	my @wsdl2 = grep { $_ !~ "svn" } (@wsdl);
	return @wsdl2;
}

sub axisoutputdir {
	my ($self) = @_;
	return $self->builder->getScalarProperty('axis2.outputdir');
}

sub axisnamespace {
	my ($self) = @_;
	return $self->builder->getScalarProperty('axis2.namespace');
}

sub axisbin {
	my ($self) = @_;
	return $self->builder->getScalarProperty('axis2.bin');
}

sub axisdir {
	my ($self) = @_;
	my $axis = $self->builder->getScalarProperty('axis2.lib');
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

Axis2 - Dilletante Axis2 command support

=head1 DESCRIPTION

Provides actions used to invoke the various Axis2 command tools, specifically WSDL2Java.

=head2 CONFIGURATION

There are several attributes used to configure aspects of Java code generation.

=over 4

=item axis2.wsdl.dir

This is the path to the directory containing WSDL files to be used for code generation.

=item axis2.outputdir

This is the path to the output directory where generated java source files will be placed.

=item axis2.namespace

This is the namespace used to generate the package names for the generated code.

=item axis2.lib

This is the path to the directory containing axis jars.

=item axis2.bin

This is the path to the directory containing axis binaries.

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
