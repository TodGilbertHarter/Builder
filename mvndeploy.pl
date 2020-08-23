#!/usr/bin/perl

use strict;

use Pod::Usage;
use Getopt::Long;
use Data::Dumper;
use File::Find;
use Term::ReadLine;

use vars qw(%opts);

%opts = # establish default values for command line params
	(
#	'repositoryurl' => "file:///mnt/deltaopt/development/testrepository",
	'repositoryurl'	=> '',
#	'repositoryid' 	=> "TSIDevGroup",
	'repositoryid'	=> '',
#	'groupid'		=> "org.jboss",
	'groupid'		=> '',
#	'version'		=> "4.0.4CR2",
	'version'		=> '',
	'directory'		=> ".",
	'man'			=> 0,
	'help'			=> 0,
	);

GetOptions(\%opts,
	'man',
	'help',
	'repositoryurl=s',
	'repositoryid=s',
	'groupid=s',
	'version=s',
	'directory=s',
	) || pod2usage('exitval' => -1,'verbose' => 1);
pod2usage('exitval' => 0,'verbose' => 2) if $opts{'man'};
pod2usage('exitval' => 0,'verbose' => 1) if $opts{'help'};
pod2usage('exitval' => -1, 'verbose' => 1) if $opts{'repositoryurl'} eq '' || $opts{'repositoryid'} eq '' ||
	$opts{'groupid'} eq '' || $opts{'version'} eq '';
my $term = new Term::ReadLine 'MVN jar deployer';
my $OUT = $term->OUT || \*STDOUT;
my $prompt = "Import this (y/n): ";

find(\&wanted,$opts{'directory'});

sub wanted
	{
	if(/(.*)\.jar$/) 
		{
		my $artifactname = $1;
		print $OUT "found a jar $_\n"; 
		my $answer = $term->readline($prompt);
		if($answer eq "y") 
			{
			system('mvn','deploy:deploy-file',"-DartifactId=$artifactname","-Durl=$opts{'repositoryurl'}",
				"-DrepositoryId=$opts{'repositoryid'}","-DgroupId=$opts{'groupid'}","-Dversion=$opts{'version'}",
				"-Dpackaging=jar","-Dfile=$_");
			}
		}
	}

exit(0);

__END__

=head1 NAME

MVN Deployer tool - Deploy multiple artifacts to MVN repository

=head1 SYNOPSIS

.\mvndeploy.pl [options]

.\mvndeploy.pl --help

.\mvndeploy.pl --man

.\mvndeploy.pl --repositoryurl=file:///myrep --repositoryid=TSIDevGroup --groupid=org.jboss --version=4.0.4CR2

=head1 DESCRIPTION

MVN Deployer provides a quick easy way to deploy a whole bunch of jars to an MVN remote repository. It 
iterates through a given directory (the current working directory by default) and all its subdirs looking
for .jar files and invokes the mvn deploy:deploy-file goal on each one, after prompting the user. This is
useful for situations where a vendor has dropped a new version of a framework, say the JBoss EJB3 libraries,
which all need to be installed in an MVN repository. Rather than manually calling mvn for each one, just
run this marvellous script!

=head1 OPTIONS

=over 4

=item --repositoryurl=url
The URL of the remote repository you are deploying to. This is a required parameter.


=item --repositoryid=repoid
The repository id of the remote repository in your ~/.m2/settings.xml (or wherever mvn normally finds it).
This is also mandatory.


=item --groupid=groupid
The groupId to be assigned to all deployed jars. This is mandatory also.


=item --version=version
The version number to assign to the jars. This is also mandatory.


=item --directory=somedir
Specify a directory other than the current working directory as the place to start the search for jars.


=item --help
Output basic help info on this script.


=item --man
Output extensive documentation on this script.


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
