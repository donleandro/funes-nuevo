######################################################################
#
# EPrints::Plugin::SneepNote_via_DataObj;
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


package EPrints::Plugin::SneepNote_via_DataObj;
use strict;
our  @ISA = qw/ EPrints::Plugin /;

#######################################################################
=pod

=item $notes = EPrints::DataObj->get_notes( $ownerid )

Get all the notes associated with a given EPrints::DataObj for a given owner...

=cut
#######################################################################

sub EPrints::DataObj::get_SneepNotes
{
	my( $self, $ownerid ) = @_;

	#First off check that the owner is the current user!!
	if($self->{session}->current_user->get_id != $ownerid){
		return undef;
	}

	my $search_object_value = lc $self->get_dataset->confid;
	my $search_id_value = $self->get_id;

	#We use the comments dataset for notes	
	my $ds = $self->{session}->get_repository->get_dataset( 'sneep_comment' );

	my $searchexp = EPrints::Search->new(
		session=>$self->{session},
		dataset=>$ds,
		custom_order=>"created/lastmod" );

	$searchexp->add_field(
		$ds->get_field( 'object_type' ),
		$search_object_value );

	$searchexp->add_field(
		$ds->get_field( 'objectid' ),
		$search_id_value );

	#The important difference being they are flagged as private
	$searchexp->add_field(
		$ds->get_field( 'security' ),
		'private' );
	#and belong to a specific user (or owner)
	$searchexp->add_field(
		$ds->get_field( 'ownerid' ),
		$ownerid );

	my $searchid = $searchexp->perform_search;
	my @notes = $searchexp->get_records;
	$searchexp->dispose;
#	foreach my $notes ( @notes )
#	{
#		print $comment->get_value("text")."<br/>";
#	#	$comment->register_parent( $self );  #sounds like it might be useful....?
#	}
	if(scalar @notes == 0){
		return undef;
	}else{
		return \@notes;
	}
}

1;	
