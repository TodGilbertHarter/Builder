package Bnd;

use strict;
use base qw(Step);
use IO::All;

sub execute {
	my ($self) = @_;

	my $step = $self->getStep();
	my $cdir = $self->builder()->getScalarProperty('build.target.classes');
	my $bndcmd = $self->getScalarProperty('bnd.command');
	my $target = $self->getScalarProperty("bnd.$step.target");
	my $bndfile = $self->getScalarProperty("bnd.$step.bndfile");
	$self->_execute($bndcmd,$cdir,$target,$bndfile);
}

sub _execute {
	my ($self,$bndcmd,$cdir,$target,$bndfile) = @_;

	my $step = $self->getStep();
	$self->debug("Executing bnd with class dir $cdir, bncmd $bndcmd, target $target, bndfile $bndfile");
	my $args = "buildx --classpath $cdir --output $target $bndfile";
	$self->debug("executing $bndcmd with args $args");
	my $error = '';
	$error = "$step exec failed" if system("$bndcmd $args");
	$self->error($error) if $error ne '';
}


1;


__END__

=head1 NAME

Bnd - Dilletante bnd invoker

=head1 DESCRIPTION

Bnd.pm allows Builder to invoke the bnd command line tool to build OSGi bundles and perform other related tasks.

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
