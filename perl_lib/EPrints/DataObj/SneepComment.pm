######################################################################
#
# EPrints::DataObj::SneepComment
#
######################################################################
#
#  This file is part of SNEEP.
#  
#  Copyright (c) 2000-2007 University of London Computer Centre, UK. WC1N 1DZ.
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


=pod

=head1 NAME

B<EPrints::DataObj::SneepComment> - A single comment.

=head1 DESCRIPTION

SneepComment represents a single comment from a user - this may be associated with 
one of a number of different objetcs.

This class is a subclass of DataObj, with the following metadata fields: 

=over 4

=item commentid (int)

The unique ID of the comment.
 
=item ownerid (itemref)

The id number of the user to which this comment belongs.

=item objectid (itemref)

The id number of the object with which this comment is associated.

=item object_type (text or maybe int or even a namedset?)

The type of the object with which this comment is associated. (EPrint, Documment, User, etc)

=item created (datetime)

The date and time at which the comment was created

=item lastmod (datetime)

The date and time at which the comment was last modified

=item text (text)

The text of the comment. Allows a subset of html which can be defined in the sneep.xml config file.

=item security (namedset)

The security type of this comment - who can view it. One of the types
of the dataset "security".

=back

SneepComment has all the methods of dataobj with the addition of the following.

=over 4

=cut

######################################################################
#
# INSTANCE VARIABLES:
#
#  From DataObj.
#
######################################################################

package EPrints::DataObj::SneepComment;

@ISA = ( 'EPrints::DataObj' );

use EPrints;
#use EPrints::Search;

#use File::Basename;
#use File::Copy;
#use Cwd;
#use Fcntl qw(:DEFAULT :seek);

#use URI::Heuristic;

use strict;


######################################################################
=pod

=item $metadata = EPrints::DataObj::SneepComment->get_system_field_info

Return an array describing the system metadata of the SneepComment dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;
	
	return 
	( 
		{ name=>"commentid", type=>"int", required=>1, show_in_html=>0, can_clone=>0 },

		{ name=>"ownerid", type=>"int", required=>1, show_in_html=>0, can_clone=>0 },

#		{ name=>"eprintid", type=>"int", required=>1, show_in_html=>0, can_clone=>0 },

		{ name=>"objectid", type=>"int", required=>1, show_in_html=>0, can_clone=>0 },

		{ name=>"object_type", type=>"text", required=>1 },
	
		{ name=>"created", type=>"text", required=>1 },	 #this and that below are really datetimes but would need a metafield definition

		{ name=>"lastmod", type=>"text", required=>1 },	

		{ name=>"text", type=>"text", input_cols=>40 },

		{ name=>"title", type=>"text", input_cols=>40 },

		{ name=>"security", type=>"text", required=>1, input_rows=>1 },
	);
}


######################################################################
=pod

=item $thing = EPrints::DataObj::SneepComment->new( $session, $commentid )

Return the SneepComment with the given $commentid, or undef if it does not
exist.

=cut
######################################################################

sub new
{
	my( $class, $session, $commentid ) = @_;
	
	return $session->get_database->get_single( 
		$session->get_repository->get_dataset( "sneep_comment" ),
		$commentid );
}
######################################################################
=pod

=item $comment = EPrints::DataObj::SneepComment->new_from_data( $session, $data )

Construct a new EPrints::DataObj::SneepComment based on the ref to a hash of metadata.

=cut
######################################################################
sub new_from_data
{
	my( $class, $session, $known ) = @_;

	return $class->SUPER::new_from_data(
			$session,
			$known,
			$session->get_repository->get_dataset( "sneep_comment" ) );
}

######################################################################
#
# $comment->register_parent( $object )
#
# Give the document the EPrints::DataObj::XXX object that it belongs to.
#
# This may cause reference loops, but it does avoid two identical
# EPrints objects existing at once.
#
######################################################################

#sub register_parent
#{
#	my( $self, $parent ) = @_;
#
#	$self->{object} = $parent;
#}

######################################################################
=pod

=item $boolean = $doc->is_public()

True if this document has no security set and is in the live archive.

=cut
######################################################################
=comment
sub is_public
{
	my( $self ) = @_;

	my $eprint = $self->get_eprint;

	return 0 if( $self->get_value( "security" ) ne "public" );

	return 0 if( $eprint->get_value( "eprint_status" ) ne "archive" );

	return 1;
}
=cut
######################################################################
=pod

=item $url = $doc->get_url( [$file] )

Return the full URL of the document. Overrides the stub in DataObj.

If file is not specified then the "main" file is used.

=cut
######################################################################
=comment
sub get_url
{
	my( $self, $file ) = @_;

	$file = $self->get_main unless( defined $file );

	# just in case we don't *have* a main part yet.
	return $self->get_baseurl unless( defined $file );

	# unreserved characters according to RFC 2396
	$file =~ s/([^-_\.!~\*'\(\)A-Za-z0-9])/sprintf('%%%02X',ord($1))/ge;
	
	return $self->get_baseurl.$file;
}
=cut
######################################################################
=pod

=item $success = $doc->commit

Commit any changes that have been made to this object to the
database.

(might) Call "set_sneep_comment_automatic_fields" in the ArchiveConfig first to
set any automatic fields that may be needed.

=cut
######################################################################

sub commit
{
	my( $self, $force ) = @_;

	my $dataset = $self->{session}->get_repository->get_dataset( "sneep_comment" );

#	$self->{session}->get_repository->call( "set_sneep_comment_automatic_fields", $self );

	if( !defined $self->{changed} || scalar( keys %{$self->{changed}} ) == 0 )
	{
		# don't do anything if there isn't anything to do
		return( 1 ) unless $force;
	}
	#Should we keep rev numbers for comments??? not right now.
#	$self->set_value( "rev_number", ($self->get_value( "rev_number" )||0) + 1 );	

	$self->tidy;
	my $success = $self->{session}->get_database->update(
		$dataset,
		$self->{data} );
	
	$self->queue_changes;
	
	if( !$success )
	{
		my $db_error = $self->{session}->get_database->error;
		$self->{session}->get_repository->log( "Error committing Comment ".$self->get_value( "commentid" ).": $db_error" );
	}
	
	return( $success );	
}

######################################################################
=pod

=item $success = $comment->remove

Remove this comment from the database.

=cut
######################################################################

sub remove
{
	my( $self ) = @_;
	
	my $success = 1;

	#Probably need to add some tidying if a comment is threaded... what happens to comments that reference it?

	# remove user record
	my $ds = $self->{session}->get_repository->get_dataset( "sneep_comment" );
	$success = $success && $self->{session}->get_database->remove(
		$ds,
		$self->get_value( "commentid" ) );
	
	return( $success );
}

######################################################################
# =pod
# 
# =item $comment = EPrints::DataObj::SneepComment::create( $session, $object, $data )
# 
# Create a new comment in the database.
# 
# =cut
######################################################################

sub create
{
	my( $session, $data ) = @_;

	return EPrints::DataObj::SneepComment->create_from_data( 
		$session, 
		$data, 
		$session->get_repository->get_dataset( "sneep_comment" ) );
}

######################################################################
# =pod
# 
# =item $dataobj = EPrints::DataObj->create_from_data( $session, $data, $dataset )
# 
# Create a new object of this type in the database. 
# 
# $dataset is the dataset it will belong to. 
# 
# $data is the data structured as with new_from_data.
# 
# =cut
######################################################################

sub create_from_data
{
	my( $class, $session, $data, $dataset ) = @_;

	my $new_comment = $class->SUPER::create_from_data( $session, $data, $dataset );

	$session->get_database->counter_minimum( "commmentid", $new_comment->get_id );

	return $new_comment;
}

######################################################################
=pod

=item $defaults = EPrints::DataObj::EPrint->get_defaults( $session, $data )

Return default values for this object based on the starting data.

=cut
######################################################################

sub get_defaults
{
	my( $class, $session, $data ) = @_;

	if( !defined $data->{commentid} )
	{ 
		my $new_id = $session->get_database->counter_next( "commentid" );
		$data->{commentid} = $new_id;
	}

#	$session->get_repository->call(
#		"set_comment_defaults",
#		$data,
#		$session );

	return $data;
}

######################################################################
=pod

=item $problems = $doc->validate( [$for_archive] )

Return an array of XHTML DOM objects describing validation problems
with the entire document, including the metadata and repository config
specific requirements.

A reference to an empty array indicates no problems.

=cut
######################################################################
=comment
sub validate
{
	my( $self, $for_archive ) = @_;

	return [] if $self->get_eprint->skip_validation;

	my @problems;

	unless( EPrints::Utils::is_set( $self->get_type() ) )
	{
		# No type specified
		my $fieldname = $self->{session}->make_element( "span", class=>"ep_problem_field:documents" );
		push @problems, $self->{session}->html_phrase( 
					"lib/document:no_type",
					fieldname=>$fieldname );
	}
	
	# System default checks:
	# Make sure there's at least one file!!
	my %files = $self->files();

	if( scalar keys %files ==0 )
	{
		my $fieldname = $self->{session}->make_element( "span", class=>"ep_problem_field:documents" );
		push @problems, $self->{session}->html_phrase( "lib/document:no_files", fieldname=>$fieldname );
	}
	elsif( !defined $self->get_main() || $self->get_main() eq "" )
	{
		# No file selected as main!
		my $fieldname = $self->{session}->make_element( "span", class=>"ep_problem_field:documents" );
		push @problems, $self->{session}->html_phrase( "lib/document:no_first", fieldname=>$fieldname );
	}
		
	# Site-specific checks
	push @problems, $self->{session}->get_repository->call( 
		"validate_document", 
		$self, 
		$self->{session},
		$for_archive );

	return( \@problems );
}

######################################################################
#
# $boolean = $doc->user_can_view( $user )
#
# Return true if this documents security settings allow the given user
# to view it.
#
######################################################################

sub user_can_view
{
	my( $self, $user ) = @_;

	if( !defined $user )
	{
		$self->{session}->get_repository->log( '$doc->user_can_view called with undefined $user object.' );
		return( 0 );
	}

	my $result = $self->{session}->get_repository->call( 
		"can_user_view_document",
		$self,
		$user );	

	return( 1 ) if( $result eq "ALLOW" );
	return( 0 ) if( $result eq "DENY" );

	$self->{session}->get_repository->log( "Response from can_user_view_document was '$result'. Only ALLOW, DENY are allowed." );
	return( 0 );

}
=cut
1;

######################################################################
=pod

=back

=cut

