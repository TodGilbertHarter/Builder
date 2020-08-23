#!/usr/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin";
# use lib "/mnt/deltaopt/development/builder";
use Builder;
use Getopt::Long;
my %predefines;
my %postdefines;
my %replacements;
my $nowrite = '';
my $commandline =  GetOptions("P=s" => \%predefines, "D=s" => \%postdefines, "R=s" => \%replacements, "N" => \$nowrite);
foreach my $rk (keys %replacements) {
	$postdefines{"-$rk"} = "$replacements{$rk}";
}
my $properties = $ARGV[0];
$properties ||= $ENV{BUILDER_CONFIG_MODULE};
$properties ||= 'build.properties';
$predefines{'builder.config.module'} = $properties unless defined $predefines{'builder.config.module'};
my $builder = Builder->new();
$builder->init('predefine' => \%predefines, 'postdefine' => \%postdefines);
eval { $builder->execute(); };
#$builder->execute();
$builder->writeProps() unless $nowrite;
exit($builder->getReturnValue());

__END__

=head1 NAME

Dilettante - Complex project builder

=head1 SYNOPSIS

./build.pl -D foo=bar -D baz=bazooka -P fuzz=bumble -R build.target.classes [propfile]

=head1 DESCRIPTION

Dilettante is a tool for building complex software projects. It provides many of the
features of commercial build tools and combines them with the power and flexibility of
perl scripting.

Builds are controlled by use of one or more properties files. A properties file defines
the steps required to perform build actions, the order of execution of steps, and what
code module will be used to execute each step. It supports several fairly sophisticated
features in order to accomodate large and complex build structures.

=head1 USAGE

build.pl executes a build process controlled by properties. By default build.properties is the
module level properties file used. An alternate can be specified on the command line. See below
for other ways to specify what file is used.

=head1 OPTIONS

=over 4

=item -D key=value
Define one or more properties directly from the command line. 

=item -P key=value
Define one or more properties directly from the command line B<before> normal property processing.

=item -R key=value
Remove one or more properties. This always happens at the B<end> of property processing.

=item -N
Suppress writing the output.properties file

=item --help
Output basic help info on this script.

=item --man
Output extensive documentation on this script.

=item --license
Output license information on this script.

=back

=head1 CONFIGURATION

Dilettante is controlled via properties files. There are four properties files which will be
consulted in order to configure a build, as well as some other sources, in this order:

=over 4

=item Defaults built in configuration

There are a small number of configuration properties which are built in to the Builder class and
will always be defined before any other processing takes place.

=item Global global configuration

Global configuration is held in a file config.properties which is found in the Dilettante library
install location. This location can be overridden via the BUILDER_GLOBAL_CONF environment variable.

=item Local local configuration

Local configuration is held in a file config.properties which is found in the ~/builder directory.
This location can be overridden via the BUILDER_LOCAL_CONF environment variable. 

=item Project project configuration

Project configuration is held in a file build.properties which is always searched for in the parent
of the current working directory. This location can be overridden via the BUILDER_CONFIG_PROJECT
environment variable.

=item Module module configuration

Module level configuration is held in a file build.properties in the current working directory.
This can be overridden via the BUILDER_CONFIG_MODULE environment variable. Optionally a single command
line parameter can be used to specify this file.

=back

In addition it is possible to modify the configuration via the D,P, and R command line switchs.

=head2 Properties syntax

Property files have a fairly straightforward conventional syntax, but with some added features and
flexibility. Each properties file contains one entry per line. Blank lines or lines who's first non-whitespace
character is # are comments and will be ignored. All other lines must start with a non-whitespace character and
contain a name=value pair, or start with a directive.

Names consist of non-whitespace characters and must begin with an alphanumeric character, and may not contain
an equals. Values may consist of anything except newlines or equals. Naturally line breaks cannot be placed in
either names or values.

Lines of the form Include=<filepath> act as an include directive. This will cause the file at <filepath> to be 
incorporated directly by reference into the containing properties file as if the contents of <filepath> appeared at that point.

The other directives are one of 2 special characters, '!' and '-' (minus). A directive is followed by a name and generally
also by a value. Directives are used to achieve special configuration effects. The '!' directive instructs the
properties parser to B<DELETE> a property value. If a specific value is supplied (IE a name=value pair follows '!')
only that particular value will be removed. If the value is replaced with '*', all values for that property will
be removed (the entire property will become undefined, as if it had never been encountered). 

The '-' directive B<REPLACES> a property value. Any or all existing values for this property will be replaced. Thus
if the property was multi-valued it will become a single valued property with the new value. The same effect can
be achieved via the !name=* directive followed by adding a new definition for the same property name.

Property substitution is supported via the syntax ${name} construct. This may appear anywhere in any value and
will be replaced by the B<CURRENT> value of the property with this name at the point in the parsing process where
the variable is encountered. Only single-valued properties are currently supported as sources of substitution
values.

=head2 Properties structure

Dilettante merges all properties from all configuration sources into a single properties structure, which is
used to control its activities. This structure is in the form of a tree. Defining a property name which contains
'.' (dot) characters actually constructs a PATH of properties where each dot delimited element is a property and
the element following it is a child. Properties may have any number of children. Properties may also have one or
more values. Additional definitions of a property will add values to any which already exist.

The root of the tree is an unnamed property which is implicit, thus all properties exist within a single tree.
Each property is represented as a ValueNode instance. The root property is a Properties instance, which is a
ValueNode with additional functionality which allows easy management of the entire tree. The Builder class also
provides some convenience functions for accessing its attached Properties instance.

The Builder maintains a single Properties structure which is used to control and configure all build actions. Some
actions also attach additional properties or values during the course of a build.

=head2 PATH SPECIFICATION

Dilettante internally represents all file system paths in 'UNIX style', that is paths are constructed using a
path separator of '/', and indicating an absolute path with an initial '/'. Mixed paths (for example components which
are in Windows path style) should be correctly processed during an execution of build.pl, but they will not necessarily
function correctly on other platforms. Path conversion to the current OS style will be performed (via the genPath() function
of Builder.pm). This works, but there is currently no way to conditionalize setting property values. Action modules
should be constructed with this factor in mind. Any path used/generated within an action module should be passed to
genPath() before use. In some cases this may create situations where an alternative version of a property file will
be required on different platforms. Some mechanism to deal with this eventuality should be provided in future releases.

=head1 ACTIONS

Dilettante performs all of its functions via actions. Each action is a perl class. Actions always have an execute()
method which performs the default behaviour of the action. They may in addition have other methods which can be
invoked to perform other related functions. Actions are configured via the step property and invoked via the
build.steps property.

The step property is a property who's child properties each define an available action. The names of the child properties
are the available action names. The values of the child properties are action bindings. An action binding consists of
a module (class) name and optionally a colon followed by a method name. If no method name is provided then the default
execute() method will be assumed.

The build.steps property defines which action names will be invoked. The value of this property is a comma-separated list
of action names. If multiple values exist for build.steps they will be merged in order of definition. Each action will be
executed in the order defined by looking up a child of the steps property with the name of the action. The corresponding
module will be required, an instance will be constructed via it's new() method, and the method named in the binding (or
the default execute() method) will be called and passed the builder instance as its only argument.

=head1 BUILDER CLASS

The L<Builder> module implements most of the core functionality of Dilettante. There are a number of functions built into
this class which can be utilized by action modules. See L<Builder> for detailed documentation on the various functions
which are available.

=head1 MODULE STRUCTURE

A module is a unit of code or other resources which Dilettante will act upon during a build invocation. Each module
build generally results in the production of one or more artifacts. Modules can also represent other build processes
such as integration of submodules, functional testing setups, etc. Unlike with some other build tools which rigidly
define the relationships and responsibilities of modules, Dilettante does not require a particular correspondence
between modules and units of object code or deployable products. However good practice dictates that some conventions
should be followed.

=head2 CONVENTIONS

Dilettante can be configured in any desired fashion, however the default and supplied global configurations are designed
to provide a fairly standardized build setup. This build setup is layed out in a manner intended to follow the conventions
utilized by Maven 2.x. This facilitates migration between the two build tools and utilization of both tools for specific
purposes if desired. Thus all the supplied Dilettante configuration defines a structure in which a directory 'src' contains
all module source, and a directory 'target' is used as the location where all artifacts (object code etc) will be
placed. The src directory is further defined to contain a 'main' subdirectory containing the sources for the primary
product source code, and a 'test' directory contains source etc utilized during testing. Subdirectories of src/main are
used to hold various types of source material. So for example src/main/java contains java code, src/main/perl contains
perl code, etc. Similarly src/test/java would contain java test code (JUnit test cases for example), while src/test/perl
might contain perl test harness scripts.

When designing new actions these conventions should be maintained by use of appropriate properties. Any kind of output should
generally be directed into target, etc. If conventions already exist for a corresponding Maven 2.x Mojo, it is advisable to
provide the same structure and organization whenever possible.

=head2 CUSTOMIZATION

In order to produce a module structure different from the default certain factors must be taken into account. The primary
consideration is that the builder performs property substitutions in the order they are encountered, and most of the
properties which define the module structure are defined early in the process. Thus, while it is possible to redefine this
structure in a project or module level properties file, it will usually require replacing numerous existing properties which
depend on the values of others defined earlier. For this reason, and simply because build consistency is a good thing, it
is best to perform these redefinitions in the global config.properties file. This has the benefit of insuring that all modules
operate under the same conventions.

=head2 PROJECT STRUCTURE

In any non-trivial project it will be necessary to break the project down into multiple modules in order to create a manageable
structure. Dilettante provides the project level configuration in order to facilitate sharing of information between the builds
for multiple modules making up a single project. Different development activities can also be segmented up between modules 
designed for various purposes. For example integration testing could be segregated into it's own module. Top level building
or product packaging etc could also be additional modules, or higher level 'superprojects'. Additionally the Builder can be
integrated with other logic in custom build scripts for increased flexibility as desired.

=head1 CUSTOMIZED BUILDERS

In some cases it may be simpler to invoke certain builder functions in ways that are not readily expressed via build.steps, or
some one-time process is desired which needs to take some actions not covered by an action. Builder.pm can be incorporated directly
into a script and its functionality, or the functionality of different steps, can be easily accessed directly. Using the init()
function of Builder in these cases is highly recommended since it will provide a consistent configuration to base build activity
on. An example is the L<reposcan> script for scanning Maven 2 repositories and building .dependency files from POM data.

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
