package Eclipse;

use strict;
use base qw(Step);
use XML::LibXML;
use XML::LibXSLT;
use IO::All;

# add dependencies to Eclipse classpath
sub execute {
	my ($self) = @_;

	my @ecp;
	if(defined($self->builder()->getProperty('dependencies.deppaths')->{'compile'})) {
		push(@ecp,@{$self->builder()->getProperty('dependencies.deppaths')->{'compile'}}); }
	if(defined($self->builder()->getProperty('dependencies.deppaths')->{'test'})) {
		push(@ecp,@{$self->builder()->getProperty('dependencies.deppaths')->{'test'}}); }
	if(defined($self->builder()->getProperty('dependencies.deppaths')->{'provided'})) {
		push(@ecp,@{$self->builder()->getProperty('dependencies.deppaths')->{'provided'}}); }

	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_file(".classpath");
	my $root = $doc->documentElement();
	foreach my $cp (@ecp) {
		my $cpn = $doc->createElement('classpathentry');
		$cpn->setAttribute('kind', 'lib');
		$cpn->setAttribute('path', $cp);
		$root->appendChild($cpn);
	}
	$doc->serialize() > io('.classpath');
}

# get the eclipse classpath entries and add to compile scope
sub getDependencies {
	my ($self,$builder) = @_;

	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_file(".classpath");
	my $xslt = XML::LibXSLT->new();
	my $sd = $self->genPath($self->builder()->getScalarProperty('builder.lib')."/eclipseclasspath.xslt");
	my $instyle_doc = $parser->parse_file($sd);
	my $instylesheet = $xslt->parse_stylesheet($instyle_doc);
	my @ecp = split(':',$instylesheet->transform($doc));
	$self->builder()->getProperty('dependencies.deppaths')->{'compile'} = [] unless defined($self->builder()->getProperty('dependencies.deppaths')->{'compile'});
	# this push appears to do nothing... 
	push(@{$self->builder()->getProperty('dependencies.deppaths')->{'compile'}});
}

1;


__END__

=head1 NAME

Eclipse - Dilettante Eclipse integration module

=head1 DESCRIPTION

Eclipse provides a default action which injects all dependencies of the module into the Eclipse classpath for the Eclipse
project this module is contained within, including any transitive dependencies. It does this simply be relying on the
dependencies.deppaths which is generally constructed via the L<Dependencies> module.

In addition another action, getDependencies, is provided which inserts the contents of the Eclipse classpath into the compile
scope of dependencies.deppaths. Note that this is insufficient to allow Builder to record these dependencies in the
.dependencies file, but it will allow compilation, etc. and can be useful as a way to get tests working or deal with certain
situations where Eclipse plugins interject dependency information. Only dependencies in the Eclipse standard 'lib' classpath
entries can be processed this way, dependencies in other containers are not accessible to Dilettante.

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
