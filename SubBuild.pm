package SubBuild;

use strict;
use base qw(Step);
use Builder;
use Cwd;

sub execute {
	my ($self) = @_;
	
	my $step = $self->builder()->getStep();
	my $abort = eval { $self->builder()->getScalarProperty("$step.haltonfail"); };
	$abort ||= 'true';
	my $setdir = eval { $self->builder()->getScalarProperty("$step.builddir"); };
	$self->error("$setdir directory does not exist") if($setdir ne '' && ! -d $setdir);
	my $curdir = getcwd();
	$self->debug("Setting directory to $setdir");
	if($setdir ne '') {
		chdir($setdir);
	}

	my $predefs = $self->_setPredefs();
	my $postdefs = $self->_setPostDefs();
	my $builder = Builder->new();
	$builder->init('predefine' => $predefs, 
		'postdefine' => $postdefs );
	$self->debug("Going to execute subbuild with abort $abort, dir $setdir");
	eval { $builder->execute(); };
#print "GOT HERE\n";
	$builder->writeProps();
	if($abort eq 'true' && $builder->getReturnValue() != 0) {
		$self->error("Subbuild failed");
	} elsif($builder->getReturnValue() == 0) {
		$self->info("Subbuild executed")
	} else {
		$self->warn("Subbuild failed, continuing parent build");
	}
	if($setdir ne '') {
		chdir($curdir);
	}
}

sub fork {
	my ($self) = @_;
	
	my $step = $self->builder()->getStep();
	my $predefs = $self->_setPredefs();
	my @args;
	foreach my $predef (keys(%$predefs)) {
		push(@args,"-D $predef=$predefs->{$predef}");
	}
	my $builderbin = $self->genPath($self->getProperty('builder.lib')."/builder.pl");
	my $abort = eval { $self->getScalarProperty("$step.haltonfail"); };
	my $setdir = eval { $self->getScalarProperty("$step.builddir"); };
	my $curdir = getcwd();
	if($setdir ne '') {
		chdir($setdir);
	}
	if($abort eq 'true') {
		$self->error("Forked subbuild failed")
			if system($builderbin,@args);
	} else {
		$self->warn("Forked subbuild failed")
			if system($builderbin,@args);
	}
	if($setdir ne '') {
		chdir($curdir);
	}
}

sub _setPredefs {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $buildfile = $self->genPath($self->builder()->getProperty("$step.properties"));
	$self->debug("Predefs build file is $buildfile");
	my %predefs;
	$predefs{'builder.config.module'} = $buildfile;

# subprops are parent build properties which are passed down to the subbuild
	my $subprops = eval { $self->builder()->getProperty("$step.subproperties"); };
	if(defined $subprops) {
		$subprops = ref($subprops) ? $subprops : [ $subprops ];
		foreach my $subprop (@$subprops) {
			my $sbvalue = $self->builder()->getProperty($subprop);
			my @sbvalues = ref($sbvalue) ? @$sbvalue : [ $sbvalue ];
			foreach my $subvalue (@sbvalues) {
				$predefs{$subprop} = $subvalue;
			}
		}
	}
	return \%predefs;
}

use Data::Dumper;

sub _setPostDefs {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	$self->debug("Postdefs being defined");
	my %postdefs = ( '-build.output.properties' => $self->builder()->getScalarProperty('build.target')."/$step-output.properties" );

# addprops are added p=v pairs supplied by $step.addproperties which are predefed into the subbuild
	my $addprops = eval { $self->builder()->getProperty("$step.addproperties"); };
	if(defined $addprops) {
#print "ADDING PROPERTIES\n";
		$addprops = ref($addprops) ? $addprops : [ $addprops ];
		foreach my $addprop (@$addprops) {
#print "FOUND ADDPROPERTY $addprop\n";
			$addprop =~ /([^=]*)=(.*)/;
			my $pname = $1;
			my $pvalue = $2;
#print "ADDING $pname=$pvalue\n";
			$postdefs{$pname} = $pvalue;
		}
	}
#print "WHAT ARE THE POSTDEFS ".Dumper(\%postdefs)."\n";
	return \%postdefs;
}

1;


__END__

=head1 NAME

SubBuild - Dilettante execute sub build.

=head1 DESCRIPTION

SubBuild is a module which provides an action to initiate a separate execution of Builder within the current build script. The
default action constructs a separate Builder and executes it. Using the fork action initiates a completely separate execution of
build.pl. Any values present in the property <step>.subproperties are automatically predefined in the subbuild. The subbuild's
module level properties file is indicated by <step>.properties. 

If <step>.haltonfail has a value of 'true' the master build will halt if the subbuild reports failure. If <step>.builddir has a
value the subbuild will chdir() to the directory indicated by this property value before executing. 

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
