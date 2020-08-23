package Step;

use strict;
use vars qw($SAVEDOUT $SAVEDERR);
use IO::All;
use File::Copy::Recursive;
use LWP;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common;
use Carp qw(cluck);

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

sub builder {
	return shift->{'builder'};
}

sub getLogLevel {
	my ($self) = @_;
	return $self->getScalarProperty('build.loglevel');
}

sub isDebug {
	my ($self) = @_;
	return $self->getLogLevel() eq 'debug';
}

sub debug {
	my ($self,$message) = @_;

	$self->{'builder'}->debug($message);
}

sub info {
	my ($self,$message) = @_;

	$self->{'builder'}->info($message);
}

sub warn {
	my ($self,$message) = @_;

	$self->{'builder'}->warn($message);
}

sub error {
	my ($self,$message) = @_;

	$self->{'builder'}->error($message);
}

sub execute {
	die("subclass must implement");
}

sub halt {
	my ($self) = @_;
	$self->{'builder'}->halt();
}

sub genPath {
	my ($self,$path) = @_;
	return $self->builder()->genPath($path);
}

sub registerCleanupStep() {
	my ($self,$step) = @_;

	$self->builder()->registerCleanupStep($step);
}

# return the last component of a path, usually a filename, could be a trailing directory
sub fileFromPath {
	my ($self,$path) = @_;
	my @pcs = io($path)->splitpath();
	return pop(@pcs);
}

# return only the path portion (strip the last element from path).
sub filePath {
	my ($self,$path) = @_;
	my @pcs = io($path)->splitpath();
	pop(@pcs);
	return join('/',@pcs);
}

# copy a source file to a target directory
sub copyArtifact {
	my ($self,$source,$dest) = @_;

	my $depfile = $self->fileFromPath($source);
	io($source) > io("$dest/$depfile");
}

# copy a dependency artifact to a target directory, and optionally strip off the version
sub copyDependency {
	my ($self,$dep,$target,$flag) = @_;

#cluck("HOW IS THIS STUPID SHIT CALLED");
	my $deppath = $dep->getPath();
	my @foohaa = io($deppath)->splitpath();
	my $depfile = pop(@foohaa);
	if($flag eq 'true') {
		$depfile = $dep->getArtifactid().".".$dep->getPackaging();
	}
	$self->debug("Copying dependency $deppath to $target/$depfile\n");
	io($deppath) > io("$target/$depfile");
}

sub explodeDependency {
	my ($self,$dep,$target,$stripver,$nosubdir) = @_;

		my $deppath = $dep->getPath();
		my @foohaa = io($deppath)->splitpath();
		my $depfile = pop(@foohaa);
		if($stripver eq 'true') {
			$depfile = $dep->getArtifactid().".".$dep->getPackaging();
		}
		my $tdir = $nosubdir ? $target : "$target/$depfile";
		$self->debug("Exploding dependency $deppath to $tdir\n");
		eval {
			io("$tdir")->mkdir();
		};
#print "WTF IS THE DEPENDENCY ".$dep->getArtifactid()."\n";
		if($dep->getPackaging() eq 'tgz' || $dep->getPackaging() eq 'tar.gz') {
			system('tar','zxf',$deppath,'-C',"$tdir");
		} elsif($dep->getPackaging() eq 'zip' || $dep->getPackaging() eq 'jar' || $dep->getPackaging() eq 'war' || $dep->getPackaging() eq 'ear' || $dep->getPackaging() eq 'rar' ) {
			system('unzip','-qq','-o',$deppath,'-d',"$tdir");
		} elsif($dep->getPackaging() eq 'tar') {
			system('tar','xf',$deppath,'-C',"$tdir");
		} else {
			$self->error("Don't currently support exploding dependencies of this type");
		}
}

sub _prunePath {
	my ($self,$base,$path) = @_;
	my $res = $path;
	$res =~ s|$base||;
	return $res;
}

sub _makeDirs {
	my ($self,$source,$targetdir) = @_;
	my @tdirs = split('\/',$source);
	pop(@tdirs);
	my $path = $targetdir;
	foreach my $tdir (@tdirs) {
#		io("$targetdir/$tdir")->mkdir();
		unless(-d "$path/$tdir") {
			$self->debug("Making dir $path/$tdir");
			io("$path/$tdir")->mkdir();
		}
		$path .= "/$tdir";
	}
	$self->debug("Created resource dirs");
}

sub _copyTree {
	my ($self,$sources,$target,$include) = @_;

	my $step = $self->builder()->getStep();
	$include ||= ".*";
	io($target)->mkpath() unless -d $target;
	File::Copy::Recursive::dircopy($sources,$target);
	$self->info("copyTree copied files to $target");
}

# just a shortcut so you don't have to use $self->builder()->getProperty() in steps...
sub getProperty {
	my ($self,$property) = @_;
	return $self->builder()->getProperty($property);
}

sub setProperty {
	my ($self,$property,$value) = @_;
	return $self->builder()->addProperty($property,$value);
}

sub getScalarProperty {
	my ($self,$property) = @_;
	return $self->builder()->getScalarProperty($property);
}

sub getStep {
	my ($self) = @_;
	return $self->builder()->getStep();
}

# redirect STDOUT/STDERR to dev/null and save current values
sub hideOutput {
	my ($self) = @_;
	my $ll = $self->getProperty('build.loglevel');
	if($ll ne 'debug') {
		open $SAVEDOUT, ">&STDOUT";
		open STDOUT, '>', '/dev/null';
		open $SAVEDERR, ">&STDERR";
		open STDERR, '>', '/dev/null';
	}
}

# restore original STDOUT/STDERR
sub restoreOutput {
	my ($self) = @_;
	my $ll = $self->getProperty('build.loglevel');
	if($ll ne 'debug') {
		open STDOUT, ">&", $SAVEDOUT;
		close $SAVEDOUT;
		open STDERR, ">&", $SAVEDERR;
		close $SAVEDERR;
	}
}

# Simple get. This just does a basic HTTP GET request.

sub get {
	my ($self,$url,$server,$domain,$username,$password) = @_;

	my $ua = LWP::UserAgent->new();
	$ua->credentials($server,$domain,$username => $password) if $server ne undef;
	my $req = HTTP::Request->new('GET' => $url);
	return $ua->request($req);
}

# Like get, but does a POST and a ref to an array or hash of parameters can be provided

sub post {
	my ($self,$url,$params,$server,$domain,$username,$password) = @_;

	my $ua = LWP::UserAgent->new();
	$ua->credentials($server,$domain,$username => $password) if $server ne undef;
	my $req = HTTP::Request::Common::Post($url,$params);
	return $ua->request($req);
}

1;

__END__

=head1 NAME

Step - Dilettante build action base class

=head1 DESCRIPTION

Step is an abstract base class for build actions. It provides a new() method which takes hash key style arguments and is suitable
for invocation on subclasses. Builder calls new() with the arguments 'builder' => $self.

Some convience methods are provided, builder() returns the value of the 'builder' attribute and the functions debug(), info(),
warn(), and error() invoke the corresponding builder logging methods. There are now also a number of other such aliases, see below.

=head1 USE

Step is not intended to be useful in and of itself, it is a base class. Derived classes are B<action modules> and will contain an
use base qw(Step); statement.

=head2 UTILITY FUNCTIONS

There are a number of methods which derived classes can call which simplify building action modules.

=over 4

=item builder()

Returns a reference to the L<Builder> which invoked the step.

=item debug() info() warn() error()

These just call the corresponding methods on the step's builder. They are shortcuts for $self->builder()->debug("message") etc.

=item execute()

The B<default action> of an action module is always a method called execute(). Derived classes should implement this, unless they do not
have any default action.

=item halt()

This calls the Builder halt() method, which immediately stops an ongoing build unconditionally.

=item genPath()

Calls the corresponding Builder method.

=item registerCleanupStep()

Calls the corresponding Builder method.

=item fileFromPath($path)

Returns the last component of $path. This will be the filename, or the innermost directory if it isn't a file.

=item filePath($path)

Returns all but the last component of $path.

=item copyArtifact($source,$dest)

Given a source which specifies a file, copies the file to the directory $dest.

=item copyDependency($dep,$target,$flag)

Given a L<Dependency> object, and a $target directory, recovers a copy of the dependency from one of the repositories (group or local) and
places it in the $target directory. If $flag is false, then the file is named from $dep, otherwise the version will be stripped from the
name of the dependency.

=item explodeDependency($dep,$target,$stripver,$nosubdir)

Copies a dependency and unpackages it. This is similar to copyDependency(), except the dependency will be unarchived if possible. Currently
explode supports tar, tarball (tar,gz, tgz) and zip/jar/war/ear. If $nosubdir is 'true' then the files will be unarchived directly into the
$target directory, otherwise a subdirectory will be created in $target named after the artifact (subject to $stripver naming).

=item hideOutput()

Redirects output from STDOUT and STDERR to /dev/null. The original values are retained for restoration by restoreOutput() later. This is mainly
useful in cases where an action calls a 'chatty' external program which is not polite enough to allow non-verbose use. Output can be dumped
to the bit bucket, the external program called vis system() etc and then output restored afterwards. B<Note:> you will need to be careful if
you do this to handle errors carefully so that output will B<always> get restored, otherwise build output can be lost. For particularly
cantankerous cases the best approach is to write a wrapper script, have the wrapper script redirect output to /dev/null, and call B<that>
from the build. Sadly a lot of build tool authors don't seem to grok good "I/O hygene"...

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
