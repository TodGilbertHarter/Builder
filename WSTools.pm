package WSTools;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $wsjavadir = $self->genPath($self->builder()->getProperty('wstools.target.java'));
	io($wsjavadir)->mkpath();
	my $wsconfdir = $self->genPath($self->builder()->getProperty('wstools.config.dir'));
	my $wstools = $self->genPath($self->builder()->getProperty('wstools.wstools'));
	my $classpath = $self->builder()->getProperty('build.target.classes');

#	my $servicename = $self->builder()->getProperty('webservice.name');
	my @wstoolscfs = io->dir($wsconfdir)->all(0);
	foreach my $wstoolscf (@wstoolscfs) {
		if($wstoolscf =~ /.*\.xml$/) {
			$self->info("$wstools -cp $classpath -config $wstoolscf $wsjavadir");
			if(system($wstools,'-cp',$classpath,'-config',$wstoolscf,'-dest',$wsjavadir)) {
				$self->error("WSTools mapping file generation failed");
			}
		}
	}
}

1;


__END__

=head1 NAME

WSTools - Dilettante run wstools module

=head1 DESCRIPTION

Generate JBossws client-side artifacts using the wstools script supplied with JBoss ws releases. This has been tested with the
1.0.4.GA release, it may or may not be entirely compatible with other versions of jbossws. 

=head2 CONFIGURATION

Several properties control the operation of this module

=over 4

=item wstools.target.java

Generated web service client source will be output to this directory.

=item wstools.config.dir

wstools-config.xml files will be located in this directory. Any xml files found here will be treated as wstools config files and
processed.

=item wstools.wstools

This property points to the wstools script itself.

=item build.target.classes

The classpath for wstools will be constructed from this property.

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
