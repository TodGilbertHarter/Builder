package Compile;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $sourcedir = $self->builder()->getScalarProperty('build.source');
	$self->info("Compiling classes from $sourcedir");
	my $flags = eval { $self->builder()->mergePropertyValues('compile.flags',' '); };
	my $classpath = $self->builder()->generateClassPath(0);
	my $classpathtwo = eval { $self->builder()->getProperty('compile.addclasspath'); };
	$classpath .= ":$classpathtwo" if $classpathtwo;
	my $destination = $self->builder()->getScalarProperty('build.target.classes');
	my $compiler = $self->builder()->getScalarProperty('compile.compiler');
	$self->error("Compilation failed") if
		$self->_compile($sourcedir,$flags,$classpath,$destination,$compiler);
}

sub testCompile {
	my ($self) = @_;

	my $cpsep = $^O=~ /MSWin32/ ? ';' : ':';
	my $sourcedir = $self->builder()->getScalarProperty('build.testsource');
	$self->info("Compiling test classes from $sourcedir");
	my $flags = eval { $self->builder()->mergePropertyValues('compile.flags',' '); };
	my $classpath = $self->builder()->generateClassPath(1);
	$classpath .= "$cpsep".$self->builder()->getScalarProperty('build.source');
	my $classpathtwo = eval { $self->builder()->getProperty('compile.addclasspath'); };
	$classpath .= ":$classpathtwo" if $classpathtwo;
	my $destination = $self->builder()->getScalarProperty('build.target.testclasses');
	my $compiler = $self->builder()->getScalarProperty('compile.compiler');
	$self->error("Test compilation failed") if
		$self->_compile($sourcedir,$flags,$classpath,$destination,$compiler);
}

sub stepCompile {
	my ($self) = @_;

	my $cpsep = $^O=~ /MSWin32/ ? ';' : ':';
	my $step = $self->builder()->getStep();
	my $sourcedir = $self->builder()->getScalarProperty("build.$step.source");
	my $flags = eval { $self->builder()->mergePropertyValues('compile.flags',' '); };
	my $classpath = $self->builder()->generateClassPath(0);
	$classpath .= "$cpsep".$self->builder()->getScalarProperty("build.$step.source");
	my $destination = $self->builder()->getScalarProperty("build.$step.target.classes");
	my $compiler = $self->builder()->getScalarProperty('compile.compiler');
	$self->error("$step compilation failed") if
		$self->_compile($sourcedir,$flags,$classpath,$destination,$compiler);
}

# invoke javac to compile classes
sub _compile {
	my ($self,$sourcedir,$flags,$classpath,$destination,$compiler) = @_;

	$self->debug("Compiling to $destination");
	my @s = io($sourcedir)->all(0);
	@s = grep /.*\.java$/, @s;
	my @sources;
	foreach my $sourcename (@s) {
		push(@sources,$self->genPath($sourcename));
	}
	$self->debug("Compiling @sources");
	return 0 if @sources == 0; # nothing to compile...
#	my $sources = join(' ',@sources);
	my @flags = split(' ',$flags);
	if($classpath ne '') {
		push(@flags,'-cp');
		push(@flags,$classpath);
	}
	$destination = $self->genPath($destination);
	$compiler = $self->genPath($compiler);
	mkdir($destination);
	push(@flags,'-d');
	push(@flags,$destination);
	$self->debug("Compiling with $compiler @flags @sources");
	return system($compiler,@flags,@sources);
}

1;

__END__

=head1 NAME

Compile - Dilettante Java compilation build step

=head1 DESCRIPTION

Compile invokes the standard javac compiler. There are 3 action methods, the default execute() action is intended to compile
module product code, and testCompile() is intended to compile test support code which will not become part of the actual
product itself (IE JUnit test cases etc). For other possible situations stepCompile() can be mapped to a step and invoked. This
will allow build.<step>.source and build.<step>.target.classes properties to be used to control the source and output
directories.

All builds use the same compile flags and compiler executeable. This should generally give the desired results. The testCompile()
method will include the 'test' scope depdendencies in the compile path, the other variations will not. Again this is generally
the desirable setup.

=head2 CONFIGURATION

=over 4

=item build.source
Directory where all source code resides. Any *.java file will be compiled. This is passed to javac as the argument list. This is
used in the default execution.

=item build.testsource
Directory where test sources reside. This works the same as build.source but is used when invoked via testCompile().

=item compile.flags
Flags to be passed to the javac compiler. These should be separated with spaces. Multiple values will be merged.

=item compile.compiler
The actual command to execute via system() in order to perform compilation.

=item build.target.classes
The output directory where .class files will be placed. By default this would be target/classes under the current working directory.

=item build.target.testclasses
The output directory where .class files will be placed during test compilation. Normally target/test-classes.

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
