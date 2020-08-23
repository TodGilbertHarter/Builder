package JBossEAP;

use base qw(Step);
use strict;
use LWP;
use LWP::UserAgent;
use HTTP::Request;
use IO::All;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $jbossdir = $self->builder()->getScalarProperty("jbosseap.$step.jbossdir");
	my $config = $self->builder()->getScalarProperty("jbosseap.$step.config");
	my $error = undef;
	
	$ENV{JBOSS_HOME}="$jbossdir";
	$ENV{JBOSSSH}="$jbossdir/bin/$config.sh";
	chmod 0755, "$jbossdir/bin/$config.sh";

	my $pid = fork;
	if(!(defined $pid)) {
		$error = "Failed to fork child process $? $!";
	} else {
		if($pid == 0) {
			$self->error("Failed to start jboss EAP from $jbossdir") if
				exec("/bin/bash","$jbossdir/bin/$config.sh");
			# if we get here, there WAS an error...
			print(STDERR "Child failed to exec $!\n");
			exit(-1);
		} else {
			$self->info("Jboss EAP server started at $jbossdir");
			$self->setProperty("jbosseap.$step.pid",$pid);
			$self->registerCleanupStep("stopeap");
		}
	}
	$self->error($error) if($error);
	
}


sub deploy {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $deployables = $self->builder()->getProperty("jbosseap.$step.deployable");
	$deployables = ref($deployables) ? $deployables : [$deployables];

	foreach my $deployable (@$deployables) {
#		my $deployable = $self->builder()->getProperty("jboss.$step.deployable");
		my $depfile = $self->fileFromPath($deployable);
		my $deployto = $self->builder()->getScalarProperty("jbosseap.$step.deployto");
	
		io($deployto)->mkpath();
		io($deployable) > io("$deployto/$depfile")
			|| $self->error("Failed to copy deployable $deployable to $deployto/$depfile");
		$self->info("$deployable deployed to $deployto/$depfile");
	}
}

sub undeploy {
	my ($self) = @_;
#	my ($self,$deployable) = @_;

	my $step = $self->builder()->getStep();
	my $deployable = $self->builder()->getProperty("jbosseap.$step.deployable");
	my $deployto = $self->builder()->getScalarProperty("jbosseap.$step.deployto");

	unlink("$deployto/$deployable")
		|| $self->error("Deployer failed to undeploy $deployable from $deployto");
	$self->info("$deployable undeployed");
}

sub stop {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $jbossdir = $self->builder()->getScalarProperty("jbosseap.$step.jbossdir");
	my $config = $self->builder()->getScalarProperty("jbosseap.$step.config");

	$ENV{JBOSS_HOME}="$jbossdir";
	$ENV{JBOSSSH}="$jbossdir/bin/$config.sh";
	$self->error("Failed to stop jboss from $jbossdir") if
		system("/bin/bash","$jbossdir/bin/$config.sh","stop");
}

sub waitforstart {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $timeout = $self->builder()->getScalarProperty("jbosseap.$step.timeout");

	my $t = $timeout;
	my $ua = LWP::UserAgent->new();
	my $req = HTTP::Request->new('GET' => "http://localhost:9990/");
	while($timeout > 0) {
		my $response = $ua->request($req);
		if($response->is_success())
		{
			$self->info("Jboss has started");
			return;
		}
		$timeout = $timeout - 1;
		sleep(1);
	}
	$self->error("JBoss failed to start within given timeout period ($t)");
}

sub waitfordeploy {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $timeout = $self->builder()->getScalarProperty("jbosseap.$step.timeout");
	my $string = $self->builder()->getScalarProperty("jbosseap.$step.appid");
	my $username = eval {$self->getScalarProperty("jbosseap.$step.username") };
	my $passwd = eval {$self->getScalarProperty("jbosseap.$step.password") };

	my $t = $timeout;
	
	my $args = "--connect --command=/deployment=$string:read-resource";
	my $command = $self->builder()->getScalarProperty("jbosseap.cli");
	$self->debug("Waiting for deployment with $command $args");
	
	while($timeout > 0) {
		my $response = system("$command $args");
		if(!$response) {
			return;
		}
		$timeout = $timeout - 1;
		sleep(1);
		$self->debug("Trying again with $command $args");
	}
	die("Failed to deploy within given timeout period ($t)\n");
}
1;


__END__

=head1 NAME

JBossEAP - Dilettante JBoss EAP management actions module

=head1 DESCRIPTION

Provides actions which will start up a JBoss EAP instance, deploy artifacts to it, wait for the server to start, wait for deployment, and stop the
server at the end of the build.

=head1 CONFIGURATION

=over 4

=item jbosseap.$step.jbossdir

Defines where the jboss top level directory is.

=item jbosseap.$step.config

Defines which JBoss configuration to use (ie, standalone, etc)

=item jbosseap.$step.deployable

Identifies a file to be deployed to JBoss. This can be multi-valued to deploy a set of files.

=item jbosseap.$step.deployto

The directory to deploy to. Generally this would be something like path/to/jboss/server/standalone/deployments, but files can be moved anywhere required.

=item jbosseap.$step.timeout

Timeout in seconds used by both waitfordeploy and waitforstart.

=item jbosseap.$step.appid

A string which waitfordeploy will watch for in the jmx-console web app. If this string shows up there waitfordeploy will decide that the
deployment has been finished. Note that it only checks localhost since there is not really a way to deploy to a remote container anyway, but
this could be parameterized.

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
