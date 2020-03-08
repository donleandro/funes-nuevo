######################################################################
#
# EPrints::Plugin::SneepComment::Add;
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


package EPrints::Plugin::SneepComment::Add;

use Unicode::String qw( utf8 );

@ISA = ( "EPrints::Plugin::SneepComment" );

use strict;
use POSIX qw(strftime);

sub new
{
	my( $class, %params ) = @_;

	my( $self ) = $class->SUPER::new( %params );

	$self->{name} = "Add comments";

	return $self;
}


sub comment_Add
{
	my( $self, $script, $object, $ownerid, $commentid, $text, $format, $title) = @_;

	my $session = $self->{session};

	$self->{ownerid} = $ownerid;
	$self->{objecttype} = $self->get_object_class_name($object);
	$self->{objectid} = $object->get_id;
	$self->{is_note} = 0;
	if($script eq "note"){
		$self->{is_note} = 1;
	}

	if(! defined $self->{objectid}){ $self->error( $session->phrase("sneep/comment:no_objectid" ), $self->{objectid}, $ownerid);}
	
	my $created = strftime "%Y-%m-%d %H:%M:%S", localtime;
	my $lastmod = $created;
	#eprintid will become objectid and have an associated object type.... soon
	my $data = {};
	$data->{ownerid}=$ownerid;
	$data->{object_type}=lc $self->{objecttype};
	$data->{objectid}=$self->{objectid};
	$data->{created}=$created;
	$data->{lastmod}=$lastmod;
	$data->{text}=$text;
	if($self->{is_note}){
		$data->{security}='private';
		$data->{title}=$title;
	}else{
		$data->{security}='public';
	}
	
	my $comment_ds = $session->get_repository->get_dataset("sneep_comment");
	my $comment = $comment_ds->create_object($session, $data);

	if($self->{is_note}){
		$session->redirect( $session->get_repository->get_conf("perl_url")."/users/note/".$self->{objectid}."/".$self->{objecttype} );
	}else{
		$session->redirect( $session->get_repository->get_conf("perl_url")."/users/comment/".$self->{objectid}."/".$self->{objecttype} );
	}
#	$session->terminate;  #I should terminate here but it cuses an error... maybe I'm only meant to in cgi scripts?
	exit;
}

1;
