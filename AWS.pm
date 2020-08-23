package AWS;

use strict;
use base qw(Step);
use IO::All;
#use Paws;

sub execute {
	my ($self) = @_;

	my $step = $self->getStep();
	my $cdir = $self->builder()->getScalarProperty('build.target.classes');
	my $bndcmd = $self->getScalarProperty('bnd.command');
	my $target = $self->getScalarProperty("bnd.$step.target");
	my $bndfile = $self->getScalarProperty("bnd.$step.bndfile");
	$self->_execute($bndcmd,$cdir,$target,$bndfile);
}

sub _getStandardArgs {
	my ($self) = @_;
	
#	my $
}

1;


__END__

=head1 NAME

AWS - Dilletante AWS command support

=head1 DESCRIPTION

AWS.pm allows Builder to invoke web service functions of the AWS APIs. Each individual API command has its own specific function
and configuration arguments. The default command simply validates the provided credentials.

=head2 CONFIGURATION

All commands share functionality to provide credentials. This happens via two main methods, either attributes point to key files, or the
module assumes that it is running on an AWS instance with an IAM role appropriate to whatever function is being performed. This would probably
be appropriate to a group/department build server.

=over 4

=item aws.$step.accesskey

This is the path to the access key file in your environment. It SHOULD always be set via a user's local config (IE avoid including keys
in repos and other such badness).

=item aws.$step.secretkey

This is the path to the secret key file in your environment. It SHOULD always be set via a user's local config (IE avoid including keys
in repos and other such badness).


=item aws.$step.region

if set this is the region any region-specific commands will be executed in. Note that most region-specific commands will default to us-east-1
if this isn't set, but some may fail, etc.

=back

=head2 ACCESS CHECK

This has no addtional parameters. It will simply make a no-op call to one of the AWS services to verify that builder is able to access the
AWS web services and is configured with a valid set of credentials (for at least some routine task).

=head1 USE

Executing calls to AWS APIs is straightforward. Each function encapsulates one or more such calls and carries out some useful logical
build-related function. For instance in a build.properties:

step.checkaws=AWS
build.steps=checkaws
aws.checkaws.accesskey=~/.aws/accesskey
aws.checkaws.secretkey=~/.aws/secretkey
aws.checkaws.region=usa-east-1

will perform a basic connectivity check to USA-EAST-1 using the given key and secret files.

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
