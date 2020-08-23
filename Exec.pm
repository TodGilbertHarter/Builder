package Exec;

use strict;
use base qw(Step);
use Cwd;
use vars qw($PIDS $CFLAG);

$CFLAG = 0;
$PIDS = [];

sub execute {
	my ($self) = @_;

	my $error = undef;
	my $step = $self->getStep();
	my $command = $self->getScalarProperty("exec.$step.command");
#	my $args = eval { $self->getProperty("exec.$step.args"); };
	my $args = eval { $self->builder()->mergePropertyValues("exec.$step.args",' '); };
	my $fork = eval { $self->getScalarProperty("exec.$step.fork"); };
	my $cleanup = eval { $self->getScalarProperty("exec.$step.cleanup"); };
	my $setdir = eval { $self->getScalarProperty("exec.$step.workingdir"); };
	my $cleaner = eval { $self->getScalarProperty("exec.$step.cleaner"); };

	if($fork ne 'true') {
		$self->debug("executing $command with args $args");
		my $curdir = getcwd();
		if($setdir ne '') {
			$self->debug("Setting directory to $setdir");
			chdir($setdir);
		}
		my $error = '';
		$error = "$step exec failed" if
			system("$command $args");
		if($setdir ne '') {
			$self->debug("Resetting directory to $curdir");
			chdir($curdir);
		}
		$self->error($error) if $error ne '';
	} else {
		$self->debug("forking $command with args $args");
#		$SIG{CHLD} = 'IGNORE'; # let child be reaped automatically
		my $pid = fork;
		if(!(defined $pid)) {
# NOTE: since we're actually forking a shell, we can't tell if the command failed or not :(
			$error = "Failed to fork child process $? $!";
		} else {
			if($pid == 0) {
				if($setdir ne '') { chdir($setdir); }
				exec("$command $args");
				# if we get here, there WAS an error...
				print(STDERR "Child failed to exec $!\n");
				exit(-1);
			} else {
				if($cleanup eq 'true') {
					$self->addPid($pid);
				} elsif($cleaner ne '') {
					$self->registerCleanupStep($cleaner);
				}
			}
		}
	}


	$self->error($error) if($error);
}

sub addPid {
	my ($self,$pid) = @_;
	$self->debug("Adding $pid to cleanup list");
	if($CFLAG == 0) {
		$self->registerCleanupStep('killchildren');
	}
	push(@$PIDS,$pid);
}

sub killChildren {
	my ($self) = @_;
	foreach my $pid (@$PIDS) {
		$self->debug("looking for child pid $pid");
		if(kill(0,$pid)) {
			$self->debug("killing child pid $pid");
			kill('HUP',$pid);
		}
	}
}

1;

__END__

=head1 NAME

Exec - Dilettante command line execution build step

=head1 DESCRIPTION

Exec executes arbitrary commands via a shell command line.

=head2 CONFIGURATION

Executing a shell script in the background might look like this:

	step.myexec=Exec
	exec.myexec.command=${build.target}/script.sh
	exec.myexec.args=2>&1 1>/dev/null
	exec.myexec.fork=true
	exec.myexec.cleanup=true

=over 4

=item exec.$step.command

The command to invoke. Note that relative paths may or may not work on different platforms.

=item exec.$step.args

Command line arguments to pass to the command being executed.

=item exec.$step.fork

If true this property will cause the command line to be executed as a separate task via a fork
and exec. Note that this has variable results on different platforms. No explicit I/O redirection
is performed. If required this should be specified as part of the args.

=item exec.$step.cleanup

If true a forked child process will be killed in a registered cleanup at the end of the build. If not, then forked child processes will continue to exist after the build has been
completed. This will have no effect if exec.$step.fork is not true.

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
