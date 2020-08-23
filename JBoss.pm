package JBoss;

use base qw(Step);
use strict;
use LWP;
use LWP::UserAgent;
use HTTP::Request;
use IO::All;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $jbossdir = $self->builder()->getScalarProperty("jboss.$step.jbossdir");
	my $config = $self->builder()->getScalarProperty("jboss.$step.config");

	$ENV{JBOSS_HOME}="$jbossdir";
	$ENV{JBOSSSH}="$jbossdir/bin/run.sh -c $config";
	chmod 0755, "$jbossdir/bin/run.sh", "$jbossdir/bin/jboss_init_tsi.sh";
	$self->error("Failed to start jboss from $jbossdir") if
		system("/bin/bash","$jbossdir/bin/jboss_init_tsi.sh","start");
	$self->info("Jboss server started at $jbossdir");
	$self->registerCleanupStep('stopjboss');
}


sub deploy {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $deployables = $self->builder()->getProperty("jboss.$step.deployable");
	$deployables = ref($deployables) ? $deployables : [$deployables];

	foreach my $deployable (@$deployables) {
#		my $deployable = $self->builder()->getProperty("jboss.$step.deployable");
		my $depfile = $self->fileFromPath($deployable);
		my $deployto = $self->builder()->getScalarProperty("jboss.$step.deployto");
	
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
	my $deployable = $self->builder()->getProperty("jboss.$step.deployable");
	my $deployto = $self->builder()->getScalarProperty("jboss.$step.deployto");

	unlink("$deployto/$deployable")
		|| $self->error("Deployer failed to undeploy $deployable from $deployto");
	$self->info("$deployable undeployed");
}

sub stop {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $jbossdir = $self->builder()->getScalarProperty("jboss.$step.jbossdir");
	my $config = $self->builder()->getScalarProperty("jboss.$step.config");

	$ENV{JBOSS_HOME}="$jbossdir";
	$ENV{JBOSSSH}="$jbossdir/bin/run.sh -c $config";
	$self->error("Failed to stop jboss from $jbossdir") if
		system("/bin/bash","$jbossdir/bin/jboss_init_tsi.sh","stop");
}

sub waitforstart {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $timeout = $self->builder()->getScalarProperty("jboss.$step.timeout");

	my $t = $timeout;
	my $ua = LWP::UserAgent->new();
	my $req = HTTP::Request->new('GET' => "http://localhost:8080/jmx-console/");
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
	my $timeout = $self->builder()->getScalarProperty("jboss.$step.timeout");
	my $string = $self->builder()->getScalarProperty("jboss.$step.appid");
	my $username = eval {$self->getScalarProperty("jboss.$step.username") };
	my $passwd = eval {$self->getScalarProperty("jboss.$step.password") };

	my $t = $timeout;
	my $ua = LWP::UserAgent->new();
	$ua->credentials('localhost:8080','JMX',$username => $passwd);
	my $req = HTTP::Request->new('GET' => "http://localhost:8080/jmx-console/HtmlAdaptor?action=displayMBeans");
	while($timeout > 0) {
		my $response = $ua->request($req);
		if($response->is_success() && $response->content() =~ m/$string/gs)
		{
			return;
		}
		$self->debug("Request returned status ".$response->status_line()." waiting for app ".$string);
		if($response->header('WWW-Authenticate')) {
# Reveals some info, so don't put it out, but if you REALLY need to debug some obscure problem...
#			$self->debug("I think I'm using $username, $passwd");
			$self->debug("Failed to auth ".$response->header('WWW-Authenticate'));
		}
		$timeout = $timeout - 1;
		sleep(1);
	}
	die("Failed to deploy within given timeout period ($t)\n");
}
1;


__END__

=head1 NAME

JBoss - Dilettante JBoss management actions module

=head1 DESCRIPTION

Provides actions which will start up a JBoss instance, deploy artifacts to it, wait for the server to start, wait for deployment, and stop the
server at the end of the build.

=head1 CONFIGURATION

=over 4

=item jboss.$step.jbossdir

Defines where the jboss top level directory is.

=item jboss.$step.config

Defines which JBoss configuration to use (ie, all, default, etc).

=item jboss.$step.deployable

Identifies a file to be deployed to JBoss. This can be multi-valued to deploy a set of files.

=item jboss.$step.deployto

The directory to deploy to. Generally this would be something like path/to/jboss/server/default/deploy, but files can be moved anywhere required.

=item jboss.$step.timeout

Timeout in seconds used by both waitfordeploy and waitforstart.

=item jboss.$step.appid

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
