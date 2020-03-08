######################################################################
#
# EPrints::Plugin::SneepComment::Update;
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

package EPrints::Plugin::SneepComment::Update;

use Unicode::String qw( utf8 );
use EPrints::Plugin::SneepComment;

@ISA = ( "EPrints::Plugin::SneepComment" );

use strict;
use POSIX qw(strftime);

sub new
{
	my( $class, %params ) = @_;

	my( $self ) = $class->SUPER::new( %params );

	$self->{name} = "Update comments";
#	$self->{visible} = "all";
#	$self->{suffix} = ".xml";
#	$self->{mimetype} = "text/xml";

	return $self;
}


sub comment_Update
{
	my( $self, $script, $object, $ownerid, $commentid, $text, $format, $title) = @_;

	my $session = $self->{session};

	$self->{ownerid} = $ownerid;	
	$self->{objecttype} = $self->get_object_class_name($object);
	$self->{objectid} = $object->get_id;

	if(! defined $commentid){ $self->error( $session->phrase("sneep/comment:no_commentid" ), $self->{objectid}, $ownerid, $commentid);}

	my $comment = EPrints::DataObj::SneepComment->new($session, $commentid);
	if($comment->get_value('security') eq 'private'){
		$self->{is_note} = 1;
	}

	$comment->set_value("text", $text);
	#This bit can maybe go in an auto_update script ??
	my $lastmod = strftime "%Y-%m-%d %H:%M:%S", localtime;
	$comment->set_value("lastmod", $lastmod);
	if(defined $title){
		$comment->set_value("title", $title);
	}
	
	$comment->commit or $self->error( $session->phrase("sneep/comment:comment_not_updated" ), $self->{objectid}, $ownerid, $commentid);
	
	if($self->{is_note}){
		$session->redirect( $session->get_repository->get_conf("perl_url")."/users/note/".$self->{objectid}."/".$self->{objecttype} );
	}else{
		$session->redirect( $session->get_repository->get_conf("perl_url")."/users/comment/".$self->{objectid}."/".$self->{objecttype} );
	}
	exit;
}

1;
