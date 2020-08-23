package Jacoco;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $jacocoloc = $self->builder()->getScalarProperty("jacoco.bin");
	my $repdir = $self->builder()->getScalarProperty("$step.jacoco.reports");
	my $jacocodata = $self->builder()->getScalarProperty("$step.jacoco.datafile");
	my $source = $self->builder()->getScalarProperty("build.source");
#	my $title = "'".$self->builder()->getScalarProperty("build.name")." Coverage Report'";
	my $title = "Coverage";
	my $classes = $self->builder()->getScalarProperty("build.target.testclasses");
	io($repdir)->mkpath();

	$self->debug("$jacocoloc/jacoco-report.sh $jacocodata $repdir $source $title $classes");
	$self->error("Jacoco failed to generate report") if
		system("$jacocoloc/jacoco-report.sh",$jacocodata,$repdir,$source,$title,$classes);
	$self->info("Report generated");
}

1;


__END__

=head1 NAME

Jacoco - Dilettante Jacoco report generation module

=head1 DESCRIPTION

This module provides a default action which generates a report from a Jacoco test run file.

=head2 REPORT CONFIGURATION

Several properties control the instrumentation 

=over 4

=item jacoco.bin

Location of your Jacoco installation.

=item jacocoreport.jacoco.reports

Output directory for coverage reports. This is normally target/jacoco-reports

=item jacocoreport.jacoco.datafile

Name of the jacoco data file to generate report from

=item build.source

Source file directory.

=item build.target.testclasses

Binary class files to be reported on.

=back

=head1 USE

Note that this module only generates reports, it doesn't perform the coverage analysis. Because Jacoco uses a java agent to do the instrumentation and data capture
on the fly all that is required is to set the test.extras property as follows:

test.extras=-javaagent:/mnt/deltaopt/development/brepository/org/jacoco/agent/0.7.2.201409121644/agent-0.7.2.201409121644.jar=destfile=${build.target}/jacoco.exec

and jacoco will automagically do the rest. 

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
