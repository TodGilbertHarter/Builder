package SCP;

use strict;
use base qw(Step);
use Net::SFTP;
use Net::SFTP::Util;
use Net::SFTP::Attributes;
use Net::SFTP::Recursive;
use IO::All;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $source = $self->genPath($self->builder()->getScalarProperty("scp.$step.sourcedir"));
	my $includes = eval { $self->builder()->getProperty("scp.$step.include"); };
	my $host = $self->builder()->getScalarProperty("scp.$step.host");
	my $target = $self->builder()->getScalarProperty("scp.$step.target");
	my $user = eval { $self->builder()->getScalarProperty("scp.$step.user"); };
	my $password = eval { $self->builder()->getScalarProperty("scp.$step.password"); };
	my $mkdirs = eval { $self->builder()->getScalarProperty("scp.$step.dirflag"); };

#	my $sftp;
#	if($user) {
#		$self->debug("logging into remote host $host as $user");
#		$sftp = Net::SFTP->new($host, 'user' => $user, 'password' => $password, 'warn' => \&_warn );
#	} else {
#		$self->debug("not using authentication for host $host");
#		$sftp = Net::SFTP->new($host, 'warn' => \&_warn);
#	}

#	my @source = ref($source) ? (@$source) : ($source);
#	$includes = ".*" if $includes eq '';
#	my @includes = ref($includes) ? (@$includes) : ($includes);
#	foreach my $sdir (@source) {
#		my @sfiles = io($sdir)->all(0);
#		foreach my $file (@sfiles) {
#			my $flag = 0;
#			foreach my $i (@includes) {
#				$flag = 1 if $file =~ /$i/;
#			}
#			$flag = 0 if $file =~ /\.svn/;
#			if($flag && ! -d $file) {
#				$self->debug("copying file from $file to scp://$host/$target");
#				my $tf = "$target/$file";
#				if($mkdirs eq 'true') {
#					$self->debug("Making dirs $sdir $file");
#					my $fbase = $self->_prunePath($sdir,$file);
#					$self->_makeDirs($file,$target,$sftp);
#				} else {
#					(undef,undef,$tf) = $file->splitpath();
#					$tf = "$target/$tf";
#				}
#				unless($sftp->put("$file","$tf")) {
#					my $err = Net::SFTP::Util::fx2txt($sftp->status());
#					$self->error("transfer to scp://$host/$tf failed, reason $err");
#				}
#			}
#		}
#	}
	my $sftp;
	if($user) {
		$self->debug("logging into remote host $host as $user");
		$sftp = Net::SFTP::Recursive->new($host, 'user' => $user, 'password' => $password, 'warn' => \&_warn );
	} else {
		$self->debug("not using authentication for host $host");
		$sftp = Net::SFTP::Recursive->new($host, 'warn' => sub { $self->debug("SFTP Warning: ".$@[0]); }, 'debug' => $self->isDebug() );
	}
	$sftp->rput($source,$target,
		sub {
			my ($s,$l,$r,$ar) = @_;
			$self->debug("copied $l to $r");
		}
	,{'file_pat' => $includes});
	$self->info("remote copy from $source to scp://$host/$target completed");
}

sub _prunePath {
	my ($self,$base,$path) = @_;
	my $res = $path;
	$res =~ s|$base||;
	return $res;
}

# noop to get rid of useless warnings.
sub _warn {

}

sub _makeDirs {
	my ($self,$source,$targetdir,$sftp) = @_;
	my @tdirs = split('\/',$source);
	pop(@tdirs);
	my $path = $targetdir;
	foreach my $tdir (@tdirs) {
		if($tdir ne '') {
			my $code = $sftp->do_mkdir("$path/$tdir",Net::SFTP::Attributes->new('Stat' => stat "$path/$tdir"));
# OK, error handling is wonderfully hapless, so we'll just forget about it for now...
#			if($code) {
#				my $err = Net::SFTP::Util::fx2txt($code);
#				$self->error("creating remote dir $path/$tdir failed, reason $err");
#			}
			$path .= "/$tdir";
		}
	}
}

1;


__END__

=head1 NAME

SCP - Dilettante secure copy module

=head1 DESCRIPTION

Use ssh to move files from local machine to a remote system.

=head2 CONFIGURATION

=over 4

=item scp.<step>.sourcedir

The source directory from which files will be copied.

=item scp.<step>.include

Regex which files to copy must match. If not provided then all files will be copied.

=item scp.<step>.target

Directory on target where files will be placed. Can be relative or absolute, etc.

=item scp.<step>.user

Username for remote system. If this is not provided it will be assumed no auth is required.

=item scp.<step>.password

If user is provided then this should also be provided generally.

=item scp.<step>.dirflag

If this has a true value the source directory structure will be replicated on the remote host, otherwise
matching files will simply be copied to target. Either one can be handy depending on what you want to do.

=back

B<NOTE:> there are potentially lots of other ssh parameters that could be useful. If you need them, hack them in, they are
potentially pretty numerous, mostly rarely required, and thus it hasn't been done so far.

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
