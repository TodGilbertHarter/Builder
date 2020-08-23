package Jar;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;
	my $jarfile = $self->builder()->getScalarProperty('build.target')."/"
		.$self->builder()->getScalarProperty('build.artifactid')."-"
		.$self->builder()->getScalarProperty('build.version').".".$self->builder()->getScalarProperty('build.packaging');
	$jarfile = $self->genPath($jarfile);
	my $basedir = $self->genPath($self->builder()->getScalarProperty('build.target.classes'));
	my $jarprog = $self->genPath($self->builder()->getScalarProperty('jar.jarprogram'));
	my $propfile = $self->_buildManProps();
	$self->error("Failed to create jar file")
		if(system($jarprog,'cmf',$propfile,$jarfile,'-C',$basedir,'.'));
	$self->info("Constructed jar $jarfile");
}

sub _buildManProps {
	my ($self) = @_;
	my $manprops = $self->getProperty("manifest.property");
	$manprops = ref($manprops) ? $manprops : [ $manprops ];
	my $target = $self->getScalarProperty('build.target');
	my $fh = io("$target/manifest.props");
	for my $manprop (@$manprops) {
		$fh->print("$manprop\n");
	}
	return "$target/manifest.props";
}

sub war {
	my ($self) = @_;

	my $wardir = $self->genPath($self->builder()->getScalarProperty('build.target')."/"
		.$self->builder()->getScalarProperty('build.artifactid')."-"
		.$self->builder()->getScalarProperty('build.version'));
	my $warfile = $wardir.".".$self->builder()->getScalarProperty('build.packaging');
	my $classesdir = $self->genPath($self->builder()->getScalarProperty('build.target.classes'));
#	$self->_cleanDir($wardir);
	eval {
		io->dir($wardir)->mkdir();
	};
#	rename($self->genPath($self->builder()->getProperty('build.target')."/WEB-INF"),"$wardir"); # /WEB-INF");
#	rename($classesdir,$self->genPath("$wardir/WEB-INF/classes"));
	$self->_copyTree($self->genPath($self->builder()->getScalarProperty('build.target')."/WEB-INF"),"$wardir",undef);
	if(-d $classesdir) {
		$self->_copyTree($classesdir,$self->genPath("$wardir/WEB-INF/classes"),undef);
	}
	my $filelist = $self->_makeFileList($wardir);
	my $jarprog = $self->genPath($self->builder()->getScalarProperty('jar.jarprogram'));
	my $propfile = $self->_buildManProps();
	$self->error("Failed to create war file")
		if(system($jarprog,'cmf',$propfile,$warfile,'-C',$wardir,'.'));
	$self->info("Constructed war $warfile");
}

sub mkEar {
	my ($self) = @_;
	
	my $step = $self->getStep();
	my $jarprog = $self->genPath($self->builder()->getScalarProperty('jar.jarprogram'));
	my $earfile = $self->genPath($self->builder()->getScalarProperty("jar.$step.earfile"));
	my $eardir = $self->genPath($self->builder()->getScalarProperty("jar.$step.eardir"));
	my $propfile = eval { $self->getScalarProperty("jar.$step.manifest"); };
	$propfile = "$eardir/META-INF/MANIFEST.MF" unless defined $propfile;
	$propfile = $self->genPath($propfile);
	$self->error("Failed to create ear file")
		if(system($jarprog,'cmf',$propfile,$earfile,'-C',$eardir,'.'));
}

sub ear {
	my ($self) = @_;

	my $eardir = $self->genPath($self->builder()->getScalarProperty('build.target')."/"
		.$self->builder()->getScalarProperty('build.artifactid')."-"
		.$self->builder()->getScalarProperty('build.version'));
	my $earfile = $eardir.".".$self->builder()->getScalarProperty('build.packaging');
	my $classesdir = $self->genPath($self->builder()->getScalarProperty('build.target.classes'));
#	$self->_cleanDir($eardir);
	eval {
		io->dir($eardir)->mkdir();
	};
	rename($self->genPath($self->builder()->getScalarProperty('build.target')."/META-INF"),"$eardir/META-INF");
	rename($classesdir,$self->genPath("$eardir/META-INF/classes"));
	my $filelist = $self->_makeFileList($eardir);
	my $jarprog = $self->genPath($self->builder()->getScalarProperty('jar.jarprogram'));
	my $propfile = $self->_buildManProps();
	$self->error("Failed to create ear file")
		if(system($jarprog,'cmf',$propfile,$earfile,'-C',$eardir,'.'));
	$self->info("Constructed ear $earfile");
}

sub sourceJar {
	my ($self) = @_;

	my $jarfile = $self->builder()->getScalarProperty('build.target')."/"
		.$self->builder()->getScalarProperty('build.artifactid')."-source-"
		.$self->builder()->getScalarProperty('build.version').".jar";
	$jarfile = $self->genPath($jarfile);
	my $basedir = eval { $self->getScalarProperty('jar.source'); };
	if($basedir eq '') {
		$basedir = $self->genPath($self->builder()->getScalarProperty('build.source'));
	}
	my $tdir = $self->builder()->getScalarProperty('build.target')."/sjtmp";
	$self->_copyTree($basedir,$tdir);
	my @files =  $self->_makeFileList($tdir);
	foreach my $d (@files) {
		if($d =~ /.*\.svn$/) {
			$self->_cleanDir($d) if -d "$d";
#			$self->_cleanDir($d);
		}
	}
	my $extradir = eval { $self->getScalarProperty('jar.extrasource'); };
	if($extradir ne '') {
		$extradir = $self->genPath($extradir);
		$self->_copyTree($extradir,$tdir);
		@files = $self->_makeFileList($tdir);
		foreach my $d (@files) {
			if($d =~ /.*\.svn$/) {
				$self->_cleanDir($d) if -d "$d";
			}
		}
	}

	my $jarprog = $self->genPath($self->builder()->getScalarProperty('jar.jarprogram'));
	$self->error("Failed to create jar file")
		if(system($jarprog,'Mcf',$jarfile,'-C',$tdir,'.'));
	$self->info("Constructed jar $jarfile");
}

sub testJar {
	my ($self) = @_;

	my $jarfile = $self->builder()->getScalarProperty('build.target')."/"
		.$self->builder()->getScalarProperty('build.artifactid')."-tests-"
		.$self->builder()->getScalarProperty('build.version').".jar";
#		.$self->builder()->getScalarProperty('build.version').".".$self->builder()->getScalarProperty('build.packaging');
	$jarfile = $self->genPath($jarfile);
	my $basedir = $self->genPath($self->builder()->getScalarProperty('build.target.testclasses'));
	my $jarprog = $self->genPath($self->builder()->getScalarProperty('jar.jarprogram'));
	$self->error("Failed to create jar file")
		if(system($jarprog,'cf',$jarfile,'-C',$basedir,'.'));
	$self->info("Constructed jar $jarfile");
}

sub _makeFileList {
	my ($self,$dir) = @_;
	return io->dir($dir)->all(0);
}

sub _cleanDir {
	my ($self,$dir) = @_;
# IO::All shits itself here.
#	IO::All->new()->dir($dir)->rmtree();
# OK, so obviously File::Path::rmtree is poop
#	File::Path::rmtree($dir);
	system('rm','-r','-f',$dir); # luckily we can do things the brute force way...
}

1;


__END__

=head1 NAME

Jar - Dilettante Jar packager action

=head1 DESCRIPTION

The Jar module constructs Java .jar archives containing object code and/or other output resources. It does this by simply
invoking the sun jar tool and providing it with a list of files containing the contents of the 'build.target.classes'
directory, with some common types exclusions for cvs, svn, hidden (IE ".") files, and editor backup files. The output jar is
placed in 'build.target' with the name being constructed as ${build.artifactid}-${build.version}.${build.packaging}.

A secondary action is also provided which operates in a similar fashion but produces an output file with a '.war' extension. This
version also packages the additional directory 'WEB-INF' from 'build.target' and places classes under 'WEB-INF/classes' in order
to conform with the war file specification.

A testJar action packages tests from build.target.testclasses. The resulting archive is named
${build.artifactid}-tests-${build.version}.${build.packaging}

Finally there is an ear action. This is almost identical to the war action except for the placement of files in META-INF.

All actions will construct a MANIFEST.MF file which includes additional properties extracted
from the values of the manifest.property property. Values should be added to this property in
order to customize the manifest output.

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
