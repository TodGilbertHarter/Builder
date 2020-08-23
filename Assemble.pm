package Assemble;

use strict;
use base qw(Step);
use IO::All;
use File::Copy::Recursive;
use Cwd;
use Data::Dumper;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $sources = $self->genPath($self->builder()->getScalarProperty("assemble.$step.source"));
	my $target = $self->genPath($self->builder()->getScalarProperty("assemble.$step.target"));
	my $include = eval { $self->builder()->getProperty("assemble.$step.include"); };
	$include ||= ".*";
	io($target)->mkpath() unless -d $target;
	$self->_mvSrc($sources,$target,$include);
	$self->info("Assemble copied files to $target");
}

sub _mvSrc {
	my ($self,$source,$target,$include) = @_;

	my @sio = -f $source ? ($source) : io($source)->all_files(0);
	foreach my $sf (@sio) {
		my @foohaa = io($sf)->splitpath();
		my $fname = pop(@foohaa);
		if($fname =~ $include && $fname !~ /^.svn/) {
			$self->debug("Assemble copying $sf to $target/$fname");
			io($sf) > io("$target/$fname");
		}
	}
}

sub copyTree {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $sources = $self->genPath($self->builder()->getScalarProperty("assemble.$step.source"));
	my $target = $self->genPath($self->builder()->getScalarProperty("assemble.$step.target"));
	my $include = eval { $self->builder()->getProperty("assemble.$step.include"); };
	$include ||= ".*";
	io($target)->mkpath() unless -d $target;
	File::Copy::Recursive::dircopy($sources,$target);

#	my @sio = io($sources)->all(0);
#	eval {
#		foreach my $sf (@sio) {
	#print "WHAT THE FUCK $sf\n";
#			if($sf->is_file()) {
#				my $path = $self->filePath($sf);
	#print "FILE PATH IS $path\n";
#				my $fname = $self->fileFromPath($sf);
	#print "FILE NAME IS $fname\n";
#				$path = $self->_prunePath($sources,$path);
	#print "PRUNED PATH IS $path\n";
#				$self->_makeDirs($path,$target);
#				$self->debug("Copy $sf to $target/$path/$fname");
#				io($sf) > io("$target/$path/$fname");
#			}
#		}
#	};
#	$self->error("copyTree failed with $@\n" if $@;
	$self->info("copyTree copied files to $target");
}

sub copyFiles {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
#	my $sources = $self->genPath($self->builder()->getScalarProperty("assemble.$step.source"));
	my $sources = $self->genPath($self->builder()->getProperty("assemble.$step.source"));
	$sources = ref($sources) ? $sources : [$sources];
	my $target = $self->genPath($self->builder()->getScalarProperty("assemble.$step.target"));
	my $include = eval { $self->builder()->getProperty("assemble.$step.include"); };
	$include ||= ".*";
	$include = ref($include) ? $include : [$include];
	io($target)->mkpath() unless -d $target;
	foreach my $source (@$sources) {
	  $self->debug("Copying from directory $source");
	  # remember children, each component that all_files() sees MUST be a directory
	  # otherwise you just get some bullshit erroneous error from perl! In other words
	  # you can't make your $sources a set of FILES, only a set of directories to copy
	  # all the files out of.
	  my @files = io($source)->all_files();
	  foreach my $file (@files) {
		  foreach my $inc (@$include) {
			  if($file =~ $inc) {
				  my (undef,undef,$infile) = io($file)->splitpath();
				  io($file) > io("$target/$infile");
			  }
		  }
	  }
    }
	$self->info("copyFiles copied files to $target");
}

sub remove {
	my ($self) = @_;
	my $step = $self->getStep();
	my $target = $self->genPath($self->getScalarProperty("assemble.$step.target"));
	my $excludes = eval { $self->getProperty("assemble.$step.excludes"); };
	$self->_remove($target,$excludes);
}

sub _remove {
	my ($self,$target,$excludes) = @_;
	if($excludes != undef) {
		$excludes = ref($excludes) ? $excludes : [$excludes];
		my @stuff = io($target)->all();
		foreach my $thing (@stuff) {
			if(io($thing)->is_dir()) {
				$self->_remove($thing,$excludes);
			} else {
				my $exflag = 0;
				for my $exclude (@$excludes) {
					$exflag ||= $thing =~ $exclude;
				}
				if(!$exflag) {
					if(io($thing)->is_dir()) {
						$self->_remove($thing,$excludes);
					} else {
						io($thing)->unlink();
					}
				}
			}
		}
	} else {
		io($target)->rmtree();
	}
}

# use Data::Dumper;

sub copyDeps {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $deps = $self->builder()->getProperty('dependencies.deps');
	
#$self->debug("DEPS LOOK LIKE ".Dumper($deps));	
	my $scope = eval { $self->builder()->getScalarProperty("assemble.$step.scope"); };
	my $target = $self->genPath($self->builder()->getScalarProperty("assemble.$step.target"));
	my $flag = eval { $self->builder()->getScalarProperty("assemble.$step.stripversion"); };
	my $explode = eval { $self->builder()->getScalarProperty("assemble.$step.explode"); } eq 'true';
	my $include = eval { $self->builder()->getProperty("assemble.$step.include"); };
	my $nosubdir = eval { $self->builder()->getScalarProperty("assemble.$step.nosubdir"); };
	$include = ".*" unless $include;
	$include = ref($include) ? $include : [$include];
	io($target)->mkpath() unless -d $target;
	foreach my $depkey (keys(%$deps)) {
		my $incflag = 0;
		foreach my $inc (@$include) {
			if($depkey =~ $inc) {
				$incflag = 1;
			}
		}
$self->debug("TESTING TO GET -> $depkey WITH SCOPE SET TO $scope AND DEPS SAYS SCOPE IS ".$deps->{$depkey}->getScope());
		if($incflag == 1 && ($deps->{$depkey}->getScope() eq $scope || $scope eq '')) {
$self->debug("GET TEST PASSED FOR $depkey");
#		if($incflag == 1) {
			if($explode) {
			$self->explodeDependency($deps->{$depkey},$target,$flag,$nosubdir);
			} else {
				$self->copyDependency($deps->{$depkey},$target,$flag);
			}
			my $subdeps = $deps->{$depkey}->getSubDeps();
			if(defined $subdeps) {
				foreach my $subdepkey (keys(%$subdeps)) {
					my $incflag = 0;
					foreach my $inc (@$include) {
			#print "WTF IS INCLUDE $inc depkey is $depkey\n";
						if($subdepkey =~ $inc) {
							$incflag = 1;
#$self->debug("TRYING TO CLEAR OUT STUPID SUBDEPS $incflag, ".$subdeps->{$subdepkey}->getScope().", scope $scope with subdepkey of $subdepkey");
							unless($incflag == 1 && ($subdeps->{$subdepkey}->getScope() eq $scope || $scope eq '')) { $incflag = 0; }
						}
					}
#$self->debug("WTF is going on here now ".$subdeps->{$subdepkey}->getScope()." incflag is $incflag, subdepkey $subdepkey");
					if($subdeps->{$subdepkey}->getScope() eq 'compile' && $incflag == 1) {
						$self->copyDependency($subdeps->{$subdepkey},$target,$flag);
					}
				}
			}
		}
	}
	$self->info("Dependencies copied to $target");
}

1;

__END__

=head1 NAME

Assemble - Dilettante packaging module

=head1 DESCRIPTION

Assemble provides an easy way to construct distributable assemblies of software components.

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
