package Dependency;

use strict;

sub new {
	my ($caller, %arg) = @_;
	my $class = ref($caller) || $caller;
	my $self = bless({},$class);
	foreach my $key (keys(%arg)) {
		if(exists $arg{$key}) {
			$self->{$key} = $arg{$key};
		}
	}
	return $self;
}

sub getSubDeps {
	return shift->{'subdeps'};
}

sub setSubDeps {
	my ($self,$value) = @_;
	$self->{'subdeps'} = $value;
}

sub getRepo {
	return shift->{'repo'};
}

sub setRepo {
	my ($self,$value) = @_;
	$self->{'repo'} = $value;
}

sub getPath {
	return shift->{'path'};
}

sub setPath {
	my ($self,$value) = @_;
	$self->{'path'} = $value;
}

sub getArtifactid {
	return shift->{'artifactid'};
}

sub setArtifactid {
	my ($self,$value) = @_;
	$self->{'artifactid'} = $value;
}

sub getScope {
	return shift->{'scope'};
}

sub setScope {
	my ($self,$value) = @_;
	$self->{'scope'} = $value;
}

sub setPackaging {
	my ($self,$value) = @_;
	$self->{'packaging'} = $value;
}

sub getPackaging {
	return shift->{'packaging'};
}

sub setGroupid {
	my ($self,$value) = @_;
	$self->{'groupid'} = $value;
}

sub getGroupid {
	return shift->{'groupid'};
}

sub setVersion {
	my ($self,$value) = @_;
	$self->{'version'} = $value;
}

sub getVersion {
	return shift->{'version'};
}

sub toString {
	my ($self) = @_;

	return $self->getGroupid().":".$self->getArtifactid().":"
		.$self->getVersion().":".$self->getPackaging().":".$self->getScope();
}

1;

__END__


=head1 NAME

Dependency - Object which represents all information pertaining to a dependency.

=head1 DESCRIPTION

This object simply holds data related to a dependency. It is used by the Dependencies module to maintain a coherent list of the
dependencies of a project during dependency resolution. Other modules may also utilize this code for similar purposes.

=head1 FUNCTIONS

Dependency has several functions for getting and setting attributes.

=over 4

=item new()
Construct a new dependency object. Key/value pairs may be supplied to the constructor to preassign attributes. 
(IE Dependency->new('version' => '1.0.0') results in a new Dependency object with its version attribute set to '1.0.0'.

=item getVersion()/setVersion()
Get/set the dependency version number.

=item getGroupid()/setGroupid()
Get/set the dependency group id.

=item getPackaging()/setPackaging()
Get/set the dependency packaging type. As with scopes, packagings have some conventional meanings but there are no hard
and fast requirements, altho some action modules may be unable to operate on arbitrary packagings (IE the Assemble module
won't be able to deal with 'exploding' a dependency of a packaging type it can't understand).

=item getArtifactid()/setArtifactid()
Get/set the dependency artifact identifier.

=item getScope()/setScope()
Get/set the dependency useage scope. Note that some scopes (compile,test and provided) have specific conventional meanings
to other builder components. However any arbitrary scope CAN be defined and this is sometimes useful when you want to
manage some other type of environmental dependency, such as a test fixture installer which can be related to an artifact
of some kind.

=item toString()
Returns a string representation of the dependency in the same format used in a dependency property in a build file (IE
groupid:artifactid:version:packaging:scope).

=item getRepo()/setRepo()
Get/set the path to the repository base path the artifact corresponding to this dependency has been resolved to, if any.

=item getPath()/setPath()
Get/set the full file system path to the artifact which resolves this dependency.

=item getSubDeps()/setSubDeps()
Get/set subdependencies of this dependency. Subdependencies consist of a hash who's keys are the scopes of the sub
depdencies and who's values are Dependency objects describing each dependency. This way a Dependency object can describe
transitive dependency information to any depth and level of complexity.

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
