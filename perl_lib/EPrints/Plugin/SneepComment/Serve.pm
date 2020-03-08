######################################################################
#
# EPrints::Plugin::SneepComment::Serve;
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

package EPrints::Plugin::SneepComment::Serve;

use Unicode::String qw( utf8 );
use EPrints::Plugin::SneepComment;

@ISA = ( "EPrints::Plugin::SneepComment" );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my( $self ) = $class->SUPER::new( %params );

	$self->{name} = "Serve comments";
	$self->{visible} = "all";
	$self->{suffix} = ".xml";
	$self->{mimetype} = "text/xml";

	return $self;
}

sub comment_Serve
{
	my( $self, $script, $object, $ownerid, $commentid, $text, $format) = @_;

	$self->{ownerid} = $ownerid;
#	$self->{objecttype} = $object->get_dataset->confid;
	$self->{objecttype} = $self->get_object_class_name($object);
	$self->{objectid} = $object->get_id;
	$self->{object} = $object;
	$self->{is_note} = 0;
	if($script eq "note"){
		$self->{is_note} = 1;
	}

	if($format eq "HTML"){
		$self->print_HTML;
	}else{
		$self->print_XML;
	}
}

sub print_XML
{
	my( $self ) = @_;
	my $session = $self->{session};

	if($self->{is_note}){
		unless($self->{notes} = $self->{object}->get_SneepNotes($self->{ownerid})){
			print "<sneep_notes></sneep_notes>";
		}else{
			$self->notes_to_XML();
			print EPrints::XML::to_string( $self->{notes_xml} );
		}
	}else{
		unless($self->{comments} = $self->{object}->get_SneepComments()){
			print "<sneep_comments></sneep_comments>";
		}else{
			$self->comments_to_XML();
			print EPrints::XML::to_string( $self->{comments_xml} );
		}
	}
}

sub print_HTML
{

open (MYFILE, '>>/tmp/Serve.txt');
 	print MYFILE "Inicio\n\n";

	my( $self ) = @_;
	my $session = $self->{session};
	
	if($self->{is_note}){
		unless($self->{notes} = $self->{object}->get_SneepNotes($self->{ownerid})){
                        print EPrints::XML::to_string( $session->html_phrase("sneep/note:no_notes" ) );
		}else{
			$self->notes_to_HTML();
			print EPrints::XML::to_string( $self->{notes_html} );
		}
	}else{
		unless($self->{comments} = $self->{object}->get_SneepComments()){
			print EPrints::XML::to_string( $session->html_phrase("sneep/comment:no_comments" ) );
	print MYFILE "NO Comments\n\n";	}else{
			$self->comments_to_HTML();
			print EPrints::XML::to_string( $self->{comments_html} );
print MYFILE "Comments\n\n";
		}
	}
close (MYFILE); 
}
1;
