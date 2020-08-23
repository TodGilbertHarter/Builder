package Trac;

use local::lib;
use strict;
use base qw(Step);
use IO::All;
use Trac::RPC;
use DateTime::Format::Strptime;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $tracpage = $self->builder()->getScalarProperty("trac.$step.page");
	my $tracuser = $self->builder()->getScalarProperty('trac.username');
	my $tracpassword = $self->builder()->getScalarProperty('trac.password');
	my $tracrealm = $self->builder()->getScalarProperty('trac.realm');
	my $tracurl = $self->builder()->getScalarProperty('trac.url');
	my $file = $self->builder()->getScalarProperty("trac.$step.file");

	my $buildname = $self->builder()->getScalarProperty('build.name');
	my $builddescription = $self->builder()->getScalarProperty('build.description');
	my $buildreport = "= $buildname =\n";
	my $formatter = DateTime::Format::Strptime->new('pattern' => '%Y-%m-%d');
	my $dt = DateTime->now();
	my $dtstr = $formatter->format_datetime($dt);
	$buildreport .= "== Build $dtstr ==\n";
	$buildreport .= "\n=== $builddescription ===\n\n";
	$buildreport .= join("\n",'{{{',@{io($file)},'}}}');
	$buildreport .= "\n\nuploaded by builder at ".time();
	$self->_doTopicOutput($tracpage,$tracurl,$tracrealm,$tracuser,$tracpassword,$buildreport);
}

sub append {
	my ($self) = @_;
	
	my $step = $self->builder()->getStep();
	
	my $tracpage = $self->builder()->getScalarProperty("trac.$step.page");
	my $tracuser = $self->builder()->getScalarProperty('trac.username');
	my $tracpassword = $self->builder()->getScalarProperty('trac.password');
	my $tracrealm = $self->builder()->getScalarProperty('trac.realm');
	my $tracurl = $self->builder()->getScalarProperty('trac.url');
	my $file = $self->builder()->getScalarProperty("trac.$step.file");
	
}

sub testReport {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $tracpage = $self->builder()->getScalarProperty("trac.$step.page");
	my $tracuser = $self->builder()->getScalarProperty('trac.username');
	my $tracpassword = $self->builder()->getScalarProperty('trac.password');
	my $tracrealm = $self->builder()->getScalarProperty('trac.realm');
	my $tracurl = $self->builder()->getScalarProperty('trac.url');

	my $buildname = $self->builder()->getScalarProperty('build.name');
	my $testreport = "{{{\n" . io($self->builder()->getScalarProperty('build.target.testreports')."/testreport.txt")->slurp() . "\n}}}";
#	$testreport =~ s|\n|<br/>|mg;
	$testreport = "= Test Report For $buildname =\n\n$testreport";
	$testreport .= "\n\nuploaded by builder at ".time();
	$self->_doTopicOutput($tracpage,$tracurl,$tracrealm,$tracuser,$tracpassword,$testreport);
}

# save the given content to the given web.topic, using the given twiki user/passwd
sub _doTopicOutput {
	my ($self,$page,$url,$realm,$user,$password,$content) = @_;
	$self->debug("Trac Wiki output to $url\n");
	my $params = {
		realm => $realm,
		user =>  $user,
		password => $password,
		host => $url
	};
	my $client = Trac::RPC->new($params);
	$self->info("Trac wiki output to $url for page $page");
	$client->put_page($page,"$content");
}

1;


__END__

=head1 NAME

Trac - Dilettante Trac reporting functions

=head1 DESCRIPTION

This module provides a way for build information to be integrated into a Trac Wiki. Currently 2 actions are supported. The default
action puts a copy of trac.file into a page. The testReport action inserts the consolidated
output of Test into a page. 

=head2 CONFIGURATION

Several properties control execution.

=over 4

=item trac.<step>.page

Where <step> is the name of the current step this property value provides the name of the Trac Wiki page to add/update

=item trac.username

Provides the login name of the user identity which will be used to perform the Trac update/create function. Generally this is
a wiki name, but this will depend on the setup of the given Trac.

=item trac.password

Provides the password corresponding to the trac.username.

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
