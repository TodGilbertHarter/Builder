package Builder;

# dilettante

use strict;
use IO::File;
use Fcntl qw(:DEFAULT);
use Properties;
use Cwd;
use vars qw($_property_defaults $PSEP);
use Carp;

# determine OS specific path separator for use by genPath
$PSEP = $^O=~ /MSWin32/ ? "\\" : '/';

$_property_defaults = [
	'builder.home'				=> my_home(),
	'builder.lib'				=> $ENV{BUILDER_GLOBAL} || '/mnt/deltaopt/development/builder',
	'builder.config.global'		=> $ENV{BUILDER_GLOBAL_CONF} || '${builder.lib}/config.properties',
	'builder.config.local'		=> $ENV{BUILDER_LOCAL_CONF} || '${builder.home}/builder/config.properties',
	'builder.config.project'	=> $ENV{BUILDER_CONFIG_PROJECT} || '../build.properties',
#	'builder.config.module'		=> $ENV{BUILDER_CONFIG_MODULE} || 'build.properties',
	'build.source'				=> 'src/main/java',
	'build.target'				=> '${build.basedir}/target',
	'build.target.classes'		=> '${build.target}/classes',
	'build.output.properties'	=> '${build.target}/output.properties',
	'build.testsource'			=> 'src/test/java',
#	'build.target.testclasses'	=> '${build.target}/test-classes',
	'build.target.testclasses'	=> '${build.target}/test-classes.bld',
	'build.target.testreports'	=> '${build.target}/test-reports',
	'build.loglevel'			=> 'info',
	'build.time'				=> time(), 
	];

# return some reasonable value for a user specific directory regardless of OS.
sub my_home {
	if($^O =~ /MSWin32/) {
		if ( $ENV{USERPROFILE} ) { return $ENV{USERPROFILE}; }
		if ( $ENV{HOMEDRIVE} and $ENV{HOMEPATH} ) {
				return io()->catpath( $ENV{HOMEDRIVE}, $ENV{HOMEPATH}, '',);
		}
	} else {
		return $ENV{HOME};
	}
	Carp::croak("Could not locate current user's home directory");
}

sub new {
	my ($caller) = @_;
	my $class = ref($caller);
	$class ||= $caller;
	my $self = bless({},$class);
	$self->{'returnvalue'} = 0;
	$self->{'properties'} = Properties->new();
	$self->{'cleanups'} = [];
	return $self;
}

sub init {
	my ($self, %arg) = @_;

	if($arg{'predefine'} != undef) {
		foreach my $key (keys(%{$arg{'predefine'}})) {
			$self->addProperty($key,$arg{'predefine'}->{$key});
		}
	}
	$self->addProperty('build.basedir',getcwd());
	my @pdtemp = (@$_property_defaults);
	while(my $key = shift(@pdtemp)) {
		my $value = shift(@pdtemp);
		$self->addProperty($key,$value);
	}
	$self->readProjectConfig();
	if($arg{'postdefine'} != undef) {
		foreach my $key (keys(%{$arg{'postdefine'}})) {
			$self->addProperty($key,$arg{'postdefine'}->{$key});
		}
	}
	mkdir($self->getScalarProperty('build.target'));
	$self->{'loglevels'} = {debug => 1, info => 2, warn => 3, error => 4};
	$self->{'loglevel'} = $self->{'loglevels'}->{$self->getScalarProperty('build.loglevel')};
	$self->{'step'} = 'initialization';
	$self->info("Builder initialized");
	return $self;
}

sub genPath {
	my ($self,$path) = @_;
	$path = $path ? $path : $self; # allow static call
	$path =~ s|/|$PSEP|ge;
	return $path;
}

sub debug {
	my ($self,$message) = @_;
	$self->_log(1,"DEBUG:",$message);
}

sub info {
	my ($self,$message) = @_;
	$self->_log(2,"INFO:",$message);
}

sub warn {
	my ($self,$message) = @_;
	$self->_log(3,"WARN:",$message);
}

sub error {
	my ($self,$message) = @_;
	$self->{'returnvalue'} = -1;
	$self->{'halt'} =1 unless eval { $self->getProperty('builder.continue') eq 'true'; };
	$self->_log(4,"ERROR:",$message);
	confess($message);
}

sub _log {
	my ($self,$level,$lstr,$message) = @_;
	if($self->{'loglevel'} <= $level) {
		my $line = sprintf("%15s-> %7s %s\n",$self->{'step'},$lstr,"$message");
		print $line;
		$self->{'log'} = [] unless defined $self->{'log'};
		push(@{$self->{'log'}},$line);
	}
}

sub getLogLevel {
	return shift->{'loglevel'};
}

sub getLog {
	return shift->{'log'};
}

sub getReturnValue {
	return shift->{'returnvalue'};
}

sub addProperty {
	my ($self,$key,$value) = @_;
	eval {
		$self->{'properties'}->addProperty($key,$value);
	}; 
	die("Failed to add property $key=$value : $@") if $@;
	return $self;
}

sub getProperty {
	my ($self,$key) = @_;
	my $v;
	eval {
		$v = $self->{'properties'}->getProperty($key);
	};
	die("Failed to get property $key : $@") if $@;
	return $v;
}

# version of get property which errors on non-scalar property value
sub getScalarProperty {
	my ($self,$key) = @_;
	my $p = $self->getProperty($key);
	die("Property $key is not a scalar") if(ref($p)); 
	return $p;
}

sub writeProps {
	my ($self) = @_;
	$self->{'step'} = "writeproperties";
	my $filename = $self->getScalarProperty('build.output.properties');
	$self->{'properties'}->writeProps($filename);
	$self->info("Properties written to $filename");
}

sub doPropertySubstitution {
	my ($self,$value) = @_;
	return $self->{'properties'}->doPropertySubstitution($value);
}

sub dump {
	my ($self) = @_;
	return $self->{'properties'}->dump();
}

sub readProjectConfig {
	my ($self) = @_;
	$self->{'properties'}->readProps($self->getScalarProperty('builder.config.global')) if -f $self->getProperty('builder.config.global');
	$self->{'properties'}->readProps($self->getScalarProperty('builder.config.local')) if -f $self->getProperty('builder.config.local');
	$self->{'properties'}->readProps($self->getScalarProperty('builder.config.project')) if -f $self->getProperty('builder.config.project');
	$self->{'properties'}->readProps($self->getScalarProperty('builder.config.module')) if -f $self->getProperty('builder.config.module');
	return $self;
}

sub mergePropertyValues {
	my ($self,$property,$separator) = @_;

	$separator = ',' unless defined($separator);

	my $value = $self->getProperty($property);
	return $value unless ref($value);
	return join($separator,@$value);
}

sub generateClassPath {
	my ($self,$test) = @_;
	
	my $cpsep = $^O=~ /MSWin32/ ? ';' : ':';
	
	my $classpath = '';
	my @jars;
	if(defined($self->getProperty('dependencies.deppaths')->{'compile'})) {
		@jars = grep /\.jar$/, @{$self->getProperty('dependencies.deppaths')->{'compile'}};
	}

	if(defined($self->getProperty('dependencies.deppaths')->{'provided'})) {
		push(@jars,grep /\.jar$/, @{$self->getProperty('dependencies.deppaths')->{'provided'}});
	}

	if($test && defined($self->getProperty('dependencies.deppaths')->{'test'})) {
		push(@jars,grep /\.jar$/, @{$self->getProperty('dependencies.deppaths')->{'test'}});
	}
	my %jars;
	foreach my $jar (@jars) {
		$jars{$jar} = $jar;
	}
	@jars = keys(%jars);
	$classpath .= join($cpsep,@jars); 
	return $classpath;
}

sub halt {
	my ($self) = @_;
	$self->{'halt'} = 1;
}

sub addCompletionNotification {
	my ($self,$message) = @_;

	$self->{'notifications'} = [] unless ref($self->{'notifications'});
	my $msg = sprintf("%10s %s",$self->{'step'},$message);
	push(@{$self->{'notifications'}},$msg);
}

sub printCompletionNotifications {
	my ($self) = @_;
	
	if($self->{'notifications'}) {
		foreach my $string (@{$self->{'notifications'}}) {
			$self->warn("$string\n");
		}
	}
}

sub getStep {
	return shift->{'step'};
}

sub getHalt {
	return shift->{'halt'};
}

sub registerCleanupStep {
	my ($self,$step) = @_;

	my $cleanups = $self->{'cleanups'} || [];
	push(@$cleanups,$step);
}

sub performAction {
	my ($self,$package,$method) = @_;
	$method = 'execute' if $method eq '';
	eval "require $package";
	$self->error("Failed to require Package $package $@") if $@;
	eval "$package->new('builder' => \$self)->$method()";
	$self->error("Step $self->{'step'} failed with error $@") if $@;
}

sub executeStep {
	my ($self,$step) = @_;

	$self->{'step'} = $step;
	my $fn = eval { $self->getProperty("step.$step"); };
	$self->error("No such step as $step") unless $fn;
	my ($package,$method) = split(':',$fn);
	$self->performAction($package,$method);
	$self->info("Step executed");
}

sub execute {
	my ($self) = @_;
	my $stopat = eval { $self->getProperty('builder.stopat') };
	my $steps = $self->mergePropertyValues('build.steps');
	my @steps = split(',',$steps);
	foreach my $step (@steps) {
		eval { $self->executeStep($step); };
		if($self->{'halt'}) {
			$self->warn("Build halted");
			last;
			}
		last if $step eq $stopat;
	}

	my @csteps = @{$self->{'cleanups'}};
	$self->{'step'} = 'cleanups';
	$self->info("Performing registered post-build cleanup steps");
	foreach my $cstep (@csteps) {
		$self->executeStep($cstep);
	}

	$self->{'step'} = 'complete';
	$self->info("Build completed successfully") unless $self->{'halt'};
	$self->printCompletionNotifications();
}

1;

__END__

=head1 NAME

Builder - Dilettante project builder core

=head1 SYNOPSIS

	use Builder;
	my $builder = Builder->new();
	$builder->init('predefine' => 'builder.home=/mnt/foo');
	$builder->writeProps();
	$builder->execute();

=head1 DESCRIPTION

Builder is the main class which performs most of the work of the Dilettante build system. Usually it is invoked from the
L<build> script. However it is sometimes convenient to combine it with other scripting.

=head1 CONFIGURATION

Builder performs all the configuration actions of Dilettante except command line processing. The standard configuration process
is invoked via the init() function, which will read the various properties files and set itself up to operate in the standard fashion. For a description of the full configuration system see L<build>. 

The init function takes optional arguments as a hash. Currently 2 keys are recognized, 'predefine' allows property definitions
B<BEFORE> any other property processing, and 'postdefine' allows them at the very end of processing. If more flexibility is required
you can call methods of builder either before or after init(), or forgo init() altogether. See below for a description of the
full Builder API.

=head1 BUILDER API

Builder provides a number of useful functions. Generally build actions are performed by individual action classes, but there are
many operations which are so frequently used by different modules that they have been incorporated into Builder itself in order
to simplify development of action modules. This also helps maintain consistency of operation between steps and reduces the
chances of build errors. B<Note:> Most of the functions commonly accessed from action modules have aliases in the L<Step> module
in order to allow simpler syntax, for example a step can call $self->debug("some message") instead of $self->builder()->debug("some message").
See the L<Step> module pod for a list of aliases. 

=head2 LOGGING

Builder provides a simple logging facility. The property build.loglevel defines a level of logging output. 4 levels are supported

=over 4

=item debug($message)

The debug level is the most verbose. Most actions will report everything they do at this level.

=item info($message)

At this level Builder will report execution of steps etc. providing a general synopsis of build actions. Action modules should
report a brief synopsis of what they did at this level, usually 1 or 2 lines. This is generally the default level of logging and output
at this level should be sufficient to determine which steps were executed and what they did. Info level is the level most production
builds should use, the output can be then be assembled into a build report and posted to a build management site, etc.

=item warn($message)

At this level problems which do not halt the build are reported. This level will generally indicate any abnormal or unusual conditions which
may need to be examined such as dependency conflicts, failed resource variable substitutions, etc.

=item error($message)

At this level only errors which halt the build are reported. Calling this function will result in the build halting at this
point, unless the property builder.continue has the value 'true'. A clean build will generally not output anything at this level.

=back

Builder provides 4 logging functions corresponding to these levels, debug(), info(), warn(), and error(). If the log level is
equal to or greater than the corresponding level the message passed to these functions will be output, otherwise it will be
suppressed. The error() function additionally halts the build and issues a Carp::confess() with the message. In addition to
the message text builder will output the current value of the step property. This is set before calling an action module
method. The format of the output is currently fixed.

=head2 Property Management

Property management should be performed via the functions provided by Builder. 

=over 4

=item addProperty($key,$value) 

Adds the given value to the given property. This supports the full property syntax including directives
and property value substitution. See L<build> for the full explanation of the syntax.

=item getProperty($key) 

Returns the value(s) of the given property. Single valued properties will be returned as a scalar, multi-valued
properties will be returned as an array of values.

=item getScalarProperty($key)

Returns the value of a property which has one value. If a property has multiple values an error will be generated and the build halted. This
mainly simplifies action module code which wants a single valued property only. It is good practice to call this in cases where you are sure
the property should be single valued.

=item writeProps() 

Will write out a property file containing the current values of all properties to a file who's name is found in the
build.output.properties property. The L<build> script will normally invoke this at the end of a build run in order to provide
an easy check on what the configuration of the build was.

=item dump() 

Will return a string containing the full contents of the current properties in the same format as a properties file. 
This is used by writeProps(), but it could also be handy in other situations.

=item doPropertySubstitution($value) 

Parses value and replaces ${name} constructs with the values of the corresponding property
values. Any module can use this to perform filtering, etc.

=item mergePropertyValues($property,$separator) 

Returns a property as a scalar. If the property is single-valued the value is just
returned as-is. If the property is multi-valued the values are join()ed with the given separator, or a ',' if no separator is
provided.

=back

=head2 Build Execution

=over 4

=item execute() 

Invokes the sequence of build actions from the build.steps property. If the build.stopat property has a value then the execution will be truncated after the corresponding step is executed. This is generally only called
by the build.pl script, but certain types of actions such as inline sub-builds may also utilize this function.

=item registerCleanupStep($step)

Registers a step which will be performed AFTER all normal build steps have completed, regardless of the state of the
build at that time. The purpose of this mechanism is to allow for certain types of 'recovery' actions to be taken and
for certain functions to be performed in the event of a halted/failed build. For example a build which launches other
background programs (IE a JMS message broker or J2EE container) can register a clean up step to perform server shutdown
after build completion. This way even if the integration tests fail and result in a build halt, these applications can
be terminated. Other uses include generating test reports, sending out build state notifications, etc. which need to
happen regardless of the result of the build.

=item executeStep($step)

This is the entry point for executing a single step. Note that if this is called from an existing step the
value returned from Builder.getStep() is overwritten, so the calling step should be aware of this, the value
is not restored before returning.

=item performAction($package,$method)

This is the lowest level execution method. It simply requires $package and calls $method on a new instance
of the package's step. No changes are made to builder state before the call, so the current step name will be
unchanged, etc. Generally an action which needs to be composed of other actions uses this, it saves the
author from needing to sort out package loading etc. Any errors thrown in the call will be handled.

=back

=head2 Build Utilities

=over 4

=item generateClassPath($testflag) 

This will return a string containing all dependencies of the current module in a format suitable for
use as a java classpath argument to a jvm or the javac compiler. If a true value is passed then test dependencies will be included,
otherwise they will not.

=item genPath($path)

Rewrite a path or 'path like' string to conform to the syntax of the host platform. Generally '/' will be replaced by the host OS
path separator.

=item getLog()

Returns an array of strings containing a copy of each log message for the current run. 

=item getReturnValue()

Returns the current value which will be returned via exit() at termination of the build script run. If this isn't 0 it indicates
an error value is being returned. Generally -1 will be returned if an error was encountered during the build. If the 
builder.continue property is set to 'true' the rest of the steps will be performed regardless, otherwise once the current step
finishes the build will halt. A step could use this value to determine whether or not following steps will execute or not.

=item halt()

Calling this function will flag the builder to stop after the current step completes. Generally this is set true by a call to the
error() function, unless builder.continue is 'true'. Calling halt() directly would bypass this check. While it probably isn't a
B<nice> thing for an action to do, it is possible to unconditionally halt the build via calling this function.

=item addCompletionNotification($message)

This provides a way to output a message which will be output at the B<end> of the build. This is in contrast to the various log
functions which output immediately. Actions which want to provide some kind of summary or important information which the user
should always see can use this function. For instance the Test actions use this to insure that test failure indications are
available in the output at the end of the run to flag the user that not everything went OK, even if the build completed.

=item getStep()

Returns the name of the current build step. This is particularly useful when constructing actions which might want to do
different things (IE use one of several possible property values) depending on how they were invoked. For instance the Filter
action module uses this to select different possible sources and destinations for filtered data.

=item registerCleanupStep($step)

Registers a step as a B<cleanup>. Cleanups are steps which are always executed at the end of the build, regardless of any errors. This
is very useful when a step needs to make sure something always happens later. For example steps which start external programs may want to
register a cleanup step which shuts down the external program. Test uses this for example to generate test reports even when the tests
themselves fail. The executed cleanup step(s) are called just like a normal step would be, they simply do not need to be listed in the
build.steps property and are not skipped in the event of an error.

=item  printCompletionNotifications()

Calls warn() for each completion notification at the end of the build. This is normally called from inside execute(). 

=back

=head1 USE

The build.pl script is B<usually> flexible enough to accomplish whatever tasks are desired. In a few cases it may be desirable to create
other scripts which access build-like functionality, in which case this module might be invoked directly. The other likely case where it
may be useful to construct and call a Builder object would be in a step which controls other builds. The L<SubBuild> module is provided for
use in these cases, but sometimes it may not suitable.

Because Builder maintains B<ALL> state for itself in instance variables there should not normally be a problem with builds calling other
builds or even recursive builds.

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

=head1 SEE ALSO

L<build>, L<Step>

=cut
