package Install;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $gpath = $self->builder()->getScalarProperty('build.groupid');
	$gpath =~ s|\.|/|g;
	my $targetdir = $self->builder()->getScalarProperty('build.localrepository')
		."/$gpath/"
		.$self->builder()->getScalarProperty('build.artifactid')."/"
		.$self->builder()->getScalarProperty('build.version');
	$self->debug("Installing to $targetdir");
	$self->_copy($targetdir,"");
}

sub deploy {
	my ($self) = @_;

	my $gpath = $self->builder()->getScalarProperty('build.groupid');
	$gpath =~ s|\.|/|g;
	my $targetdir = $self->builder()->getScalarProperty('build.grouprepository')
		."/$gpath/"
		.$self->builder()->getScalarProperty('build.artifactid')."/"
		.$self->builder()->getScalarProperty('build.version');
	$self->debug("Deploying to $targetdir");
	$self->_copy($targetdir,"");
}

# allow deployment of an arbitrary file to repo as part of a build
sub installFile {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $ftype = $self->getScalarProperty("install.$step.type");
	my $source = $self->getScalarProperty("install.$step.sourcefile");
	my $ext = $self->getScalarProperty("install.$step.extension");

	my $fbase = $self->builder()->getScalarProperty('build.artifactid')."-$ftype-"
		.$self->builder()->getScalarProperty('build.version').".$ext";

	my $gpath = $self->builder()->getScalarProperty('build.groupid');
	$gpath =~ s|\.|/|g;
	my $targetdir = $self->builder()->getScalarProperty('build.localrepository')
		."/$gpath/"
		.$self->builder()->getScalarProperty('build.artifactid')."/"
		.$self->builder()->getScalarProperty('build.version');
	$self->debug("$source copied to $targetdir/$fbase");
	io($source) > io("$targetdir/$fbase");
}

# allow deployment of an arbitrary file to repo as part of a build
sub deployFile {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $ftype = $self->getScalarProperty("install.$step.type");
	my $source = $self->getScalarProperty("install.$step.sourcefile");
	my $ext = $self->getScalarProperty("install.$step.extension");

	my $fbase = $self->builder()->getScalarProperty('build.artifactid')."-$ftype-"
		.$self->builder()->getScalarProperty('build.version').".$ext";

	my $gpath = $self->builder()->getScalarProperty('build.groupid');
	$gpath =~ s|\.|/|g;
	my $targetdir = $self->builder()->getScalarProperty('build.grouprepository')
		."/$gpath/"
		.$self->builder()->getScalarProperty('build.artifactid')."/"
		.$self->builder()->getScalarProperty('build.version');
	$self->debug("$source copied to $targetdir/$fbase");
	io($source) > io("$targetdir/$fbase");
}

sub testInstall {
	my ($self) = @_;

	my $gpath = $self->builder()->getScalarProperty('build.groupid');
	$gpath =~ s|\.|/|g;
	my $targetdir = $self->builder()->getScalarProperty('build.localrepository')
		."/$gpath/"
		.$self->builder()->getScalarProperty('build.artifactid')."/"
		.$self->builder()->getScalarProperty('build.version');

	$self->_copy($targetdir,"tests");
}

sub sourceInstall {
	my ($self) = @_;

	my $gpath = $self->builder()->getScalarProperty('build.groupid');
	$gpath =~ s|\.|/|g;
	my $targetdir = $self->builder()->getScalarProperty('build.localrepository')
		."/$gpath/"
		.$self->builder()->getScalarProperty('build.artifactid')."/"
		.$self->builder()->getScalarProperty('build.version');

	$self->_copy($targetdir,"source","jar");
}

sub sourceDeploy {
	my ($self) = @_;

	my $gpath = $self->builder()->getScalarProperty('build.groupid');
	$gpath =~ s|\.|/|g;
	my $targetdir = $self->builder()->getScalarProperty('build.grouprepository')
		."/$gpath/"
		.$self->builder()->getScalarProperty('build.artifactid')."/"
		.$self->builder()->getScalarProperty('build.version');

	$self->_copy($targetdir,"source","jar");
}

sub testDeploy {
	my ($self) = @_;

	my $gpath = $self->builder()->getScalarProperty('build.groupid');
	$gpath =~ s|\.|/|g;
	my $targetdir = $self->builder()->getScalarProperty('build.grouprepository')
		."/$gpath/"
		.$self->builder()->getScalarProperty('build.artifactid')."/"
		.$self->builder()->getScalarProperty('build.version');

	$self->_copy($targetdir,"tests");
}

sub _copy {
	my ($self,$targetdir,$type,$packaging) = @_;

	$packaging = $packaging ? $packaging : $self->builder()->getScalarProperty('build.packaging');
	$type = "-$type" if $type ne "";
	$type .= "-";
	my $fbase = $self->builder()->getScalarProperty('build.artifactid')."$type"
		.$self->builder()->getScalarProperty('build.version');

	my $base = $self->builder()->getScalarProperty('build.target')."/$fbase";

	my $file = $base.".".$packaging;

	my $depsfile = "$base.dependencies";

	my $filetarget = "$targetdir/$fbase.".$packaging;
	my $depstarget = "$targetdir/$fbase.dependencies";

	io("$targetdir/")->mkpath();
	$self->debug("Copying $file to $filetarget");
	io($file) > io($filetarget);
	$self->info("Copied $file to $filetarget");
	if($type eq "-") {
		$self->debug("Copying $depsfile to $depstarget");
		io($depsfile) > io($depstarget);
		$self->info("Copied $depsfile to $depstarget");
	}
}

1;


__END__

=head1 NAME

Install - Dilettante installer module

=head1 DESCRIPTION

Install copies both the primary artifact identified by build.artifactid, build.version, and build.packaging to the location
${build.localrepository}/${build.groupid}/${build.artifactid}-${build.version}.${build.packaging}. In addition it copies the 
corresponding .dependencies file to the same location.

Install also provides an additional action deploy, which behaves identically except it copies the artifact to the 
build.grouprepository location.

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
