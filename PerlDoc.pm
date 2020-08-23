package PerlDoc;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $source = $self->builder()->getScalarProperty("perldoc.$step.source");
	my $target = $self->builder()->getScalarProperty("perldoc.$step.target");
	io($target)->mkpath();
#	my @sources = io($source)->all(0);
#	@sources = grep(/.*\.p[ml]/,@sources);
	$self->info("Generating perl docs");
	$self->debug("for $source into $target");
	$self->error("PerlDoc failed") if system('mpod2html','-dir',$target,$source);
}

1;


__END__

=head1 NAME

PerlDoc - Dilettante generate HTML version of POD from perl modules and scripts

=head1 DESCRIPTION

Generates a set of HTML pages from perl source files and puts them in a directory.

=head2 CONFIGURATION

=over 4

=item perldoc.<step>.source

The source directory where the perl source is.

=item perldoc.<step>.target

Directory where the output HTML goes.

=back

=head1 USE

This uses the CPAN mpod2html module to construct the documentation. Everything will be fully crosslinked and generally the results are pretty
good. Currently no extra options are supported or anything like that. This should be sufficient if you just want to document a set of
.pm and .pl files which are all in one place.

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
