package Filter;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $include = eval { $self->builder()->getProperty("filter.$step.include"); };
	$include ||= ".*";
	$include = ref($include) ? $include : [$include];
	my $dir = eval { $self->builder()->getScalarProperty("filter.$step.dir"); };
	$dir = $self->genPath($dir);
	return unless $dir;
	my $target = $self->builder()->getScalarProperty("filter.$step.target");
	$target = $self->genPath($self->builder()->getScalarProperty('build.target.classes')) if $target eq '';
	$self->builder()->debug("Filtering resources from $dir to $target\n");
	eval {
		io($target)->mkdir();
	};
	my @dirs;
	if(ref($dir)) {
		@dirs = @$dir;
	} else {
		push(@dirs,$dir);
	}
	foreach my $cdir (@dirs) {
		my @files = io($cdir)->all(0);
		foreach my $file (@files) {
			my $flag = 0;
			foreach my $i (@$include) {
				$flag = 1 if $file =~ /$i/;
			}
			$flag = 0 if $file =~ /\.svn/;
			if($flag) {
				my $fbase = $self->_prunePath($cdir,$file);
				$self->_processFile($fbase,$cdir,$target);
			}
		}
	}
}

sub _processFile {
	my ($self,$file,$sourcedir,$targetdir) = @_;

	my $step = $self->builder()->getStep();
	my $filterflag = eval { $self->builder()->getProperty("filter.$step.filter"); };
	$self->_makeDirs($file,$targetdir);
	if(-f $sourcedir.$file) {
		my $infh = io($self->genPath($sourcedir.$file));
		$self->builder()->error("Filter cannot open $sourcedir/$file for reading: $@") unless $infh;
		$self->debug("Opened resource file $infh");
		my $outfh = io($self->genPath("$targetdir/$file"));
		$self->builder()->error("Filter cannot open $targetdir/$file for writing: $@") unless $outfh;
		$self->debug("Opened target file $outfh");
		while(my $sline = $infh->getline()) {
			my $oline = $sline;
			$oline = eval { $self->builder()->doPropertySubstitution($sline); } unless $filterflag eq 'false';
			$self->builder()->warn("Failed to filter variable at line $sline in $file\n") if $@;
			$outfh->print($oline);
		}
		$infh->close();
		$outfh->close();
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
			$self->debug("Making resource dir $path/$tdir");
			io("$path/$tdir")->mkdir();
		}
		$path .= "/$tdir";
	}
	$self->debug("Created resource dirs");
}

1;


__END__

=head1 NAME

Filter - Dilettante resource filtering action

=head1 DESCRIPTION

Filter processes text files and performs property substitutions on them. It scans each directory in the values of 
filter.<step>.dir and selects all files matching the regex filter.<step>.include. Each matching file is scanned for
all occurances of the pattern ${name} and this is replaced with the correspondingly named property value. The file is then
written to 'filter.<step>.target'. Subdirectories of each scanned directory are constructed under the target to produce
a corresponding directory structure.

Thus if Filter is executed in a step named 'resources' filter.resources.dir=foo and foo contains a subdirectory bar, 
which contains a file baz.xml and 
filter.resources.include=*.xml then the target directory will contain a subdirectory bar containing a file baz.xml who's contents
are the result of filtering foo/bar/baz.xml.

=head2 CONFIGURATION

Several properties control execution.

=over 4

=item filter.<step>.dir

Each value of this property is a directory which will be scanned for resources to be filtered.

=item filter.<step>.include

Each value of this property represents a regex to match against file names in scanned directories.

=item filter.<step>.target

Location for the output to be placed. Typically this might be 'build.target.classes' to put resources into a jar along with
compiled class files, etc. Various other action modules expect or can be configured to utilize filtered files placed in any
desired location. Generally it is best to keep these within the 'target' directory since they are by definition generated
data which is subject to change from build to build.

=item filter.<step>.filter

Set to false to copy without filtering.

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
