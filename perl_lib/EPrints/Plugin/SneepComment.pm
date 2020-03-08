######################################################################
#
# EPrints::Plugin::SneepComment;
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

package EPrints::Plugin::SneepComment;

use strict;
use Switch;

our @ISA = qw/ EPrints::Plugin /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{db_table} = "sneep_comment";
	$self->{error} = undef;
	$self->{component_name} = "comment";

	return $self;
}

sub comments_to_XML
{
	my( $self, $comments) = @_;

	if(!defined $self->{comments}){
		EPrints::abort( "No comments defined" );
	}
	my $session = $self->{session};
	my $comments_xml=$session->make_doc_fragment();
	my $comments_element=$session->make_element("sneep_comments");
	foreach my $comment(@{$self->{comments}}){
		my $comment_element=$session->make_element("sneep_comment", 
							   commentid=>$comment->get_value("commentid"), 
							   objectid=>$comment->get_value("objectid"), 
							   object_type=>$comment->get_value("object_type"), 
						 	   ownerid=>$comment->get_value("ownerid"), 
							   created=>$comment->get_value("created"), 
							   lastmod=>$comment->get_value("lastmod"));

		$comment_element->appendChild( $session->make_text( $comment->get_value("text") ) );
		$comments_element->appendChild($comment_element);
	}
	$comments_xml->appendChild($comments_element);

	$self->{comments_xml} = $comments_xml;

}

sub notes_to_XML
{
	my( $self, $notes) = @_;

	if(!defined $self->{notes}){
		EPrints::abort( "No notes defined" );
	}
	my $session = $self->{session};
	my $notes_xml=$session->make_doc_fragment();
	my $notes_element=$session->make_element("sneep_notes");
	foreach my $note(@{$self->{notes}}){
		my $note_element=$session->make_element("sneep_note", 
							   noteid=>$note->get_value("commentid"), 
							   objectid=>$note->get_value("objectid"), 
							   object_type=>$note->get_value("object_type"), 
						 	   ownerid=>$note->get_value("ownerid"), 
							   created=>$note->get_value("created"), 
							   lastmod=>$note->get_value("lastmod"));

		$note_element->appendChild( $session->make_text( $note->get_value("text") ) );
		$notes_element->appendChild($note_element);
	}
	$notes_xml->appendChild($notes_element);

	$self->{notes_xml} = $notes_xml;

}

# Returns an HTML unordered list as a XML::DOM object
# each <li> containing a comment
sub comments_to_HTML
{


	my( $self ) = @_;

	my $ownerid = $self->{ownerid};
	my $objectid = $self->{objectid};
	my $session = $self->{session};
	my $objecttype_lc = lc $self->{objecttype};

	my $page=$session->make_doc_fragment();
	
	my $intro_p = $session->make_element("p", class=>"sneep_c_intro_p");
	my $num_comments = scalar @{$self->{comments}};
	my $s="";
	if($num_comments>1){ $s="s"; }
	$intro_p->appendChild($session->make_text($num_comments." comentario$s on \"".$self->{object}->get_value("title")."\""));
	$page->appendChild($intro_p);

	my $comment_list = $session->make_element( "ul", id=>"sneep_c_list:".$objecttype_lc );
	my $usertype = 'anon';
	if(defined $ownerid){
		my $user = EPrints::DataObj::User->new($session, $ownerid );
		$usertype = $user->get_value("usertype");
	}
	foreach my $comment(@{$self->{comments}}){
	
		# Fetch the user object for this comment;
		my $c_u_id = $comment->get_value("ownerid");
		my $c_user = EPrints::DataObj::User->new($session, $c_u_id );

		my $li = $session->make_element("li", class=>"sneep_c_li");
		$comment_list->appendChild ( $li );

		# dyno_element will be a form if the comment belongs to the user otherwise it'll be a span
		my $dyno_element;
		if(defined $ownerid && ($c_u_id eq $ownerid || $usertype eq "admin")){	
			$dyno_element = $session->make_element("form", 
								id=>"sneep_c_edit_form_".$comment->get_value("commentid").":".$objecttype_lc,
								action=>"",
								method=>"post" );
		}else{
			$dyno_element = $session->make_element("span");
		}
		$li->appendChild($dyno_element);

		# The header for each comment	
		my $comment_header_span = $session->make_element("span", 
								id=>"sneep_c_edit_header_".$comment->get_value("commentid").":".$objecttype_lc, 
								class=>"sneep_c_header");
		$dyno_element->appendChild($comment_header_span);
		my $comment_header_text = $c_user->render_description;
		$comment_header_text->appendChild( $session->make_text(" says "));
		my $comment_time_span = $session->make_element("span", class=>"sneep_c_time_span");
		$comment_time_span->appendChild($session->make_text( "(".$self->timestamp_to_text($comment->get_value("created")).")" ) );
		$comment_header_span->appendChild( $comment_header_text );
		$comment_header_span->appendChild($comment_time_span);
		$comment_header_span->appendChild($session->make_text(":"));


		# If the user owns this comment add tools
		if(defined $ownerid && ($c_u_id eq $ownerid || $usertype eq "admin")){	
			my $comment_tools_span = $session->make_element("span", 
									id=>"sneep_c_tools_".$comment->get_value("commentid").":".$objecttype_lc, 
									class=>"sneep_c_tools" );
			$dyno_element->appendChild($session->render_nbsp);
			$dyno_element->appendChild($comment_tools_span);
			# One button and three inputs in the tools span
			my $edit_button = $session->make_element("button", 
								class=>"sneep_button_as_link",
								onclick=>"sneep_comment_toggle_edit('".$comment->get_value("commentid")."',this,'".
									$session->phrase("sneep/comment:edit")."','".
									$session->phrase("sneep/comment:cancel")."'); return false;" );
			$edit_button->appendChild( $session->html_phrase( "sneep/comment:edit" ) );

			my $img_src = $session->get_repository->get_conf( "base_url" )."/style/images/ajax-loader.gif";
			my $delete_wait_icon = $session->make_element( "img", id=>"sneep_wait_delete_".$comment->get_value("commentid").":".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );

			my $delete_input = $session->make_element("input",
								type=>"submit",
								class=>"sneep_button_as_link",
								id=>"sneep_c_delete_".$comment->get_value("commentid").":".$objecttype_lc,
								onclick=>"SneepCommentDelete('".$self->{objecttype}."', '".$objectid."','".$comment->get_value("commentid")."','sneep_wait_delete_".$comment->get_value("commentid")."'); return false;",
								name=>"delete",
								value=>$session->phrase("sneep/comment:delete"));
			my $save_wait_icon = $session->make_element( "img", id=>"sneep_wait_save_".$comment->get_value("commentid").":".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );

			my $save_input = $session->make_element("input",
        	                         			type=>"submit",
								class=>"sneep_button_as_link",
								id=>"sneep_c_edit_save_".$comment->get_value("commentid").":".$objecttype_lc,
								onclick=>"SneepCommentUpdate('".$self->{objecttype}."', '".$objectid."','".$comment->get_value("commentid")."','sneep_wait_save_".$comment->get_value("commentid")."'); return false;",
								name=>"save_update",
								value=> $session->phrase("sneep/comment:save") );
								
			my $hidden_input = $session->make_element("input",
								type=>"hidden",
								name=>"commentid",
								value=>$comment->get_value("commentid") );

			$comment_tools_span->appendChild($edit_button);
			$comment_tools_span->appendChild( $session->html_phrase( "sneep/comment:tools_divider" ) );
			$comment_tools_span->appendChild($delete_input);
			$comment_tools_span->appendChild($delete_wait_icon);
			$comment_tools_span->appendChild( $session->html_phrase( "sneep/comment:tools_divider" ) );
			$comment_tools_span->appendChild($save_input);
			$comment_tools_span->appendChild($save_wait_icon);
			$comment_tools_span->appendChild($hidden_input);
		}

		# Now for the comment text itself
		# Use this xml parser to turn comment text into an XML object as it may contain markup in it already
		# Note the $text_str in the code a bit further below...
		
		
		# my $parser = XML::LibXML->new();

	
		my $p = $session->make_element("p", 
						id=>"sneep_c_text_p_".$comment->get_value("commentid").":".$objecttype_lc,
						class=>"sneep_comment_text");
		$dyno_element->appendChild($p);
		
		# Here is a span what is only used for no JS or init conditions
		my $text_str = "<span id=\"sneep_c_init_text_".$comment->get_value("commentid")."\" class=\"sneep_comment_text_span\">".$comment->get_value("text")."</span>";
		my $comment_init_text_span = EPrints::Extras::render_xhtml_field($session, undef, $text_str ) or EPrints::abort( "Could not parse xml: $!\n $text_str" );
		$p->appendChild($comment_init_text_span);

		# Here is a span what stays hidden and is cloned by and used by the JS in 80_sneep_comment.js 
		$text_str = "<span id=\"sneep_c_text_".$comment->get_value("commentid").":".$objecttype_lc."\" style=\"display: none;\" class=\"sneep_comment_text_span\">".$comment->get_value("text")."</span>";
		my $comment_text_span = EPrints::Extras::render_xhtml_field($session, undef, $text_str ) or EPrints::abort( "Could not parse xml: $!\n $text_str" );
		$dyno_element->appendChild($comment_text_span);

		# This span contains the texarea for editing a coment (only used if user owns comment);
		if(defined $ownerid && ($c_u_id eq $ownerid || $usertype eq "admin")){	
			my $comment_edit_span = $session->make_element("span", 
								id=>"sneep_c_edit_span_".$comment->get_value("commentid").":".$objecttype_lc);

			$dyno_element->appendChild($comment_edit_span);
			my $comment_edit_textarea = $session->make_element("textarea", 
								    cols=>$session->phrase("sneep/comment:edit_textarea_cols"),
								    rows=>$session->phrase("sneep/comment:edit_textarea_rows"),
								    name=>"comment_text_update_".$comment->get_value("commentid"),
								    id=>"sneep_c_edit_textarea_".$comment->get_value("commentid").":".$objecttype_lc,
							      	    onkeyup=>"setTextArea(this)",
								    onfocus=>"setTextArea(this)",
								    class=>"sneep_comment_edit_textarea" );
			$comment_edit_span->appendChild($comment_edit_textarea);
			
		}
		# There should be someway that displays whether an edit has been undertaken by an administrator
		# a hidden input can relate admininess of the user to JS and it can highlight the fact... somehow
		if($usertype eq "admin" && $c_u_id ne $ownerid){
			my $admin_input = $session->make_element("input", 
								type=>"hidden", 
								name=>"admin_edit", 
								id=>"admin_edit_".$comment->get_value("commentid").":".$objecttype_lc, 
								value=>"1");
			$dyno_element->appendChild($admin_input);
		}
	}
	if($self->{comments}){
		$page->appendChild( $comment_list );
	}else{
		$page->appendChild( $session->html_phrase( "sneep/comment:no_comments" ) );
	}
	# Stick a span with the repo email so that the JS can access it
	my $repo_email_span = $session->make_element("span", id=>"repo_admin_email", style=>"display: none;");
	$repo_email_span->appendChild($session->make_text( $session->get_repository->get_conf( "adminemail" ) ) );
	$page->appendChild($repo_email_span);

	$self->{comments_html} = $page;
}

sub notes_to_HTML
{
	my( $self ) = @_;

	my $ownerid = $self->{ownerid};
	my $objectid = $self->{objectid};
	my $session = $self->{session};
	my $objecttype_lc = lc $self->{objecttype};

	my $page=$session->make_doc_fragment();

	my $note_list = $session->make_element( "ul", id=>"sneep_n_list:".$objecttype_lc );
	my $usertype = 'anon';
	my $user;
	if(defined $ownerid){
		$user = EPrints::DataObj::User->new($session, $ownerid );
		$usertype = $user->get_value("usertype");
	}
	my $intro_p = $session->make_element("p", class=>"sneep_n_intro_p");
	my $num_notes = scalar @{$self->{notes}};
	my $s="";
	if($num_notes>1){ $s="s"; }
	$intro_p->appendChild($session->make_text($num_notes." note$s on \"".$self->{object}->get_value("title")."\""));
	$intro_p->appendChild($session->make_text(" for "));
	$intro_p->appendChild($user->render_description);
	$page->appendChild($intro_p);

	foreach my $note(@{$self->{notes}}){
	
		# Fetch the user object for this note;
		my $c_u_id = $note->get_value("ownerid");
		my $c_user = EPrints::DataObj::User->new($session, $c_u_id );

		my $li = $session->make_element("li", class=>"sneep_n_li");
		$note_list->appendChild ( $li );

		# dyno_element will be a form if the note belongs to the user otherwise it'll be a span
		# In this case it will always be a form cos notes are private.
		my $dyno_element;

		$dyno_element = $session->make_element("form",
							id=>"sneep_n_edit_form_".$note->get_value("commentid").":".$objecttype_lc,
							action=>"",
							method=>"post" );
		$li->appendChild($dyno_element);

		# The header for each note	
		my $note_header_span = $session->make_element("span", 
								id=>"sneep_n_edit_header_".$note->get_value("commentid").":".$objecttype_lc, 
								class=>"sneep_n_header");
		$dyno_element->appendChild($note_header_span);
		my $note_header_text = $session->make_element("span");
		#title span
		my $title_span = $session->make_element("span", 
							id=>"sneep_n_title_".$note->get_value("commentid").":".$objecttype_lc, 
							class=>"sneep_note_title_span");
		$title_span->appendChild($session->make_text($note->get_value("title")));
		$note_header_text->appendChild( $title_span );
		my $note_time_span = $session->make_element("span", class=>"sneep_n_time_span");
		$note_time_span->appendChild( $session->make_text(" (".$self->timestamp_to_text($note->get_value("created"))."):" ) );
		$note_header_text->appendChild( $note_time_span );
		$note_header_span->appendChild( $note_header_text  );

		my $note_tools_span = $session->make_element("span",
								id=>"sneep_n_tools_".$note->get_value("commentid").":".$objecttype_lc,
								class=>"sneep_n_tools" );
		$dyno_element->appendChild($session->render_nbsp);
		$dyno_element->appendChild($note_tools_span);
		# One button and three inputs in the tools span
		my $edit_button = $session->make_element("button", 
							class=>"sneep_button_as_link",
							onclick=>"sneep_note_toggle_edit('".$note->get_value("commentid")."',this,'".
								$session->phrase("sneep/note:edit")."','".
								$session->phrase("sneep/note:cancel")."'); return false;" );
		$edit_button->appendChild( $session->html_phrase( "sneep/note:edit" ) );

		my $img_src = $session->get_repository->get_conf( "base_url" )."/style/images/ajax-loader.gif";
		my $delete_wait_icon = $session->make_element( "img", id=>"sneep_wait_delete_".$note->get_value("commentid").":".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );

		my $delete_input = $session->make_element("input",
							type=>"submit",
							class=>"sneep_button_as_link",
							id=>"sneep_n_delete_".$note->get_value("commentid").":".$objecttype_lc,
							onclick=>"SneepNoteDelete('".$self->{objecttype}."', '".$objectid."','".$note->get_value("commentid")."','sneep_wait_delete_".$note->get_value("commentid")."'); return false;",
							name=>"delete",
							value=>$session->phrase("sneep/note:delete"));
		my $save_wait_icon = $session->make_element( "img", id=>"sneep_wait_save_".$note->get_value("commentid").":".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );

		my $save_input = $session->make_element("input",
       	                         			type=>"submit",
							class=>"sneep_button_as_link",
							id=>"sneep_n_edit_save_".$note->get_value("commentid").":".$objecttype_lc,
							onclick=>"SneepNoteUpdate('".$self->{objecttype}."', '".$objectid."','".$note->get_value("commentid")."','sneep_wait_save_".$note->get_value("commentid")."'); return false;",
							name=>"save_update",
							value=> $session->phrase("sneep/note:save") );
							
		my $hidden_input = $session->make_element("input",
							type=>"hidden",
							name=>"noteid",
							value=>$note->get_value("commentid") );

		$note_tools_span->appendChild($edit_button);
		$note_tools_span->appendChild( $session->html_phrase( "sneep/note:tools_divider" ) );
		$note_tools_span->appendChild($delete_input);
		$note_tools_span->appendChild($delete_wait_icon);
		$note_tools_span->appendChild( $session->html_phrase( "sneep/note:tools_divider" ) );
		$note_tools_span->appendChild($save_input);
		$note_tools_span->appendChild($save_wait_icon);
		$note_tools_span->appendChild($hidden_input);

		# Now for the note text itself
		# Use this xml parser to turn note text into an XML object as it may contain markup in it already
		# Note the $text_str in the code a bit further below...
#		my $parser = XML::LibXML->new();
		
		my $p = $session->make_element("p", 
						id=>"sneep_n_text_p_".$note->get_value("commentid").":".$objecttype_lc,
						class=>"sneep_note_text");
		$dyno_element->appendChild($p);
		
		# Here is a span what is only used for no JS or init conditions
		my $text_str = "<span id=\"sneep_n_init_text_".$note->get_value("commentid").":".$objecttype_lc."\" class=\"sneep_note_text_span\">".$note->get_value("text")."</span>";

		my $note_init_text_span = EPrints::Extras::render_xhtml_field( $session, undef, $text_str ) or EPrints::abort( "Could not parse xml: $!\n $text_str" );
		$p->appendChild($note_init_text_span);

		# Here is a span what stays hidden and is cloned by and used by the JS in 80_sneep_note.js 
		$text_str = "<span id=\"sneep_n_text_".$note->get_value("commentid").":".$objecttype_lc."\" style=\"display: none;\" class=\"sneep_note_text_span\">".$note->get_value("text")."</span>";
		my $note_text_span = EPrints::Extras::render_xhtml_field( $session, undef, $text_str ) or EPrints::abort( "Could not parse xml: $!\n $text_str" );
		$dyno_element->appendChild($note_text_span);

		my $note_edit_span = $session->make_element("span", 
							id=>"sneep_n_edit_span_".$note->get_value("commentid").":".$objecttype_lc);

		$dyno_element->appendChild($note_edit_span);
		my $note_edit_title = $session->make_element("input", 
							    name=>"note_title_update_".$note->get_value("commentid"),
							    id=>"sneep_n_edit_title_".$note->get_value("commentid").":".$objecttype_lc,
							    class=>"sneep_note_edit_title",
							    value=>$note->get_value("title") );
		# ADD THIS ONLY WHEN YOU HAVE FIXED sneep_note_init_notes() in js in order to hide the form elements
		$note_edit_span->appendChild($session->make_text("Note title [optional]: "));
		$note_edit_span->appendChild($note_edit_title);
		$note_edit_span->appendChild($session->make_element("br"));
		my $note_edit_textarea = $session->make_element("textarea", 
							    cols=>$session->phrase("sneep/note:edit_textarea_cols"),
							    rows=>$session->phrase("sneep/note:edit_textarea_rows"),
							    name=>"note_text_update_".$note->get_value("commentid"),
							    id=>"sneep_n_edit_textarea_".$note->get_value("commentid").":".$objecttype_lc,
						      	    onkeyup=>"setTextArea(this)",
							    onfocus=>"setTextArea(this)",
							    class=>"sneep_note_edit_textarea" );
		$note_edit_span->appendChild($note_edit_textarea);
			
		# There should be someway that displays whether an edit has been undertaken by an administrator
		# a hidden input can relate admininess of the user to JS and it can highlight the fact... somehow
		# I can't quite see why an admin would need to edit someones notes as no else will see them... but you never know.
		if($usertype eq "admin" && $c_u_id ne $ownerid){
			my $admin_input = $session->make_element("input", 
								type=>"hidden", 
								name=>"admin_edit", 
								id=>"admin_edit_".$note->get_value("commentid").":".$objecttype_lc, 
								value=>"1");
			$dyno_element->appendChild($admin_input);
		}
	}
	if($self->{notes}){
		$page->appendChild( $note_list );
	}else{
		$page->appendChild( $session->html_phrase( "sneep/note:no_notes" ) );
	}
	# Stick a span with the repo email so that the JS can access it
	my $repo_email_span = $session->make_element("span", id=>"repo_admin_email", style=>"display: none;");
	$repo_email_span->appendChild($session->make_text( $session->get_repository->get_conf( "adminemail" ) ) );
	$page->appendChild($repo_email_span);

	$self->{notes_html} = $page;
}

sub render_comment_link
{
	my ( $self, $objecttype, $objectid) = @_;

	my $session = $self->{session};
	my $objecttype_lc = lc $objecttype;
 
	my $comment_header = $session->make_element( "span", id=>"sneep_comment_link_span:".$objecttype_lc );
	my $comment_url = $session->get_repository->get_conf( "perl_url" )."/users/comment/$objectid/$objecttype"; #or not...

	my $repo_open = $session->phrase("sneep/comment:repository_open");
	
	# little loading icon
	my $img_src = $session->get_repository->get_conf( "base_url" )."/style/images/ajax-loader.gif";
	my $wait_icon = $session->make_element( "img", id=>"sneep_c_wait:".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );

	# put down an invisible marker flagging component status (hidden or unhidden)
	my $status_flag = $session->make_element("span", id=>"sneep_c_status_flag:".$objecttype_lc, style=>"display: none;");
	$status_flag->appendChild($session->make_text("0"));

	my $comment_link = $session->make_element("a", 
						  id=>"sneep_comment_link:".$objecttype_lc,
						  href=>"$comment_url", 
						  onclick=>"sneep_comment('',".$repo_open.",'".$objecttype."','".$objectid."','sneep_c_wait:".$objecttype_lc."');
						  sneep_comment_toggle('sneep_c_main:".$objecttype_lc."',this,'Mostrar comentarios','Ocultar Comentarios'); return false;" );


	$comment_link->appendChild( $session->html_phrase( "sneep/comment:link_label" ) );
	$comment_header->appendChild( $comment_link );
	$comment_header->appendChild( $wait_icon );
	$comment_header->appendChild( $status_flag );

	return $comment_header;

}

sub render_note_link
{
	my ( $self, $objecttype, $objectid) = @_;

	my $session = $self->{session};
 	my $objecttype_lc = lc $objecttype;

	my $note_header = $session->make_element( "span", id=>"sneep_note_link_span:".$objecttype_lc );
	my $note_url = $session->get_repository->get_conf( "perl_url" )."/users/note/$objectid/$objecttype"; #or not...

#	my $repo_open = $session->phrase("sneep/note:repository_open");
	
	my $img_src = $session->get_repository->get_conf( "base_url" )."/style/images/ajax-loader.gif";
	my $wait_icon = $session->make_element( "img", id=>"sneep_n_wait:".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );

	# put down an invisible marker flagging component status (hidden or unhidden)
	my $status_flag = $session->make_element("span", id=>"sneep_n_status_flag:".$objecttype_lc, style=>"display: none;");
	$status_flag->appendChild($session->make_text("0"));

	my $note_link = $session->make_element("a", 
						  id=>"sneep_note_link:".$objecttype_lc,
						  href=>"$note_url", 
						  onclick=>"sneep_note('','".$objecttype."','".$objectid."','sneep_n_wait:".$objecttype_lc."');
						  sneep_note_toggle('sneep_n_main:".$objecttype_lc."',this,'Show notes','Hide notes'); return false;" );

	$note_link->appendChild( $session->html_phrase( "sneep/note:link_label" ) );
	$note_header->appendChild( $note_link );
	$note_header->appendChild( $wait_icon );
	$note_header->appendChild( $status_flag );

	return $note_header;

}

sub render_comments_box
{
	my ( $self, $objecttype, $objectid) = @_;

	my $session = $self->{session};
	my $objecttype_lc = lc $objecttype;

	my $comment_url = $session->get_repository->get_conf( "perl_url" )."/users/comment/$objectid/$objecttype";

	# main_comment_div (sneep_c_main) holds all the comment paraphanalia save for the show comment link 
	# which is rendered by render_link and called separately from within eprint_render.pl (or whatever page the comments are embedded in)
	my $main_comment_div = $session->make_element( "div", id=>"sneep_c_main:".$objecttype_lc, class=>"sneep_c_main sneep_c_dialog" );

	# Rounded corners - Thanks to David Kane of www.wit.ie
	my $div_hd = $session->make_element("div", class=>"sneep_c_hd");
	$main_comment_div->appendChild($div_hd);
	my $div_c_empty = $session->make_element("div", class=>"sneep_c_c");
	$div_hd->appendChild($div_c_empty);

	my $div_bd = $session->make_element("div", class=>"sneep_c_bd");
	$main_comment_div->appendChild($div_bd);
	my $div_c = $session->make_element("div", class=>"sneep_c_c");
	$div_bd->appendChild($div_c);
	######################

	$div_c->appendChild($session->html_phrase("sneep/comment:comment_title"));

	# comment_div holds that comments them selves (retrived by comment/Serve)
	my $comment_div = $session->make_element( "div", id=>"sneep_c_comment:".$objecttype_lc );
	$div_c->appendChild($comment_div);
	
	# form for adding new comments (editing and deleting is done via a separate form)
	my $comment_add_form = $session->make_element( "form", method=>"post", action=>$comment_url );
	# comment_add_div has the links and buttons for adding a comment
	my $comment_add_div = $session->make_element( "div", id=>"sneep_c_add:".$objecttype_lc, class=>"sneep_c_add" );
	# comment_add_textarea (the form itself spreads between the two comment_add_X divs)
	my $comment_add_textarea_div = $session->make_element( "div", id=>"sneep_c_add_textarea:".$objecttype_lc, class=>"sneep_c_add_textarea" );
	
	# an hr between the comments and the add form
	#$div_c->appendChild( $session->make_element("hr", id=>"sneep_c_comments_end:".$objecttype_lc ) );

	$div_c->appendChild($comment_add_form);
	$comment_add_form->appendChild($comment_add_div);
	$comment_add_form->appendChild($comment_add_textarea_div);

	# Inside comment_add_div goes a button and two inputs
	my $add_button = $session->make_element("button",
					class=>"sneep_button_as_link",
					onclick=>"sneep_comment_toggle_add('sneep_c_add_textarea:".$objecttype_lc."',this,'".
						$session->phrase("sneep/comment:add")."','".
						$session->phrase("sneep/comment:cancel")."');return false;",
					id=>"sneep_c_add_button:".$objecttype_lc);
	$add_button->appendChild( $session->html_phrase("sneep/comment:add" ) );

	#wait for it...
	my $img_src = $session->get_repository->get_conf( "base_url" )."/style/images/ajax-loader.gif";
	my $wait_icon = $session->make_element( "img", id=>"sneep_wait_add:".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );
	my $save_input = $session->make_element("input",
					type=>"submit",
					class=>"sneep_button_as_link",
					onclick=>"SneepCommentAdd('".$objecttype."', '".$objectid."', 'sneep_wait_add'); return false;",
					name=>"save_add",
					value=>$session->phrase("sneep/comment:save"),
					id=>"sneep_c_add_save:".$objecttype_lc);
	# This fellow is here to help the non JS souls out there
	my $hidden_input = $session->make_element("input",
					type=>"hidden",
					name=>"add_form",
					value=>"1" );
#	$comment_add_div->appendChild($add_button);
	$comment_add_div->appendChild($session->html_phrase("sneep/comment:add_comment"));
#	$comment_add_div->appendChild( $session->html_phrase( "sneep/comment:tools_divider" ) );
	$comment_add_div->appendChild($hidden_input);
	# Inside comment_add_textarea_div... a textarea
	my $textarea = $session->make_element("textarea",
				      name=>"sneep_new_comment_text",
				      id=>"sneep_new_comment_text:".$objecttype_lc,
				      class=>"sneep_comment_add_textarea",
				      onkeyup=>"setTextArea(this)",
				      onfocus=>"setTextArea(this)",
				      cols=>$session->phrase("sneep/comment:add_textarea_cols"),
				      rows=>$session->phrase("sneep/comment:add_textarea_rows"));
	$comment_add_textarea_div->appendChild( $textarea);
	$comment_add_textarea_div->appendChild( $session->make_element("br"));
	$comment_add_textarea_div->appendChild( $save_input);
	$comment_add_textarea_div->appendChild( $wait_icon );

	# Rounded corners - Thanks to David Kane
	my $div_ft = $session->make_element("div", class=>"sneep_c_ft");
	$main_comment_div->appendChild($div_ft);
	my $div_ftl = $session->make_element("div", class=>"sneep_c_ft-l");
	$div_ft->appendChild($div_ftl);
	######################

	return $main_comment_div;
}

sub render_notes_box
{
	my ( $self, $objecttype, $objectid) = @_;
	
	my $session = $self->{session};
	my $objecttype_lc = lc $objecttype;

	my $note_url = $session->get_repository->get_conf( "perl_url" )."/users/note/$objectid/$objecttype";

	# main_note_div (sneep_n_main) holds all the note paraphanalia save for the show note link 
	# which is rendered by render_link and called separately from within eprint_render.pl (or whatever page the notes are embedded in)
	my $main_note_div = $session->make_element( "div", id=>"sneep_n_main:".$objecttype_lc, class=>"sneep_n_main sneep_n_dialog" );

	# Rounded corners - Thanks to David Kane of www.wit.ie
	my $div_hd = $session->make_element("div", class=>"sneep_n_hd");
	$main_note_div->appendChild($div_hd);
	my $div_c_empty = $session->make_element("div", class=>"sneep_n_c");
	$div_hd->appendChild($div_c_empty);

	my $div_bd = $session->make_element("div", class=>"sneep_n_bd");
	$main_note_div->appendChild($div_bd);
	my $div_c = $session->make_element("div", class=>"sneep_n_c");
	$div_bd->appendChild($div_c);
	######################

	my $user = $session->current_user();

	$div_c->appendChild($session->html_phrase("sneep/note:note_title"));

	# note_div holds that notes them selves (retrived by comment/Serve)
	my $note_div = $session->make_element( "div", id=>"sneep_n_note:".$objecttype_lc );
	$div_c->appendChild($note_div);
	
	# form for adding new notes (editing and deleting is done via a separate form)
	my $note_add_form = $session->make_element( "form", method=>"post", action=>$note_url );
	# note_add_div has the links and buttons for adding a note
	my $note_add_div = $session->make_element( "div", id=>"sneep_n_add:".$objecttype_lc, class=>"sneep_n_add" );
	# note_add_textarea (the form itself spreads between the two note_add_X divs)
	my $note_add_textarea_div = $session->make_element( "div", id=>"sneep_n_add_textarea:".$objecttype_lc, class=>"sneep_n_add_textarea" );
	
	# an hr between the notes and the add form
#	$div_c->appendChild( $session->make_element("hr", id=>"sneep_n_notes_end:".$objecttype_lc ) );

	$div_c->appendChild($note_add_form);
	$note_add_form->appendChild($note_add_div);
	$note_add_form->appendChild($note_add_textarea_div);

	# Inside note_add_div goes a button and two inputs
	my $add_button = $session->make_element("button",
					class=>"sneep_button_as_link",
					onclick=>"sneep_note_toggle_add('sneep_n_add_textarea:".$objecttype_lc."',this,'".
						$session->phrase("sneep/note:add")."','".
						$session->phrase("sneep/note:cancel")."');return false;",
					id=>"sneep_n_add_button:".$objecttype_lc);
	$add_button->appendChild( $session->html_phrase("sneep/note:add" ) );

	#wait for it...
	my $img_src = $session->get_repository->get_conf( "base_url" )."/style/images/ajax-loader.gif";
	my $wait_icon = $session->make_element( "img", id=>"sneep_wait_add:".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );
	my $save_input = $session->make_element("input",
					type=>"submit",
					class=>"sneep_button_as_link",
					id=>"sneep_n_add_save:".$objecttype_lc,
					onclick=>"SneepNoteAdd('".$objecttype."', '".$objectid."', 'sneep_wait_add'); return false;",
					name=>"save_add",
					value=>$session->phrase("sneep/note:save") );
	# This fellow is here to help the non JS souls out there
	my $hidden_input = $session->make_element("input",
					type=>"hidden",
					name=>"add_form",
					value=>"1" );
#	$note_add_div->appendChild($add_button);
	$note_add_div->appendChild($session->html_phrase("sneep/note:add_note"));
#	$note_add_div->appendChild( $session->html_phrase( "sneep/note:tools_divider" ) );
	$note_add_div->appendChild($hidden_input);
	
	my $note_add_title = $session->make_element("input", 
						    name=>"sneep_new_note_title",
						    id=>"sneep_new_note_title:".$objecttype_lc,
						    class=>"sneep_note_add_title" );
	my $note_add_title_label = $session->make_element("span", id=>"sneep_new_note_label:".$objecttype_lc, class=>"sneep_new_note_label");
	$note_add_title_label->appendChild($session->html_phrase("sneep/note:note_title_label"));
	$note_add_textarea_div->appendChild($note_add_title_label);
	$note_add_textarea_div->appendChild($note_add_title);
	$note_add_textarea_div->appendChild($session->make_element("br"));
	
#	<textarea id="content" name="content" cols="85" rows="15">This is some content that will be editable with TinyMCE.</textarea><br>
#	<a href="javascript:toggleEditor('content');">Add/Remove editor</a>
	
	# Inside note_add_textarea_div... a textarea
	my $textarea = $session->make_element("textarea",
				      name=>"sneep_new_note_text",
				      id=>"sneep_new_note_text:".$objecttype_lc,
				      class=>"sneep_note_add_textarea",
				      onkeyup=>"setTextArea(this)",
				      onfocus=>"setTextArea(this)",
				      cols=>$session->phrase("sneep/note:add_textarea_cols"),
				      rows=>$session->phrase("sneep/note:add_textarea_rows"));
	$note_add_textarea_div->appendChild($textarea);
	
#	my $wysiwyg = $session->make_element("a", href=>"javascript:sneep_toggleEditor('sneep_new_note_text:".$objecttype_lc."');");
#	$wysiwyg->appendChild($session->html_phrase("sneep/note:wysiwyg_link"));	

#	$note_add_textarea_div->appendChild($wysiwyg);

	$note_add_textarea_div->appendChild( $session->make_element("br"));
	$note_add_textarea_div->appendChild($save_input);
	$note_add_textarea_div->appendChild( $wait_icon );

	# Rounded corners - Thanks to David Kane
	my $div_ft = $session->make_element("div", class=>"sneep_n_ft");
	$main_note_div->appendChild($div_ft);
	my $div_ftl = $session->make_element("div", class=>"sneep_n_ft-l");
	$div_ft->appendChild($div_ftl);
	######################

	return $main_note_div;
}

#$error_msg is an XHTML DOM element thingy (not a string)
sub error
{
	my( $self, $error_msg, $objectid, $ownerid, $commentid ) = @_;

	my $session = $self->{session};
	
	my $error_div=$session->make_element("div");
	my $error_head=$session->make_element("h1");
	$error_head->appendChild( $session->html_phrase("sneep/error:heading", 
							component_name=>$session->make_text("SNEEP.".$self->{component_name}) ) );

	my $error_text=$session->make_element("p");
	$error_text->appendChild( $error_msg );

	$error_div->appendChild( $error_head );
	$error_div->appendChild( $error_text );

	print EPrints::XML::to_string( $error_div );

	exit;
}

sub make_comment_timestamp
{
	my ($self,$time) = @_;
 
	$time = time unless defined $time;
	
	my( $sec, $min, $hour, $mday, $mon, $year ) = localtime($time);

	return sprintf( "%04d-%02d-%02dT%02d:%02d:%02dZ", 
			$year+1900, $mon+1, $mday, 
			$hour, $min, $sec );

	return $time;
}
sub timestamp_to_text
{
	my ($self,$time) = @_;

	my( $year,$mon,$day,$hour,$min,$sec ) = split /[- :TZ]/, $time;
	
	my @today=EPrints::Time::get_date_array();
	my $str = "$hour:$min";
	if("$year$mon$day" ne join("",@today)){
		$str.= " $day/$mon/$year";
	}else{
		$str.=" today";
	}

}
# Until I work out how to access real class names (EPrint, User etc)... this hack will do
sub get_object_class_name
{
	my ($self,$object) = @_;

	my $cn = ucfirst $object->get_dataset->confid;
	if($cn eq 'Eprint'){
		$cn = 'EPrint';
	}
	
	return $cn;
}

1;
