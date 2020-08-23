package Delay;

use strict;
use base qw(Step);

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $delay = $self->getScalarProperty("delay.$step.delay");
	$self->info("Delaying $delay seconds");
	sleep($delay);
	$self->debug("Delayed $delay seconds");
}

1;


__END__

=head1 NAME

Delay - step to introduce a pause.

=head1 DESCRIPTION

Provides a single default option which delays processing by a given number of seconds. This can be 
useful in some cases where it isn't possible to determine when some external process has completed, etc.

=head2 CONFIGURATION

There is only one attribute, which controls the length of the delay in seconds.

=over 4

=item delay.$step.delay

This is the number of seconds to delay.

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
