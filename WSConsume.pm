package WSConsume;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $wsjavadir = eval { $self->genPath($self->getScalarProperty('wsconsume.target.java')); };
	my $wsconsume = $self->genPath($self->getScalarProperty('wsconsume.wsconsume'));
	my $wsdl = $self->getScalarProperty('wsconsume.wsdl');
	my $outdir = $self->getScalarProperty('wsconsume.target.classes');
	my @args = ('-o',$outdir,'-e','-t','2.2');
	unless($wsjavadir eq undef) {
		$self->debug("going to put stub source in $wsjavadir");
		io($wsjavadir)->mkpath();
		push(@args,'-s');
		push(@args,$wsjavadir);
		push(@args,'-k');
	}
	push(@args,'-v') if $self->getLogLevel() eq 'debug';
	push(@args,$wsdl);
	$self->info("creating service stubs from $wsdl in $outdir");
	$self->debug("Calling $wsconsume with @args");
	$ENV{JAVA_HOME} = $self->getScalarProperty('build.javahome');
	$self->error("WSConsume failed") if system($wsconsume,@args);
}

1;


__END__

=head1 NAME

WSTools - Dilettante run wsconsume module

=head1 DESCRIPTION

Runs the JBoss-ws wsconsume tool. This will produce a SOAP service client stub and SEI from a WSDL file.

=head2 CONFIGURATION

Several properties control the operation of this module

=over 4

=item wsconsume.target.java

Generated web service client source will be output to this directory.

=item wsconsume.wsconsume

This property points to the wsconsume script itself.

=item wsconsume.target.classes

The output directory for compiled class files. A copy of the WSDL will be placed here as well.

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
