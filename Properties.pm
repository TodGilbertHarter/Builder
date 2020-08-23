package Properties;

use strict;
use IO::File;
use Fcntl qw(:DEFAULT);
use base qw(ValueNode);
use vars qw($PSEP);

# determine OS specific path separator for use by genPath
$PSEP = $^O=~ /MSWin32/ ? "\\" : '/';

sub addProperty {
	my ($self,$property,$value) = @_;
	if($property =~ /^(\!)(.*)/) {
		$property = $2;
		if($value eq '*') {
			$self->deleteProperty($property);
		} else {
			$self->deletePropertyValue($property,$self->doPropertySubstitution($value));
		}
	} elsif($property =~ /^(\-)(.*)/) {
		$property = $2;
		my $pnode = undef;
		eval {
			$pnode = $self->_getPropertyNode($property);
		};
		if($pnode != undef) { # if it exists, replace it
			$pnode->replaceValue($self->doPropertySubstitution($value));
		} else { # doesn't exist, so just insert it
			$self->addProperty($property,$value);
		}
	} else {
		my @elements = split('\.',$property);
		$value = $self->doPropertySubstitution($value);
		$self->_addProperty($value,$self,@elements);
	}
        return $self;
}

sub genPath {
	my ($self,$path) = @_;
	$path = $path ? $path : $self; # allow static call
	$path =~ s|/|$PSEP|ge;
	return $path;
}

sub deletePropertyValue {
	my ($self,$property,$value) = @_;
	my $pnode = $self->_getPropertyNode($property);
	if($pnode != undef) {
		my $cvalue = $pnode->getValue();
		if(ref($cvalue)) {
			for(my $i = 0; $i < scalar(@$cvalue); $i++) {
				delete $cvalue->[$i] if $cvalue->[$i] eq $value;
			}
		} else {
			$self->deleteProperty($property);
		}
	}
}

sub deleteProperty() {
	my ($self,$property) = @_;
	my @elements = split('\.',$property);
	my $result = $self;
	my $parent = undef;
	my $element = undef;
	my $lastelement = undef;
	foreach $element (@elements) {
		$lastelement = $element;
		$parent = $result;
		$result = $result->getChild($element);
	}
	$parent->removeChild($lastelement) if($parent != $self && $parent != undef)
}

sub doPropertySubstitution {
	my ($self,$value) = @_;
	while($value =~ /(\$\{[a-z,.]*\})/) {
		my $t = $1;
		my $skey = $t;
		$t =~ /\$\{(.*)\}/;
		my $bkey = $1;
		$value =~ s/\$\{$bkey\}/$self->getProperty($bkey)/ge;
	}
	return $value;
}

sub _addProperty {
	my ($self,$value,$target,@elements) = @_;
	if(scalar(@elements) > 0) {
		my $key = shift(@elements);
		if($target->getChild($key) == undef) {
			$target->addChild(ValueNode->new('name' => $key));
		}
		$self->_addProperty($value,$target->getChild($key),@elements);
	} else {
		$target->addValue($value);
	}
}

sub _getPropertyNode {
	my ($self,$property) = @_;
	my @elements = split('\.',$property);
	my $result = $self;
	foreach my $element (@elements) {
		$result = $result->getChild($element);
	}
	return $result;
}

sub getProperty {
	my ($self,$property) = @_;
	my $rv = eval { $self->_getPropertyNode($property)->getValue(); };
	if($@) {
		die("Property $property doesn't exist");
	}
	return $self->_getPropertyNode($property)->getValue();
}

sub writeProps {
	my($self,$filename) = @_;
	my $fh = IO::File->new(genPath($filename),O_WRONLY()|O_TRUNC()|O_CREAT());
	die("Failed to open properties file $filename for writing") unless defined $fh;
	$fh->print($self->dump());
	$fh->close();
}

sub readProps {
	my ($self,$filename) = @_;
	my $fh = IO::File->new(genPath($filename), O_RDONLY());
	die("Failed to open properties file $filename") unless defined $fh;
	while(my $line = <$fh>) {
		chomp($line);
		next if $line =~ /^\s*\#/;
		if($line =~ /^include=(.*)/) {
			$self->readProps($self->doPropertySubstitution($1));
		} else {
#			my ($key,$value) = split("=",$line);
			$line =~ /([^=]*)=(.*)/;
			my $key = $1;
			my $value = $2;
			$self->addProperty($key,$value);
		}
	}
	return $self;
}

1;

__END__

=head1 NAME

Properties - Dilettante property management module

=head1 DESCRIPTION

This module provides all the property support functions for the builder. This functionality is all normally accessed via
delegate methods on L<Builder>. Properties extends ValueNode with extra functions required to manage an entire tree of
properties, of which a Properties instance is the root.

=head2 METHODS

Properties inherits all the methods of L<ValueNode> and adds the following additional methods.

=over 4

=item addProperty($property,$value)

Add the given value to the given property. The property must be a string. It can contain any of the notations documented
in the general documentation for builder.pl and Builder.pm. If the property doesn't exist, it will be created, and if it
does exist, the given value will be appended to any of its existing values (unless the property contains annotations which
direct otherwise).

Returns $self

=item genPath($path)

Converts a standard path (with Unix-style delimiters) to use the delimters in the package-global $PSEP variable. $PSEP is
normally set to an OS-specific value by default. This is a convenience function, which can be called either as a method or
as a standard function.

Returns platform-specific separator version of $path

=item deletePropertyValue($property,$value)

Removes a specific value from the given property if it has been set there, otherwise it does nothing. Note that this takes
the property name, but doesn't understand annotations such as '-' or '!'.

=item doPropertySubstitution($value)

Substitutes the value of a given property into a string for each instance of ${property} encountered in the string. If property
has multiple values, then the results are undefined. Note that this substitution is not recursive, but since addProperty is the
normal way to include new property values, and it calls doPropertySubstitution, this isn't normally an issue.

=item getProperty($property)

Returns the value or values of the given property. If it has one value then a scalar is returned. If there are multiple values then
an array containing all of them is returned.

=item writeProps($filename)

Writes a properties file to the given filename. The file will be created if it doesn't exist, or overwritten if it does.

=item readProps($filename)

Reads properties from the given filename and adds them to this Properties object.

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
