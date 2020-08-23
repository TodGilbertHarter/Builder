package Macro;

use strict;
use base qw(Step);

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $actions = $self->genPath($self->builder()->getScalarProperty("macro.$step.actions"));
	my @actions = split(/;/,$actions);
	my $halt = eval { $self->builder()->getScalarProperty("macro.$step.halt"); };
	for my $action (@actions) {
		my ($package,$method) = split(/:/,$action);
		$self->builder()->performAction($package,$method);
		$self->builder()->{'halt'} = 0 if $halt eq 'false';
		$self->error("Macro $step halting due to error in action $action") if $self->builder()->getHalt();
	}
	$self->debug("Macro $step successfully performed");
}

sub doSteps {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $steps = $self->genPath($self->builder()->getScalarProperty("macro.$step.steps"));
	my @steps = split(/;/,$steps);
	my $halt = eval { $self->builder()->getScalarProperty("macro.$step.halt"); };
	for my $step (@steps) {
		$self->builder()->executeStep($step);
		$self->builder()->{'halt'} = 0 if $halt eq 'false';
		$self->error("Macro $step halting due to error in step $step") if $self->builder()->getHalt();
	}
	$self->debug("Step macro $step successfully performed");
	$self->builder()->{'step'} = $step;
}

1;

__END__

=head1 NAME

Macro - Dilettante macro module

=head1 DESCRIPTION

Macro allows steps to be defined in terms of other steps. This can simplify the construction of build files
and allow common sequences of operations to be specified in one location.

Common use cases would include setting up test fixtures and complex product-level archives.

=head1 CONFIGURATION

A macro definition consists of a step name and a macro.$step property which defines the sequence of actual
steps (or other macros) which make it up.

step.mymacro=Macro
macro.mymacro.actions=Assemble:CopyFiles;Filter;Test
filter.mymacro.include=.*\.xml
filter.mymacro.source=${build.dir}/src/main/stuff
filter.mymacro.target=${build.target}/stuff

The above example would define a new step 'mymacro' which would invoke the given defined set of actions. The
effective step name for all of these actions will be 'mymacro', thus other config properties required by the
actions defined in the Macro can be assigned as needed, for example the filter action above would include all
files ending with '.xml' in src/main/stuff relative to ${build.dir} and filter them into a stuff directory
under ${build.target}.

Another variation is provided, which may in some cases be more useful, the 'step macro'. A step macro is defined as
follows:

step.mymacro=Macro:doSteps
macro.mymacro.steps=testcompile;testresources;test
filter.testresources.include=.*\.xml
filter.testresources.source=${build.dir}/src/main/stuff
filter.testresources.target=${build.target}/stuff

In this case instead of executing a series of actions as a SINGLE step, the macro consists of a series of already defined
steps. This type of macro Effecively this is identical to doing property substitutions into the build.steps property
except since the macro has a step name it is possible to do things like set build.stopat=mymacro.

Both variations allow special halt handling. If the property macro.$step.halt is set to 'false', then the builder halt
flag will be ignored and it's state will be reset after all steps/actions complete. Thus it is possible to construct a
macro which will execute all of its steps/actions and continue even in the event of an error. This is highly useful in
cases where certain errors are 'nonfatal' but not others (setting the build.continue property true ignores ALL errors).

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
