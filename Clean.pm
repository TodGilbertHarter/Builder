package Clean;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $target = $self->genPath($self->builder()->getScalarProperty('build.target'));
	$self->builder()->info("Cleaning $target");
	my $io = IO::All->new()->dir($target);
	$io->rmtree() unless $target eq '';
	$io->mkdir();
}

1;


__END__

=head1 NAME

Clean - Dilettante target cleaning module

=head1 DESCRIPTION

This just wipes out the entire directory and everything under it specified by the build.target property. In a standard
configuration this should get rid of all files produced by a build.

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
