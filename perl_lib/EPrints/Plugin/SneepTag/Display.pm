######################################################################
#
# EPrints::Plugin::SneepTag::Comment;
#
######################################################################
#
#  This file is part of SNEEP.
#  
#  Copyright (c) 2008 University of London Computer Centre, UK. WC1N 1DZ.
#  
#  SNEEP is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  SNEEP is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with SNEEP; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
######################################################################

package EPrints::Plugin::SneepTag::Display;

use strict;
use Switch;

our @ISA = qw/ EPrints::Plugin::SneepTag /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{tag_type} = "EPrint";

	return $self;
}

# $mode is either "tagname" or "disp_opt"
# $action will either be a tagname if $mode is "tagname" or some display option if...
# @tag_types will be the item types to group the tags by (EPrint, Document,etc...) or "All"
# @tag_types is an array created from the colon separated list "EPrint:Comment:User" or some 
# such passed to the cgi script /cgi/tag

sub tag_Display
{
	my( $self, $mode, $action, $tag_types, $filter, $eprint) = @_;

	my $data;
	$self->{item}=$eprint;
	if( $mode eq "tagname"){
		my $tag_text = $action;
		$action = "index";
		$data = $self->get_tag_index($tag_text, $tag_types); #This returns an arrayref

	}elsif( $mode =~ /disp_opt/){
		# Returns a hash of tags and their number of 'item hits',
		# either within a type of item (EPrint, Document etc) or 
		# if tag_type eq "All" across all items
		$data = $self->get_tag_density($tag_types, $filter, $eprint); #This returns a hashref
	}else{
		print "unknown mode error here please<br/>";
		return;
	}
	eval("\$self->render_tag_$action(\$data,\$filter);");
	print EPrints::XML::to_string( $self->{tags_html} );

	if($self->{error}){
		print $self->{error_msg}."<br/>";
	}
}

1;
