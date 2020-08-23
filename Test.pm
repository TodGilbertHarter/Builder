package Test;

use strict;
use base qw(Step);
use IO::All;
use XML::LibXML;
use XML::LibXSLT;

sub execute {
	my ($self) = @_;

	$self->registerCleanupStep('testreport');
	my $tcdir = $self->genPath($self->builder()->getScalarProperty('build.target.testclasses'));
	my $cdir = $self->builder()->getScalarProperty('build.target.classes');
	$self->_execute($tcdir,$cdir);
}

# this is identical to execute() except it lets us use different values for classes and test classes so we can
# do things like instrument with Cobertura first.
sub test {
	my ($self) = @_;

	$self->registerCleanupStep('testreport');

	my $step = $self->builder()->getStep();
	my $tcdir = $self->genPath($self->builder()->getScalarProperty("test.$step.testclasses"));
	my $cdir = $self->builder()->getScalarProperty("test.$step.classes");
	$self->_execute($tcdir,$cdir);
}

sub _execute {
	my ($self,$tcdir,$cdir) = @_;

	$self->debug("Executing tests with dir $cdir and test dir $tcdir");
	my $extras;
	eval { $extras = $self->builder()->getProperty('test.extras'); };
	$extras = [ $extras ] unless ref($extras);
	$extras = "@$extras";
	my @extras = split(/ /,$extras);
	$self->debug("Extras are '$extras'");
#	$self->registerCleanupStep('testreport');
#	my $tcdir = $self->genPath($self->builder()->getProperty('build.target.testclasses'));
#	my $cdir = $self->builder()->getProperty('build.target.classes');
	my @tests = io($tcdir)->all(0);

	my $patterns;
	my @testclasses;
	eval { $patterns = $self->builder()->getProperty('test.includes'); };
	$patterns = 'Test[^$]*\.class$' if !ref($patterns) && $patterns eq '';
	$patterns = [ $patterns ] unless ref($patterns);
#use Data::Dumper;
#	push(@$patterns,'Test[^$]*\.class$') unless @$patterns > 0;
#print("WHAT THE FUCK IS THE PATTERNS ARRAY ".Dumper($patterns)."\n");
	foreach my $pattern (@$patterns) {
		$self->debug("Test Includes contains a pattern called $pattern");
#		push(@testclasses,grep($pattern,@tests));
		foreach my $testclass (@tests) {
			$self->debug("Tests includes a class called $testclass");
			if($testclass =~ $pattern && $testclass !~ /Abstract/) {
				$self->debug("Matched $testclass to $pattern and not abstract, pushing into list");
#				$testclass =~ s|^($tcdir/)||;
				$testclass = io($testclass)->abs2rel($tcdir);
				$testclass =~ s|(/)|.|g;
				$testclass =~ s|(\\)|.|g;
				$testclass =~ s|(\.class)$||;
				$self->debug("After cleanup name of test class is $testclass");
				push(@testclasses,$testclass);
			}
		}
	}
	return if @tests == 0; # no tests to run
	my $cpsep = $^O=~ /MSWin32/ ? ';' : ':';
#	my $cp = "$cdir".$cpsep."$tcdir".$cpsep.$self->builder()->generateClassPath(1);
# NOTE: the stupid ass java compiler unhelpfully moves a copy of SOME of the class files that are in the class path into the target
# directory. This completely hoses up things like embedded EJB3 which scans the class path and can't tolerate duplicate files (plus
# who the hell knows exactly what you're getting...). So, we will have to make a COPY of all the non-test classes into test-classes
# and exclude the non-test classes from the class path for the run. This is incredibly stupid and Sun should have its ass kicked for
# being such dumbshits. 
	$self->_copyTree($cdir,$tcdir,".*\.class") if(-d $cdir); # some builds may not have classes
	my $tsuppresstcdir = eval { $self->builder()->getScalarProperty('test.suppresstcdir'); };
	my $cp = ($tsuppresstcdir) ? '' : "$tcdir".$cpsep;
	$cp .= $self->builder()->generateClassPath(1);
	my $addcps = eval { $self->builder()->getProperty('test.classpath.additional'); };
	if($addcps) {
		$addcps = ref($addcps) ? $addcps : [$addcps];
		foreach my $addcp (@$addcps) {
			$cp .= $cpsep.$addcp;
		}
	}
	$self->debug("Using extra args of '$extras'");
#	$cp .= " $extras";
	
	my $trd = $self->builder()->getScalarProperty('build.target.testreports');
	mkdir($trd);
	my $tfork = eval { $self->builder()->getScalarProperty('test.fork'); };
	$self->debug("Running tests @testclasses with classpath $cp");
	my $java = $self->genPath($self->builder()->getScalarProperty('build.java'));
	if($tfork eq 'true') {
		foreach my $testclass (@testclasses) {
			my @foob = ($java,'-cp',$cp,@extras,'com.tradedesksoftware.test.report.XMLTestRunner',$trd,$testclass);
			$self->debug("using test args of @foob");
#			if(system($java,'-cp',$cp,$extras,
#					'com.tradedesksoftware.test.report.XMLTestRunner',
#					$trd,$testclass)) {
			if(system(@foob)) {
				$self->warn("Tests Failed");
				$self->builder()->addCompletionNotification("Some tests failed");
				my $haltflag = eval { $self->builder()->getScalarProperty('test.halt'); };
				$self->halt() unless $haltflag eq 'false';
			}
		}
	} else {
		my @foob = ($java,'-cp',$cp,@extras,'com.tradedesksoftware.test.report.XMLTestRunner',$trd,@testclasses);
		$self->debug("using test args of @foob");
#		if(system($java,'-cp',$cp,$extras,
#				'com.tradedesksoftware.test.report.XMLTestRunner',
#				$trd,@testclasses)) {
		if(system(@foob)) {
			$self->warn("Tests Failed");
			$self->builder()->addCompletionNotification("Some tests failed");
			my $haltflag = eval { $self->builder()->getScalarProperty('test.halt'); };
			$self->halt() unless $haltflag eq 'false';
		}
	}
}

sub report {
	my ($self) = @_;
	my $trd = $self->genPath($self->builder()->getScalarProperty('build.target.testreports'));
	my $repxslt = $self->genPath($self->builder()->getScalarProperty('test.report.stylesheet'));
	my $repout = $self->genPath($self->builder()->getScalarProperty('test.report.outfile'));
	my $reports = '<testreport>';
	unlink($repout);
	$reports .= $_->slurp for io($trd)->all_files();
	$reports .= '</testreport>';

	$self->debug("Generating test report $repout via stylesheet $repxslt");
	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_string($reports);
	my $xslt = XML::LibXSLT->new();
	my $instyle_doc = $parser->parse_file($repxslt);
	my $instylesheet = $xslt->parse_stylesheet($instyle_doc);
	my $results = $instylesheet->transform($doc);
#	my $resstr = $results->serialize();
	$instylesheet->output_file($results,$repout);
#	$resstr > io($repout);
}

sub _report {
	my ($self,$treps,$repxslt,$repout) = @_;

	$treps = [$treps] unless ref $treps;

#	my $reports = '<testreport>';
	my $reports = '';
	unlink($repout);
	foreach my $rep (@$treps) {
		$reports .= $_->slurp for io($rep);
	}
#	$reports .= '</testreport>';

	$self->debug("Generating test report $repout via stylesheet $repxslt");
	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_string($reports);
	my $xslt = XML::LibXSLT->new();
	my $instyle_doc = $parser->parse_file($repxslt);
	my $instylesheet = $xslt->parse_stylesheet($instyle_doc);
	my $results = $instylesheet->transform($doc);
	$instylesheet->output_file($results,$repout);
}

sub juniteereport {
	my ($self) = @_;

	my $xslt = $self->getScalarProperty('test.junitee.stylesheet');
	my $trd = $self->genPath($self->getScalarProperty('build.target.testreports'));
	my $repout = $self->genPath($self->getScalarProperty('test.junitee.outfile'));
	my $treps = $self->getScalarProperty('test.junitee.report');
	my $xml = eval { $self->getScalarProperty('test.junitee.xml'); };
	$xml = $xml eq 'xml' ? 'xml' : 'html';
	$treps = $treps.$xml;
	$self->_report($treps,$xslt,$trd);
}

# calls a JUnitEE test or tests.

sub junitee {
	my ($self) = @_;

	my $url = $self->getScalarProperty('test.junitee.url');
	my $suites = $self->getProperty('test.junitee.suites');
	$suites = [$suites] unless ref $suites;
	my $xml = eval { $self->getScalarProperty('test.junitee.xml'); };
	$xml = $xml eq 'xml' ? 'xml' : 'html';
	my $outfile = $self->getProperty('test.junitee.report')."$xml";
	my $trd = $self->getScalarProperty('build.target.testreports');
	mkdir($trd);
	my $tfork = eval { $self->builder()->getScalarProperty('test.junitee.fork'); };

	my $pstr = "?output=$xml";
	$pstr .= '&thread=true' if $tfork eq 'true';
	foreach my $suite (@$suites) {
		$self->debug("Adding suite $suite to tests");
		$pstr .= "&suite=$suite";
	}
	$url .= $pstr;

	$self->info("Executing tests with URL $url");
	my $response = $self->get($url);
	$self->error("Failed to execute tests ".$response->content()) unless $response->is_success();
	my $content = $response->content();
	my $success = $content =~ /failures="0"/ && $content =~ /errors="0"/;
	$content > io($outfile);
#	$self->error("Tests failed") unless $success;
	if(!$success) {
		$self->warn("Tests Failed");
		$self->builder()->addCompletionNotification("Some tests failed");
		my $haltflag = eval { $self->builder()->getScalarProperty('test.halt'); };
		$self->halt() unless $haltflag eq 'false';
	}

}

1;


__END__

=head1 NAME

Test - Dilettante JUnit test execution module

=head1 DESCRIPTION

Test provides for execution of JUnit tests and test suites. The default action executes tests via a JUnit runner which outputs
a simple XML report file for each test or test suite. The report function consolidates XML test reports and generates a single
text file containing the same information and a summary in a more readable format. Alternate XSLT style sheets can be specified
in order to customize this output if desired.

=head2 TEST CONFIGURATION

Several properties control execution of tests.

=over 4

=item build.target.testclasses

This is the path to the compiled tests. 

=item build.target.testreports

Directory where all test reports will be written

=item test.includes

Regex which will be used to filter the test classes. Any class file matching this Regex will be treated as a test(case) and
passed to the JUnit Runner. By default any class file with a name containing the string 'Test' will be considered a test, unless
a '$' appears somewhere in the name.

=item test.fork

If this property value is defined and has the value 'true' then each test(case) will be executed individually in its own jvm,
otherwise all tests will be executed together in one run.

=item test.halt

If this property is defined and has the value 'false' then the build will continue in the event of test failure, otherwise a
test failure will cause the build to halt at the end of the step.

=item build.java

This is the java executeable which will be used to run the tests.

=back

=head2 TEST REPORT CONFIGURATION

=over 4

=item test.report.stylesheet

This is the XSLT stylesheet which will be used to generate the consolidated test report.

=item test.report.outfile

This is the name of the consolidated report file which will be generated.

=back

=head1 USE

Executing tests is entirely straightforward. By default all class files containing 'Test' in their names will be considered to
contain tests and executed. Supplying a regex is commonly usefull. There should probably be a test.excludes regex as well, but
as of now it isn't supported.

Test report generation can be customized by defining an alternate value for test.report.stylesheet and constructing an XSLT
transform. The one supplied with builder can be used as a model. All the XML test reports are consolidated into a single
document with a <testreport/> element surrounding all of them, and then the XSLT is applied. Practically any kind of output
could be generated this way.

Generating multiple formats could be accomplished by either constructing another action to utilize a different property to
supply the stylesheet and output file name, or extending report() to allow for multivalued properties.

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
