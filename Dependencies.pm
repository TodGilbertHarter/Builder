package Dependencies;

use strict;
use base qw(Step);
use IO::All;
use Fcntl;
use Dependency;

sub execute {
	my ($self) = @_;
	my $localrepo = $self->builder()->getScalarProperty('build.localrepository');
	my $grouprepo = $self->builder()->getScalarProperty('build.grouprepository');
	my $dependencies = eval { $self->builder()->getProperty('build.dependency'); };
	my $deppaths = {};
	if(defined $dependencies) {
		$dependencies = [ $self->builder()->getProperty('build.dependency') ] unless ref($dependencies);
	
		my $mdeps = $self->_getManagedDependencies();
		$self->{'deps'} = $self->_calculateDependencies($mdeps,$dependencies);
		$self->_generateDependencyPaths($self->{'deps'},$localrepo,$grouprepo);
		$self->_getSubDeps($self->{'deps'},$localrepo,$grouprepo);
		# OK, now we should have a hash of fully resolved deps with all their subdeps.
		$deppaths = $self->_makeDepPaths($self->{'deps'});
	
		my $dfpath = $self->builder()->getProperty('build.target')."/".$self->builder()->getProperty('build.artifactid')."-"
			.$self->builder()->getProperty('build.version').".dependencies";
		$dfpath = $self->genPath($dfpath);
		$self->_writeDeps($self->{'deps'},$dfpath);
		$self->builder()->addProperty('dependencies.deps',$self->{'deps'});
	}
	$self->builder()->addProperty('dependencies.deppaths',$deppaths);
}

sub depReport {
	my ($self,$level) = @_;

	my $deps = $self->builder()->getProperty('dependencies.deps');
	$level ||= 0;
	$self->_depReport($deps,$level);
}

sub _depReport {
	my ($self,$deps,$level) = @_;

	$level ||= 0;
	foreach my $depkey (keys(%$deps)) {
		my $dep = $deps->{$depkey};
		print "\t" x $level if $level;
		print "Key: $depkey\n";
		print "\t" x $level if $level;
		print "Dependency: ".$dep->toString()."\n";
		foreach my $subdep ($dep->getSubDeps()) {
			$self->_depReport($subdep,$level+1);
		}
	}
}

# update local repo with all newer artifacts from group repo which this build depends on
sub localize {
	my ($self) = @_;

	my $deps = $self->builder()->getProperty('dependencies.deps');
	my $localrepo = $self->builder()->getScalarProperty('build.localrepository');
	my $grouprepo = $self->builder()->getScalarProperty('build.grouprepository');
	foreach my $depkey (keys(%$deps)) {
		my $dep = $deps->{$depkey};
		if($dep->getRepo() eq 'group') {
			my $artifactid = $dep->getArtifactid();
			my $version = $dep->getVersion();
			my $packaging = $dep->getPackaging();
			my $gidpath = $dep->getGroupid();
			$gidpath =~ s|(\.)|/|g;
			my $path = $self->genPath("$localrepo/$gidpath/$artifactid/$version/$artifactid-$version.$packaging");
			my $dpath = $self->genPath("$localrepo/$gidpath/$artifactid/$version/$artifactid-$version.dependencies");
			my $rdpath = $self->genPath("$grouprepo/$gidpath/$artifactid/$version/$artifactid-$version.dependencies");
			io($dep->getPath()) > io($path);
			io($rdpath) > io($dpath) if -f $rdpath;
			foreach my $subdepkey (keys(%{$dep->getSubDeps()})) {
				my $subdep = $dep->getSubDeps()->{$subdepkey};
				if($subdep->getRepo() eq 'group') {
					my $sartifactid = $subdep->getArtifactid();
					my $sversion = $subdep->getVersion();
					my $spackaging = $subdep->getPackaging();
					my $sgidpath = $subdep->getGroupid();
					$sgidpath =~ s|(\.)|/|g;
					my $spath = $self->genPath("$localrepo/$sgidpath/$sartifactid/$sversion/$sartifactid-$sversion.$spackaging");
					my $sdpath = $self->genPath("$localrepo/$sgidpath/$sartifactid/$sversion/$sartifactid-$sversion.dependencies");
					my $srdpath = $self->genPath("$grouprepo/$sgidpath/$sartifactid/$sversion/$sartifactid-$sversion.dependencies");
					io($subdep->getPath()) > io($spath);
					io($srdpath) > io($sdpath) if -f $srdpath;
				}
			}
		}
	}
}

# dump all dependencies to a file
sub _writeDeps {
	my ($self,$deps,$filename) = @_;
	my $fh = IO::All->new()->file($filename);
	foreach my $depkey (keys(%$deps)) {
		my $dep = $deps->{$depkey};
		my $groupid = $dep->getGroupid();
		my $artifactid = $dep->getArtifactid();
		my $version = $dep->getVersion();
		my $type = $dep->getPackaging();
		my $scope = $dep->getScope();
		my $line = "$groupid:$artifactid:$version:$type:$scope\n";
		$fh->print($line);
	}
}

sub _makeDepPaths {
	my ($self,$deps) = @_;

	my $deppaths = { 'compile' => [], 'test' => [], 'provided' => [] };
	foreach my $depkey (keys(%$deps)) {
		my $dep = $deps->{$depkey};
		my $scope = $dep->getScope();
		push(@{$deppaths->{$scope}},$dep->getPath());
		my $subdeps = $dep->getSubDeps();
		foreach my $subdepkey (keys(%$subdeps)) {
			my $subdep = $subdeps->{$subdepkey};
			my $subscope = $subdep->getScope();
			$subscope = 'test' if $scope eq 'test';
			$subscope = 'provided' if $scope eq 'provided';
			push(@{$deppaths->{$subscope}},$subdep->getPath()) unless $subscope eq 'fixture';
		}
	}
	return $deppaths;
}

# construct a hash for any managed dependencies and return it. Each entry is keyed on the groupid, artifactid, and packaging.
sub _getManagedDependencies {
	my ($self) = @_;
	my $depman = eval { $self->builder()->getProperty('build.dependency.managed'); };
	my @depman = ref($depman) ? @$depman : ( $depman );

	my $deps = {};
	foreach my $mdep (@depman) {
		$self->builder()->debug("Found managed dependency $mdep");
		my ($groupid,$artifactid,$version,$packaging,$scope) = split(':',$mdep);
		my $key = "$groupid:$artifactid:$packaging";
		$deps->{$key} = Dependency->new('scope' => $scope, 'version' => $version, 'groupid' => $groupid,
			'artifactid' => $artifactid, 'packaging' => $packaging);
	}
	return $deps;
}

# convert an array ref of raw dependencies into a hash of Dependency objects keyed by $groupid, $artifactid, $packaging.
sub _generateDependencies {
	my ($self,$dependencies) = @_;

	my $deps = {};
	foreach my $dep (@$dependencies) {
		chomp($dep);
		if($dep ne '') {
			my ($groupid,$artifactid,$version,$packaging,$scope) = split(':',$dep);
			my $key = "$groupid:$artifactid:$packaging";
			$deps->{$key} = Dependency->new('scope' => $scope, 'version' => $version, 'groupid' => $groupid,
				'artifactid' => $artifactid, 'packaging' => $packaging);
		}
	}
	return $deps;
}

# figure out based on a given list of  dependencies and dependency management info exactly what dependencies we have and what
# the scope of each one is. The result is a hash of all dependencies with version and scope resolved as needed.
sub _calculateDependencies {
	my ($self,$mdeps,$dependencies) = @_;

	my $deps = $self->_generateDependencies($dependencies);
	foreach my $depkey (keys(%$deps)) {
		my $dep = $deps->{$depkey};
		if($dep->getScope() eq '') {
			if(defined($mdeps->{$depkey})) {
				if($mdeps->{$depkey}->getScope() ne '') {
					$dep->setScope($mdeps->{$depkey}->getScope());
				} else {
					$dep->setScope('compile');
				}
			}
		}
		if($dep->getVersion() eq '') {
			if(defined($mdeps->{$depkey})) {
				if($mdeps->{$depkey}->getVersion() ne '') {
					$dep->setVersion($mdeps->{$depkey}->getVersion());
				} else {
					$self->builder()->error("Must supply version info for dependency ".$dep->toString());
				}
			} else { 
				if($dep->getArtifactid() =~ /(-tests|-sql|-bin|-source)$/) {
					my $modaid = $1;
					my $modkey = $depkey;
					$modkey =~ s/$modaid//;
					if(defined($mdeps->{$modkey}) && ($mdeps->{$modkey}->getVersion() ne '')) {
						$dep->setVersion($mdeps->{$modkey}->getVersion());
					} else {
						$self->builder()->error("$modkey Must supply version info for dependency ".$dep->toString());
					}
				}
			}
		}
	}
	return $deps;
}

# given a hash of dependency objects, identify the location of each one and flag which is more recent, local or group and
# set the path value for each one to point to wherever it is.
sub _generateDependencyPaths {
	my ($self,$deps,$localrepo,$grouprepo) = @_;

	foreach my $depkey (keys(%$deps)) {
		$self->_generateDependencyPath($deps->{$depkey},$localrepo,$grouprepo);
	}
}

# determine which repository, if any, a dependency resides in and resolve it to a path, or throw an error if it can't be resolved.
# If instances exist in both repositories, use the most recently modified one.
sub _generateDependencyPath {
	my ($self,$dep,$localrepo,$grouprepo) = @_;

	my $groupid = $dep->getGroupid();
	my $artifactid = $dep->getArtifactid();
	my $version = $dep->getVersion();
	my $packaging = $dep->getPackaging();

	my $gidpath = $groupid;
	$gidpath =~ s|(\.)|/|g;
	my $path = $self->genPath("$localrepo/$gidpath/$artifactid/$version/$artifactid-$version.$packaging");
	if($artifactid =~ /^(.*)-tests$/) {
		$path = $self->genPath("$localrepo/$gidpath/$1/$version/$artifactid-$version.$packaging");
	} elsif ($artifactid =~ /^(.*)-sql$/) {
		$path = $self->genPath("$localrepo/$gidpath/$1/$version/$artifactid-$version.$packaging");
	} elsif ($artifactid =~ /^(.*)-bin$/) {
		$path = $self->genPath("$localrepo/$gidpath/$1/$version/$artifactid-$version.$packaging");
	} elsif ($artifactid =~ /^(.*)-source$/) {
		$path = $self->genPath("$localrepo/$gidpath/$1/$version/$artifactid-$version.$packaging");
	}
	$self->builder()->debug("Searching for dependency at $path");
	my $mtime;
	if(-f $path) {
		$mtime = io($path)->mtime();
		$dep->setRepo('local');
		$dep->setPath($path);
	}

	$path = $self->genPath("$grouprepo/$gidpath/$artifactid/$version/$artifactid-$version.$packaging");
	if($artifactid =~ /^(.*)-tests$/) {
		$path = $self->genPath("$grouprepo/$gidpath/$1/$version/$artifactid-$version.$packaging");
	} elsif ($artifactid =~ /^(.*)-sql$/) {
		$path = $self->genPath("$grouprepo/$gidpath/$1/$version/$artifactid-$version.$packaging");
	} elsif ($artifactid =~ /^(.*)-bin$/) {
		$path = $self->genPath("$grouprepo/$gidpath/$1/$version/$artifactid-$version.$packaging");
	} elsif ($artifactid =~ /^(.*)-source$/) {
		$path = $self->genPath("$grouprepo/$gidpath/$1/$version/$artifactid-$version.$packaging");
	}
	$self->builder()->debug("Searching for dependency at $path");
	if(-f $path) {
		if(io($path)->mtime() > $mtime) {
			$dep->setRepo('group');
			$dep->setPath($path);
		}
	}
	$self->error("Failed to resolve $groupid:$artifactid:$version:$packaging") unless $dep->getRepo();
}

sub _getSubDeps {
	my ($self,$deps,$localrepo,$grouprepo) = @_;

	foreach my $depkey (keys(%$deps)) {
		$self->_getSubDep($deps->{$depkey},$localrepo,$grouprepo);
	}
}

# create a set of dependency objects for a dependency of an existing dependency and attach them to the
# dependency they relate to.
sub _getSubDep {
	my ($self,$dep,$localrepo,$grouprepo) = @_;

	my $groupid = $dep->getGroupid();
	my $artifactid = $dep->getArtifactid();
	my $version = $dep->getVersion();
	my $packaging = $dep->getPackaging();
	my $repo = $dep->getRepo() eq 'local' ? $localrepo : $grouprepo;

	my $gidpath = $groupid;
	$gidpath =~ s|(\.)|/|g;
	my $infopath = $self->genPath("$repo/$gidpath/$artifactid/$version/$artifactid-$version.dependencies");
	$self->builder()->debug("Locating subdependency info for $artifactid at $infopath");
	my $deps;
	if(-f $infopath) {
		$self->builder()->debug("Found subdependency info for $artifactid at $infopath");
		my @deps = io($infopath)->slurp();
		$deps = $self->_generateDependencies(\@deps);
	}
	$self->_generateDependencyPaths($deps,$localrepo,$grouprepo);
	return $dep->setSubDeps($deps);
}

# add a path to a scope in deppaths
sub _addDependency {
	my ($self,$deppaths,$scope,$path) = @_;

	$deppaths->{$scope} = [] unless defined($deppaths->{$scope});
	push(@{$deppaths->{$scope}},$path);
}

1;

__END__

=head1 NAME

Dependencies - Dilettante Java dependency resolution action

=head1 DESCRIPTION

Dependencies provides a scoped transitive dependency management facility for Java modules. This operates in a manner similar to
the dependency mechanism utilized by Maven 2.x. 

=head2 DEPENDENCY ATTRIBUTES

Every dependency has 5 attributes, groupid, artifactid, scope, version, and type. The groupid simply provides a namespace for 
artifacts generated by different organizations, groups, development teams, etc. The artifactid identifies a particular dependency 
object within the scope of a groupid. The scope identifies the use of the dependency. The type identifies a particular format or
classification of dependency. The version identifies a particular versioned instance of a given dependency.

=head3 GROUPID

Dependencies are segregated by group ids in order to allow for overlapping artifact ids provided by different vendors etc. Each
artifact belongs to a particular group. Thus artifactid 'foo', group 'bar' is distinguished from artifactid 'foo', group 'baz'.

=head3 ARTIFACTID

The artifact id is the unique identifier of a particular artifact within it's group.

=head3 SCOPE

Artifact scope is an indication to the build system as to what use the artifact will be put. Generally 3 scopes exist and are
supported directly by the Dependencies module, compile, test, and provided.

=over 4

=item compile

Compile scope indicates that the artifact is a library which is required in order to compile and/or link the module. A compile
scope artifact is also assumed to be required at runtime.

=item test

Test scope indicates a dependency is required to compile/link and/or run unit tests. A test scope artifact is assumed NOT to be
required at runtime.

=item provided

Provided scope is identical to compile scope except it indicates to packaging or build functionality that the artifact does not
need to be included in whatever final form the output of the build takes. 

=back

=head3 VERSION

The version identifies a particular instance of a dependency, for example version 1.0.0 of a given library.

=head3 TYPE

The type allows for the existence of multiple different instantiations of the artifact, such as different file formats, or the
creation of a set of related objects such as a jar and associated test jars. 

=head2 TRANSITIVITY

Dependencies supports the notion of transitivity of dependencies. Thus if module A depends on B, and B depends on C, then A will
automatically depend on C as well. Certain scoping rules are applied in order to keep transitive dependencies in the proper
scope. If a test dependency has compile dependencies, then these will be 'demoted' to the test scope. Likewise a compile
dependency of a provided dependency will be demoted to scope provided. 

=head2 MANAGED DEPENDENCIES

In order to simplify dependency management version and scope information can be extracted from the property 
build.dependency.managed. A project level build.properties file can then set values in this property which will be picked up by
all projects utilizing this configuration which require the given dependency. This allows version and scope specification to be
centralized in one location.

=head2 CONFIGURATION

Several properties are used to configure the operation of Dependencies.

=over 4

=item build.grouprepository
This points to a directory which is accessible to an entire development group containing artifacts.

=item build.localrepository
This points to a directory which is accessible to a single developer containing artifacts.

=item build.dependency
This is a multi-valued property which is the set of direct dependencies of this module. Each entry is a string containing 5
fields separated by the ':' character. The format is 'groupid:artifactid:version:packaging:scope'.

=item build.dependency.managed
This is a multi-valued property which can supply standardized version numbers and scopes for dependencies. Each entry is
identical in structure to a build.dependency entry. Any build.dependency which omits either scope and/or version will attempt
to supply these from this property.

=back

=head1 OPERATION

Dependencies purpose is to resolve all module dependencies into the ongoing module build. It does this by consulting the
build.dependency property of the module and determining the location of a file containing each dependency. First it assembles
a path for each value of build.dependency of the form 
${build.localrepository}/${groupid}/${version}/${artifactid}-${version}.${type} and determins if this file exists. If not it
uses build.grouprepository and tries again. If either the version or scope components are missing from a dependency, the corresponding
property build.dependency.managed will be consulted in an attempt to supply default values.

In either case if it finds the file it then attempts to find a corresponding file
repository/${groupid}/${version}/${artifactid}-${version}.dependencies, parses dependency entries from this
file, adjusts their scope as required, and also attempts to locate them by the same procedure, adding their dependencies in the
same fashion. If an artifact cannot be located anywhere in the chain an error is issued. 

Assuming all artifacts are located successfully it then adds a new property dependency.deppaths. This property is a hash with
a key for each scope. The value of each scope key is an array containing the paths to all required artifacts at that scope.
Other modules such as the Compile module can utilize this list as necessary.

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
