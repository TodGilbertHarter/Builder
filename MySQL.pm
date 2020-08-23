package MySQL;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $db = $self->builder()->getScalarProperty("mysql.$step.database");
	my $user = $self->builder()->getScalarProperty("mysql.$step.user");
	my $pass = $self->builder()->getScalarProperty("mysql.$step.password");
	my $cmdfile = $self->builder()->getProperty("mysql.$step.commandfile");
	my $host = eval { $self->getScalarProperty("mysql.$step.host"); };
	my $port = eval { $self->getScalarProperty("mysql.$step.port"); };
	my $cmdline = "mysql -u $user";
	if(defined($host)) {
		$cmdline .= " -h $host";
	}
	if(defined($port)) {
		$cmdline .= " -P $port";
	}
	$cmdline .= " --password=$pass $db <$cmdfile";
	$self->debug($cmdline);
	$self->error("Failed to execute command file $cmdfile") if
		system($cmdline);
}

1;


__END__

=head1 NAME

MySQL - Dilettante MySQL management module

=head1 DESCRIPTION

MySQL provides functions to execute a MySQL SQL command file and perform a dump of an existing 
MySQL database to a command file.

=head2 CONFIGURATION

=head1 USE

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
