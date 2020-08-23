package GitSCM;

use Git;
use strict;
use base qw(Step);

sub branch {
	my ($self) = @_;
	
	my $revprop = $self->getScalarProperty("productversion");
	my $repo = Git->repository()
	
	
	my $step = $self->getStep();
	my $revprop = $self->getScalarProperty("scm.$step.property");
	$self->debug("assigning revision number to $revprop");
	
	#TODO: assign the property
}

1;

__END__

=head1 NAME

GitSCM - Dilettante GIT SCM interface module 

=head1 DESCRIPTION

GitSCM provides an abstraction for generic source/version control functionality required by the build system.

=head2 CONFIGURATION

Assigning the build.buildnumber property to the current working copy revision number might look like this:

	step.getbuildnumber=SCM:getRevision
	scm.getbuildnumber.property=build.buildnumber

=over 4

=item scm.$step.property

Property to assign the current revision number of the working copy to via the getRevision function.

=back

=head2 FUNCTIONS

=over 4

=item getRevision

This function assigns the current revision number of the working copy in which the project is being built. This would be the directory
pointed to by the build, which defaults to the current working directory where builder is being executed. The name of the target property
is supplied by the 'scm.$step.property' property. Note that a step bound to this function should probably be executed early in the build
in order to insure that this value is set properly during subsequent operations.

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
