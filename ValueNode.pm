package ValueNode;

use strict;

sub new {
	my ($caller, %arg) = @_;
	my $class = ref($caller);
	$class ||= $caller;
	my $self = bless({},$class);
	bless($self,$class);
	foreach my $key (keys(%arg)) {
		$self->{$key} = $arg{$key};
	}
	$self->{'children'} = {} unless defined $self->{'children'};
	return $self;
}

sub getName {
	return shift->{'name'};
}

sub getValue {
	return shift->{'value'};
}

sub replaceValue {
	my ($self,$value) = @_;
	$self->{'value'} = $value;
}

sub addValue {
	my ($self,$value) = @_;
	if(defined $self->{'value'}) {
		my $type = ref($self->{'value'});
		if($type eq '') {
			$self->{'value'} = [ $self->{'value'}, $value ];
		} else {
			push(@{$self->{'value'}},$value);
		}
	} else {
		$self->{'value'} = $value;
	}
	return $self;
}

sub addChild {
	my ($self,$child) = @_;
	$self->{'children'}->{$child->getName()} = $child;
}

sub getChild {
	my ($self,$name) = @_;
	return $self->{'children'}->{$name};
}

sub getChildren {
	return shift->{'children'};
}

sub removeChild {
	my ($self,$name) = @_;
	delete($self->{'children'}->{$name});
}

sub dump {
	my ($self,$path) = @_;
	my $ds = '';
	if($path eq '') {
		$path = $self->getName();
	} else {
		$path = $path.".".$self->getName();
	}
	foreach my $child ((values %{$self->getChildren()})) {
		$ds .= $child->dump($path);
	}
	my $value = $self->getValue();
	my $type = ref($value);
	if($type eq '') {
		$ds .= "$path=$value\n" if $value ne '';
	} elsif($type eq 'ARRAY') {
		foreach my $v (@$value) {
			$ds .= "$path=$v\n" if $v ne '';
		}
	}
	return $ds;
}

1;

__END__


=head1 NAME

ValueNode - Dilettante property node object

=head1 DESCRIPTION

This class provides the base functionality for a node in the properties tree. Normally it will not be accessed directly by
application code.

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
