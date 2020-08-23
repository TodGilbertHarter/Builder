package Log;

use local::lib;
use strict;
use base qw(Step);
use IO::All;
use DateTime::Format::Strptime;

sub execute {
	my ($self) = @_;
	
	my $log = $self->builder()->getScalarProperty('log.file');

	my $buildname = $self->builder()->getScalarProperty('build.name');
	my $builddescription = $self->builder()->getScalarProperty('build.description');
	my $buildreport = "$buildname\n";
	my $formatter = DateTime::Format::Strptime->new('pattern' => '%Y-%m-%d %H:%M');
	my $dt = DateTime->now();
	my $dtstr = $formatter->format_datetime($dt);
	$buildreport .= "Build $dtstr\n";
	$buildreport .= "$builddescription\n";
	my @log = map { $_ =~ /.*DEBUG.*/ ? () : $_ } @{$self->builder()->getLog()};
	$buildreport .= join("",@log);
	$buildreport > io($log);
}

1;


__END__

=head1 NAME

Log - Dilettante output logger

=head1 DESCRIPTION

This module dumps the output of the builder log to a file. Normally it will only be appended to standard output, but using this step
you can save a copy in order to generate a report, etc.

=head2 CONFIGURATION

Several properties control execution.

=over 4

=item log.file

The file to write the output to.

=back

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
