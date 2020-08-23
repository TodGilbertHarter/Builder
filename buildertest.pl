#! /usr/bin/perl

use strict;
use lib "/mnt/deltaopt/development/builder";
use Builder;

my $builder = Builder->new();
$builder->writeProps("testwrite.properties");
$builder->execute();

__END__

=head1 NAME

Dilettante - builder test script

=head1 SYNOPSIS

./buildertest.pl

=head1 DESCRIPTION

Perform a very basic fixed test of the Builder.pm module. This should verify that the Dilettante
core modules compile properly. It will output a dump of all default property values that were configured
via builder's default configuration policies.

=head1 USAGE

buildertest.pl executes the builder->writeProps function on an instantiated Builder.pm. It doesn't have any
parameters, however, you can set environment variables.

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
