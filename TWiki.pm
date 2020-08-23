package TWiki;

use strict;
use base qw(Step);
use IO::All;
use WWW::TWikiClient;
use DateTime::Format::Strptime;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $twikiprojectweb = $self->builder()->getScalarProperty("twiki.$step.web");
	my $twikiprojecttopic = $self->builder()->getScalarProperty("twiki.$step.topic");
	my $twikiuser = $self->builder()->getScalarProperty('twiki.username');
	my $twikipassword = $self->builder()->getScalarProperty('twiki.password');

	my $buildname = $self->builder()->getScalarProperty('build.name');
	my $builddescription = $self->builder()->getScalarProperty('build.description');
	my $buildreport = "---+ $buildname\n";
	my $formatter = DateTime::Format::Strptime->new('pattern' => '%Y-%m-%d');
	my $dt = DateTime->now();
	my $dtstr = $formatter->format_datetime($dt);
	$buildreport .= "---++ Build $dtstr\n";
	$buildreport .= "\n---+++$builddescription\n\n";
	$buildreport .= join("\n",@{$self->builder()->getLog()});
	$self->_doTopicOutput($twikiprojectweb,$twikiprojecttopic,$twikiuser,$twikipassword,$buildreport);
}

sub testReport {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $twikiprojectweb = $self->builder()->getScalarProperty("twiki.$step.web");
	my $twikiprojecttopic = $self->builder()->getScalarProperty("twiki.$step.topic");
	my $twikiuser = $self->builder()->getScalarProperty('twiki.username');
	my $twikipassword = $self->builder()->getScalarProperty('twiki.password');

	my $buildname = $self->builder()->getScalarProperty('build.name');
	my $testreport .= io($self->builder()->getScalarProperty('build.target.testreports')."/testreport.txt")->slurp();
	$testreport =~ s|\n|<br/>|mg;
	$testreport = "---+ Test Report For $buildname\n\n$testreport";
	$self->_doTopicOutput($twikiprojectweb,$twikiprojecttopic,$twikiuser,$twikipassword,$testreport);
}

# save the given content to the given web.topic, using the given twiki user/passwd
sub _doTopicOutput {
	my ($self,$web,$topic,$user,$password,$content) = @_;
	$self->debug("TWiki topic output to $web.$topic\n");
	my $twikibin = $self->builder()->getScalarProperty('twiki.bin');
	my $client = WWW::TWikiClient->new();
	$client->auth_user($user);
	$client->auth_passwd($password);
	$client->bin_url($twikibin);
	$self->info("TWiki output to $web.$topic");
	$client->save_topic($content,"$web.$topic");
}

1;


__END__

=head1 NAME

TWiki - Dilettante TWiki reporting functions

=head1 DESCRIPTION

This module provides a way for build information to be integrated into a TWiki. Currently 2 actions are supported. The default
action puts a copy of the log output of the current build script into a topic. The testReport action inserts the consolidated
output of Test into a topic. 

=head2 CONFIGURATION

Several properties control execution.

=over 4

=item twiki.bin

This property is the base URL for scripts on the target TWiki. Generally it will be something like 'http://twiki.somewhere.com/twiki/bin'. 
The exact required value will depend on the setup of the TWiki in question.

=item twiki.<step>.web

Where <step> is the name of the current step this property value provides the name of the TWiki web in which the operation will
create or update a topic. So a step definition like step.twtestreport=Twiki:testReport and a property setting of 
twiki.twtestreport.web=MyProjectWeb would target the web named 'MyProjectWeb' with a test report when the twtestreport step is
executed.

=item twiki.<step>.topic

Similar to the twiki.<step>.web property, but provides the name of the specific TWiki topic which will be updated or created.

=item twiki.username

Provides the login name of the user identity which will be used to perform the TWiki update/create function. Generally this is
a wiki name, but this will depend on the setup of the given TWiki.

=item twiki.password

Provides the password corresponding to the twiki.username.

=item build.name

This is used as the value of the top level header for the new topic. 

=item build.description

This is also inserted into the build report at the beginning of the topic.

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
