######################################################################
#
# EPrints::Plugin::SneepComment_via_DataObj;
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


package EPrints::Plugin::SneepComment_via_DataObj;
use strict;
our  @ISA = qw/ EPrints::Plugin /;

#######################################################################
=pod

=item $comments = EPrints::DataObj->get_comments( )

Get all the comments associated with a given EPrints::DataObj 

=cut
#######################################################################

sub EPrints::DataObj::get_SneepComments
{
	my( $self ) = @_;

	my $search_object_value = lc $self->get_dataset->confid;
	my $search_id_value = $self->get_id;
	
	my $ds = $self->{session}->get_repository->get_dataset( 'sneep_comment' );

	my $searchexp = EPrints::Search->new(
		session=>$self->{session},
		dataset=>$ds);

	$searchexp->add_field(
		$ds->get_field( 'object_type' ),
		$search_object_value );

	$searchexp->add_field(
		$ds->get_field( 'objectid' ),
		$search_id_value );

	$searchexp->add_field(
		$ds->get_field( 'security' ),
		'public' );

	my $searchid = $searchexp->perform_search;
	my @comments = $searchexp->get_records;
	$searchexp->dispose;
#	foreach my $comment ( @comments )
#	{
#		print $comment->get_value("text")."<br/>";
#	#	$comment->register_parent( $self );  #sounds like it might be useful....?
#	}
	if(scalar @comments == 0){
		return undef;
	}else{
		return \@comments;
	}
}

1;	
