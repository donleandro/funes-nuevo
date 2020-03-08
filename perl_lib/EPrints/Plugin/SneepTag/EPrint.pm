######################################################################
#
# EPrints::Plugin::SneepTag::EPrint;
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

package EPrints::Plugin::SneepTag::EPrint;

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

sub tag_EPrint
{
	my( $self, $eprintid, $ownerid , $tagid, $text) = @_;
	
	my $session = $self->{session};
	my $user = EPrints::DataObj::User->new($session, $ownerid );
	my $eprint = EPrints::DataObj::EPrint->new($session, $eprintid );
	if($text){
		$self->insert_tag("eprint", $eprintid, $ownerid, $text);
	}else{
		$self->get_tag_density("eprint");
	}
	if($self->{error}){
		my $i=0;
		for my $error_msg(@{$self->{error_msgs}}){
			print "<sneep_tag_error id=\"sneep_tag_error_message_".$i."\">".$error_msg."</sneep_tag_error><br/>\n";
			$i++;
		}
	}
}

sub delete_EPrint
{
	my( $self, $eprintid, $ownerid , $tagid, $text) = @_;
	$self->delete_tag("eprint", $eprintid, $ownerid, $text);
	if($self->{error}){
		my $i=0;
		for my $error_msg(@{$self->{error_msgs}}){
			print "<sneep_tag_error id=\"sneep_tag_error_message_".$i."\">".$error_msg."</sneep_tag_error><br/>\n";
			$i++;
		}
	}

}
