package Eval;

use strict;
use base qw(Step);
use Cwd;

sub execute {
	my ($self) = @_;

	my $step = $self->getStep();
	my $code = $self->getScalarProperty("eval.$step.code");
	$self->debug("Eval executing perl code $code");
	eval $code;
	$self->error("Eval failed with $@") if $@;
}

1;

__END__

=head1 NAME

Eval - Dilettante execute arbitrary perl statement

=head1 DESCRIPTION

Eval simply evaluates a perl expression.

=head2 CONFIGURATION

=over 4

=item eval.$step.code

The expression to evaluate.

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
