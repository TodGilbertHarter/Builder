package ActiveMQ;

use strict;
use base qw(Step);
use DBI;
use IO::All;
use Cwd;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $mqdir = $self->builder()->getScalarProperty("activemq.$step.dir");
	my $javahome = $self->builder()->getScalarProperty("build.javahome");
	$ENV{ACTIVEMQ_HOME} = $mqdir;
	$ENV{JAVA_HOME} = $javahome;
	$self->info("Trying $ENV{ACTIVEMQ_HOME} for launch");
	eval {
		my $dsn = "DBI:mysql:database=activemq;host=localhost";
		my $dbh = DBI::Connect($dsn,"activemq","activemq", {PrintError => 1});
		$dbh->do("DROP TABLE ACTIVEMQ_ACKS");
		$dbh->do("DROP TABLE ACTIVEMQ_MSGS");
		$dbh->do("DROP TABLE ACTIVEMQ_LOCK");
	};

	unlink("$mqdir/activemq-data");
	chmod 0755, "$mqdir/bin/activemq", "$mqdir/bin/activemqservice";
	$self->error("Failed to start activemq ")
#	if system("/bin/bash","$mqdir/bin/activemq","start");
		if system("/bin/bash","$mqdir/bin/activemqservice","start");
	$self->info("ActiveMQ started from $mqdir");
	$self->registerCleanupStep('stopamq');
	sleep(30); # give activeMQ a bit of time to stabilize. else it may get annoyed...
}

sub deploy {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $mqarchive = $self->builder()->getScalarProperty("activemq.$step.source");
	my $mqtarget = $self->builder()->getScalarProperty("activemq.$step.target");

	$self->debug("Exploding activemq at $mqarchive to $mqtarget");
	io("$mqtarget")->mkdir();
	system('tar','zxf',$mqarchive,'-C',$mqtarget,'--strip-components=1');
	$self->info("deployed activemq to $mqtarget");
	chmod 0755, "$mqtarget/bin/activemq", "$mqtarget/bin/activemqservice";
}

sub stop {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $mqdir = $self->builder()->getScalarProperty("activemq.$step.dir");
	my $javahome = $self->builder()->getScalarProperty("build.javahome");
	$ENV{ACTIVEMQ_HOME} = $mqdir;
	$ENV{JAVA_HOME} = $javahome;
	$self->error("Failed to stop activemq")
#		if system("/bin/bash","$mqdir/bin/linux/activemq","stop");
		if system("/bin/bash","$mqdir/bin/activemqservice","stop");
	$self->info("ActiveMQ stopped in $mqdir");
}

1;


__END__

=head1 NAME

ActiveMQ - Dilettante activeMQ deployer action module

=head1 DESCRIPTION

ActiveMQ provides 3 actions. The default action starts an activeMQ message broker. The stop action shuts down an
activeMQ broker. The deploy action unpacks a tarball (tgz) archive containing a deployable activeMQ broker install.

=head2 CONFIGURATION

=over 4

=item activemq.$step.dir

The default and stop actions use this property to find the base directory for the activemq server.

=item activemq.$step.source

The deploy action uses this property to locate a tarballed activemq.

=item activemq.$step.target

The deploy action untars the activemq archive into this directory.

=back

=head1 USE

The actions provided in this module are useful for deploying, starting, and stopping an activemq message broker, usually as part of a test sequence.

=head2 STARTING

The default action will start a message broker, thus supplying a step.startamq=ActiveMQ (which is in the default config.properties file) along with activemq.startamq.dir=some/directory/path will start the broker and register stop as a cleanup action. It will also delete any existing activemq-data directory in the specified location
and attempt to flush MySQL tables on localhost using user "activemq" password "activemq" and table "activemq". if possible. This is to ensure that the server
starts in a known stable configuration. It might be a good idea to add ways to configure these at some point.

=head2 DEPLOYING

This step will deploy a tarballed activemq server. Generally the build environment will get the tarball as an artifact from the repository via Assemble:copyDeps.

=head2 STOPPING

Generally this is a cleanup step, it can be called explicitly if desired.

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
