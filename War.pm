package War;

use strict;
#use Java::Build::Tasks;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $wardir = $self->builder()->getScalarProperty('build.target')."/"
		.$self->builder()->getScalarProperty('build.artifactid')."-"
		.$self->builder()->getScalarProperty('build.version');
	my $warfile = $wardir.".".$self->builder()->getScalarProperty('build.packaging');
	my $classesdir = $self->builder()->getScalarProperty('build.target.classes');
	$self->_cleanDir($wardir);
	eval {
		io->dir($wardir)->mkdir();
	};
	rename($self->builder()->getProperty('build.target')."/WEB-INF","$wardir/WEB-INF");
	rename($classesdir,"$wardir/WEB-INF/classes");
	my $filelist = $self->_makeFileList($wardir);
	my $jarprog = $self->builder()->getScalarProperty('jar.jarprogram');
#	jar(JAR_FILE => $warfile, BASE_DIR => $wardir, FILE_LIST => $filelist);
	$self->error("Failed to create war file")
		if(system($jarprog,'cf',$warfile,'-C',$wardir,'.'));
	$self->info("Constructed war $warfile");
}

sub _makeFileList {
	my ($self,$dir) = @_;
#	return build_file_list(BASE_DIR => $dir, EXCLUDE_DEFAULTS => 1, STRIP_BASE_DIR => 1);
	return io->dir($dir)->all(0);
}

sub _cleanDir {
	my ($self,$dir) = @_;
	IO::All->new()->dir($dir)->rmtree();
}

1;


__END__

=head1 NAME

War - Dilettante war packager module

=head1 DESCRIPTION

B<NOTE:> Jar.pm now includes the same functionality, this module is no longer maintained since you can do the same thing via
Jar:war.

War constructs java web archives. It performs the same actions as the Jar module except it first reassembles the artifacts into
the format required by war archives. It does this by creating a directory under build.target, locating build.target/WEB-INF and 
copying it under this new directory, adding a classes subdirectory, copying build.target.classes to this directory, and creating
a jar from the result. This jar is named as with a standard jar, but with the extension .war instead of .jar. 

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
