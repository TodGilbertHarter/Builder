package JavaDoc;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $sourcedir = $self->genPath($self->builder()->getScalarProperty('build.source'));
	my $targetdir = $self->genPath($self->builder()->getScalarProperty('build.target.javadoc'));
	my $javadoc = $self->genPath($self->builder()->getScalarProperty('javadoc.javadocprogram'));
	my $classpath = $self->builder()->generateClassPath(0);
	my $extra = undef;
	eval { $extra = $self->genPath($self->getScalarProperty('javadoc.extra')); };
	$classpath = "$classpath:$extra" if defined($extra);
	$self->debug("javadoc classpath is $classpath");
	my $overview = eval { $self->builder()->getScalarProperty('javadoc.overview'); };
	$self->_buildDoc($sourcedir,$targetdir,$javadoc,$classpath,$overview);
}

# Same as execute except we can be more flexible and pick up arbitrary properties
sub javaDoc {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $sourcedir = $self->genPath($self->builder()->getScalarProperty("javadoc.$step.source"));
	my $targetdir = $self->genPath($self->builder()->getScalarProperty("javadoc.$step.target"));
	my $javadoc = $self->genPath($self->builder()->getScalarProperty('javadoc.javadocprogram'));
	my $classpath = $self->builder()->generateClassPath(0);
	my $extra = undef;
	eval { $extra = $self->genPath($self->getScalarProperty('javadoc.$step.extra')); };
	$classpath = "$classpath:$extra" if defined($extra);
	$self->debug("javadoc classpath is $classpath");
	my $overview = eval { $self->builder()->getScalarProperty("javadoc.$step.overview"); };
	$self->_buildDoc($sourcedir,$targetdir,$javadoc,$classpath,$overview);
}

# do the actual work of building a javadoc set.

sub _buildDoc {
	my ($self,$sourcedir,$targetdir,$javadoc,$classpath,$overview) = @_;
	my @args;
	io($targetdir)->mkdir();
	$self->debug("Overview is $overview");
	my @sources = io($sourcedir)->all(0);
	@sources = grep(/.*\.java$/,@sources);
	$self->debug("Generating javadocs for @sources");
	push(@args,'-d');
	push(@args,$targetdir);
	push(@args,'-classpath');
	push(@args,$classpath);
	if(-f $overview) {
		push(@args,'-overview');
		push(@args,$overview);
	}
	$self->hideOutput();
	$self->error('Javadoc generation failed')
		if system($javadoc,@args,@sources);
	$self->restoreOutput();
}

sub jarDoc {
	my ($self) = @_;
	my $jarfile = $self->builder()->getScalarProperty('build.target')."/"
		.$self->builder()->getScalarProperty('build.artifactid')."-"
		.$self->builder()->getScalarProperty('build.version')."-javadoc.".$self->builder()->getScalarProperty('build.packaging');
	$jarfile = $self->genPath($jarfile);
	my $basedir = $self->genPath($self->builder()->getScalarProperty('build.target.javadoc'));
	my $jarprog = $self->genPath($self->builder()->getScalarProperty('jar.jarprogram'));
	$self->error("Failed to create jar file")
		if(system($jarprog,'cf',$jarfile,'-C',$basedir,'.'));
	$self->info("Constructed jar $jarfile");
}

sub jarInstall {
	my ($self) = @_;

	my $jarfile = $self->builder()->getScalarProperty('build.target')."/"
		.$self->builder()->getScalarProperty('build.artifactid')."-"
		.$self->builder()->getScalarProperty('build.version')."-javadoc.".$self->builder()->getScalarProperty('build.packaging');

	my $repo = $self->builder()->getScalarProperty('build.localrepository');
	$self->_copyJar($jarfile,$repo);
}

sub jarDeploy {
	my ($self) = @_;

	my $jarfile = $self->builder()->getScalarProperty('build.target')."/"
		.$self->builder()->getScalarProperty('build.artifactid')."-"
		.$self->builder()->getScalarProperty('build.version')."-javadoc.".$self->builder()->getScalarProperty('build.packaging');

	my $repo = $self->builder()->getScalarProperty('build.grouprepository');
	$self->_copyJar($jarfile,$repo);
}

sub _copyJar {
	my ($self,$jar,$repo) = @_;

	my $gidpath = $self->builder()->getScalarProperty('build.groupid');
	$gidpath =~ s|(\.)|/|g;
	my $repodir = "$repo/"
		.$gidpath."/"
		.$self->builder()->getScalarProperty('build.artifactid')."/"
		.$self->builder()->getScalarProperty('build.version');

	my $jarfile = $self->fileFromPath($jar);
	$self->info("Copying $jarfile from $jar to $repodir/$jarfile");
	io($jar) > io("$repodir/$jarfile");
}

1;


__END__

=head1 NAME

JavaDoc - Dilettante JavaDoc generator action

=head1 DESCRIPTION

Builds Javadoc for a project. jarDoc() builds a jar archive from the resulting doc files. jarInstall()/jarDeploy() copy
doc jars to local/group repository.

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
