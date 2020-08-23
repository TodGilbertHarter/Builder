package Archive;

use strict;
use base qw(Step);
use Archive::Zip;
use IO::All;

sub execute {
	my ($self) = @_;

	my $step = $self->builder()->getStep();
	my $type = $self->builder()->getScalarProperty("archive.$step.type");
	my $name = $self->builder()->getScalarProperty("archive.$step.name");
	my $source = $self->builder()->getScalarProperty("archive.$step.source");

	$self->info("constructing archive $name from $source of type $type");
	if($type eq 'zip') {
		my $zip = Archive::Zip->new();
		$zip->addTree($source,'');
		$zip->writeToFileNamed($name);
	} elsif($type eq 'tarball') {
		$self->error("Failed to construct tarball")
			if system('tar','zcf',$name,'-C',$source,'.');
	} else {
		$self->error("Archive does not support type $type at this time");
	}
}

sub explode {
  my ($self) = @_;
  
	my $step = $self->builder()->getStep();
	my $name = $self->builder()->getScalarProperty("archive.$step.name");
	my $target = $self->builder()->getScalarProperty("archive.$step.target");
	my $type = $name =~ /.*(tar.gz|tgz)/;
	if($type) {
	  $self->error("Failed to explode tarball "+$name+" to "+$target)
		if system('tar','zxf',$name,'-C',$target);
	} else {
	  $self->error("Failed to unzip zip "+$name+" to "+$target)
		if system('unzip',$name,'-d',$target);
	}
}

1;


__END__

=head1 NAME

Archive - Dilettante File archive builder action module

=head1 DESCRIPTION

=head2 CONFIGURATION

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
