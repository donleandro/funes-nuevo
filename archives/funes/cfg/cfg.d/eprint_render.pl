
######################################################################

=item $xhtmlfragment = eprint_render( $eprint, $session, $preview )

This subroutine takes an eprint object and renders the XHTML view
of this eprint for public viewing.

Takes two arguments: the L<$eprint|EPrints::DataObj::EPrint> to render and the current L<$session|EPrints::Session>.

Returns three XHTML DOM fragments (see L<EPrints::XML>): C<$page>, C<$title>, (and optionally) C<$links>.

If $preview is true then this is only being shown as a preview.
(This is used to stop the "edit eprint" link appearing when it makes
no sense.)

=cut

use EPrints;

######################################################################

$c->{eprint_render} = sub
{
	my( $eprint, $session, $preview ) = @_;

	my $succeeds_field = $session->get_repository->get_dataset( "eprint" )->get_field( "succeeds" );
	my $commentary_field = $session->get_repository->get_dataset( "eprint" )->get_field( "commentary" );
	my $has_multiple_versions = $eprint->in_thread( $succeeds_field );

	my( $page, $p, $a );


#GAR
        my $garid = undef;
        if($session->current_user()){
                $garid = $session->current_user()->get_id;
        }
#GAR

	$page = $session->make_doc_fragment;
	# Citation
	$p = $session->make_element( "p", class=>"ep_block", style=>"margin-bottom: 1em" );
	$p->appendChild( $eprint->render_citation() );
	$page->appendChild( $p );

	my $eprint_owner_allow=1; #this will be an option from.... elsewhere
	my $comment;
	my $tag;
	if($eprint_owner_allow){
		$comment = $session->plugin( "SneepComment" );
		$tag = $session->plugin( "SneepTag", item=>$eprint );
	}

	# Put in a message describing how this document has other versions
	# in the repository if appropriate
	if( $has_multiple_versions )
	{
		my $latest = $eprint->last_in_thread( $succeeds_field );
		my $block = $session->make_element( "div", class=>"ep_block", style=>"margin-bottom: 1em" );
		$page->appendChild( $block );
		if( $latest->get_value( "eprintid" ) == $eprint->get_value( "eprintid" ) )
		{
			$block->appendChild( $session->html_phrase( 
						"page:latest_version" ) );
		}
		else
		{
			$block->appendChild( $session->render_message(
				"warning",
				$session->html_phrase( 
					"page:not_latest_version",
					link => $session->render_link( 
							$latest->get_url() ) ) ) );
		}
	}		

	# Contact email address
	my $has_contact_email = 0;
	if( $session->get_repository->can_call( "email_for_doc_request" ) )
	{
		if( defined( $session->get_repository->call( "email_for_doc_request", $session, $eprint ) ) )
		{
			$has_contact_email = 1;
		}
	}

	# Available documents
	my @documents = $eprint->get_all_documents();

	my $docs_to_show = scalar @documents;

	$p = $session->make_element( "p", class=>"ep_block", style=>"margin-bottom: 1em" );
	$page->appendChild( $p );

	if( $docs_to_show == 0 )
	{
		$p->appendChild( $session->html_phrase( "page:nofulltext" ) );
		if( $has_contact_email && $eprint->get_value( "eprint_status" ) eq "archive"  )
		{
			# "Request a copy" button
			my $form = $session->render_form( "get", $session->get_repository->get_conf( "perl_url" ) . "/request_doc" );
			$form->appendChild( $session->render_hidden_field( "eprintid", $eprint->get_id ) );
			$form->appendChild( $session->render_action_buttons( 
				"null" => $session->phrase( "request:button" )
			) );
			$p->appendChild( $form );
		}
	}
	else
	{
		$p->appendChild( $session->html_phrase( "page:fulltext" ) );

		my( $doctable, $doctr, $doctd );
		$doctable = $session->make_element( "table", class=>"ep_block", style=>"margin-bottom: 1em" );

		foreach my $doc ( @documents )
		{
			$doctr = $session->make_element( "tr" );
	
			$doctd = $session->make_element( "td", valign=>"top", style=>"text-align:center" );
			$doctr->appendChild( $doctd );
			$doctd->appendChild( $doc->render_icon_link( preview => 1 ) );
	
			$doctd = $session->make_element( "td", valign=>"top" );
			$doctr->appendChild( $doctd );
			$doctd->appendChild( $doc->render_citation_link() );
			my %files = $doc->files;
			if( defined $files{$doc->get_main} )
			{
				my $size = $files{$doc->get_main};
				$doctd->appendChild( $session->make_element( 'br' ) );
				$doctd->appendChild( $session->make_text( EPrints::Utils::human_filesize($size) ));
			}

			if( $has_contact_email && !$doc->is_public && $eprint->get_value( "eprint_status" ) eq "archive" )
			{
				# "Request a copy" button
				$doctd = $session->make_element( "td" );
				my $form = $session->render_form( "get", $session->get_repository->get_conf( "perl_url" ) . "/request_doc" );
				$form->appendChild( $session->render_hidden_field( "docid", $doc->get_id ) );
				$form->appendChild( $session->render_action_buttons( 
					"null" => $session->phrase( "request:button" )
				) );
				$doctd->appendChild( $form );
				$doctr->appendChild( $doctd );
			}

			$doctable->appendChild( $doctr );
		}
		$page->appendChild( $doctable );
	}	

	# Alternative locations
	if( $eprint->is_set( "official_url" ) )
	{
		$p = $session->make_element( "p", class=>"ep_block", style=>"margin-bottom: 1em" );
		$page->appendChild( $p );
		$p->appendChild( $session->html_phrase( "eprint_fieldname_official_url" ) );
		$p->appendChild( $session->make_text( ": " ) );
		$p->appendChild( $eprint->render_value( "official_url" ) );
	}
	
	# Then the abstract
	if( $eprint->is_set( "abstract" ) )
	{
		my $div = $session->make_element( "div", class=>"ep_block" );
		$page->appendChild( $div );
		my $h2 = $session->make_element( "h2" );
		$h2->appendChild( 
			$session->html_phrase( "eprint_fieldname_abstract" ) );
		$div->appendChild( $h2 );

		$p = $session->make_element( "p", style=>"text-align: left; margin: 1em auto 0em auto" );
		$p->appendChild( $eprint->render_value( "abstract" ) );
		$div->appendChild( $p );
	}
	else
	{
		$page->appendChild( $session->make_element( 'br' ) );
	}
	
	my( $table, $tr, $td, $th );	# this table needs more class cjg
	$table = $session->make_element( "table",
					class=>"ep_block", style=>"margin-bottom: 1em",
					border=>"0",
					cellpadding=>"3" );
	$page->appendChild( $table );

	# Commentary
#	if( $eprint->is_set( "commentary" ) )
#	{
#		my $target = EPrints::DataObj::EPrint->new( 
#			$session,
#			$eprint->get_value( "commentary" ),
#			$session->get_repository()->get_dataset( "archive" ) );
#		if( defined $target )
#		{
#			$table->appendChild( $session->render_row(
#				$session->html_phrase( 
#					"eprint_fieldname_commentary" ),
#				$target->render_citation_link() ) );
#		}
#	}

	my $frag = $session->make_doc_fragment;
	$frag->appendChild( $eprint->render_value( "type"  ) );
	my $type = $eprint->get_value( "type" );
	if( $type eq "conference_item" )
	{
		$frag->appendChild( $session->make_text( " (" ));
		$frag->appendChild( $eprint->render_value( "pres_type"  ) );
		$frag->appendChild( $session->make_text( ")" ));
	}
	if( $type eq "monograph" )
	{
		$frag->appendChild( $session->make_text( " (" ));
		$frag->appendChild( $eprint->render_value( "monograph_type"  ) );
		$frag->appendChild( $session->make_text( ")" ));
	}
	if( $type eq "thesis" )
	{
		$frag->appendChild( $session->make_text( " (" ));
		$frag->appendChild( $eprint->render_value( "thesis_type"  ) );
		$frag->appendChild( $session->make_text( ")" ));
	}
	$table->appendChild( $session->render_row(
		$session->html_phrase( "eprint_fieldname_type" ),
		$frag ));

	# Additional Info
	if( $eprint->is_set( "note" ) )
	{
		$table->appendChild( $session->render_row(
			$session->html_phrase( "eprint_fieldname_note" ),
			$eprint->render_value( "note" ) ) );
	}


	# Keywords
	if( $eprint->is_set( "keywords" ) )
	{
		$table->appendChild( $session->render_row(
			$session->html_phrase( "eprint_fieldname_keywords" ),
			$eprint->render_value( "keywords" ) ) );
	}



	# Subjects...
	if( $eprint->is_set( "subjects" ) )
	{
		$table->appendChild( $session->render_row(
			$session->html_phrase( "eprint_fieldname_subjects" ),
			$eprint->render_value( "subjects" ) ) );
	}

	# Divisions...
	if( $eprint->is_set( "divisions" ) )
	{
		$table->appendChild( $session->render_row(
			$session->html_phrase( "eprint_fieldname_divisions" ),
			$eprint->render_value( "divisions" ) ) );
	}

	$table->appendChild( $session->render_row(
		$session->html_phrase( "page:id_code" ),
		$eprint->render_value( "eprintid" ) ) );

	my $user = new EPrints::DataObj::User( 
			$eprint->{session},
 			$eprint->get_value( "userid" ) );
	my $usersname;
	if( defined $user )
	{
		$usersname = $user->render_description();
	}
	else
	{
		$usersname = $session->html_phrase( "page:invalid_user" );
	}

	$table->appendChild( $session->render_row(
		$session->html_phrase( "page:deposited_by" ),
		$usersname ) );

	if( $eprint->is_set( "sword_depositor" ) )
	{
		my $depositor = new EPrints::DataObj::User(
					$eprint->{session},
					$eprint->get_value( "sword_depositor" ) );
		my $depo_user;
		if( defined $depositor )
		{
			$depo_user = $depositor->render_description();
		}
		else
		{
			$depo_user = $session->html_phrase( "page:invalid_user" );
		}

		$table->appendChild( $session->render_row(
			$session->html_phrase( "page:sword_deposited_by" ),
			$depo_user) );
	}


	if( $eprint->is_set( "datestamp" ) )
	{
		$table->appendChild( $session->render_row(
			$session->html_phrase( "page:deposited_on" ),
			$eprint->render_value( "datestamp" ) ) );
	}

	if( $eprint->is_set( "lastmod" ) )
	{
		$table->appendChild( $session->render_row(
			$session->html_phrase( "eprint_fieldname_lastmod" ),
			$eprint->render_value( "lastmod" ) ) );
	}

        #CIFE Valoration resume
#        my $url ="/rating/valoracion.php?";
#        if( defined $user ) {
#          $url .= "user_id=".$eprint->get_value( "userid" );
#        }
#        else {
#          $url .= "user_id=-1";
#        }
#        $url .= "&";
#        $url .= "doc_id=".$eprint->get_value( "eprintid" );
#        $url .= "&";
#        $url .= "vote_enabled=0";
#         my $iframe = $session->make_element( "iframe",
#                         src=>$url,
#                         width=>"350px",
#                         height=>"28px",
#			 frameborder=>"0",
#			 scrolling=>"no",
#                         style=>"border:0;position:relative;top:-8px;left:-8px;"
#                         );
#        $table->appendChild( $session->render_row(
#                        $session->html_phrase( "cife/valoration" ),
#                        $iframe ) );
	#END CIFE

	# Now show the version and commentary response threads
	if( $has_multiple_versions )
	{
		my $div = $session->make_element( "div", class=>"ep_block", style=>"margin-bottom: 1em" );
		$page->appendChild( $div );
		$div->appendChild( 
			$session->html_phrase( "page:available_versions" ) );
		$div->appendChild( 
			$eprint->render_version_thread( $succeeds_field ) );
	}
	
	if( $eprint->in_thread( $commentary_field ) )
	{
		my $div = $session->make_element( "div", class=>"ep_block", style=>"margin-bottom: 1em" );
		$page->appendChild( $div );
		$div->appendChild( 
			$session->html_phrase( "page:commentary_threads" ) );
		$div->appendChild( 
			$eprint->render_version_thread( $commentary_field ) );
	}
if (0){
	#cife 
	my $url ="/rating/valoracion.php?";
	if( defined $user ) {
	  $url .= "user_id=".$eprint->get_value( "userid" );
	}
	else {
	  $url .= "user_id=-1";	
	}
	$url .= "&";
	$url .= "doc_id=".$eprint->get_value( "eprintid" );
	$url .= "&";
	$url .= "vote_enabled=0";
         my $iframe = $session->make_element( "iframe",
                         src=>$url,
                         width=>"250px",
                         height=>"80px",
                         style=>"border: 1;"
                         );
	$page->appendChild($iframe);
	my $div = $session->make_element( "div", class=>"ep_block", style=>"margin-bottom: 1em" );
	$page->appendChild( $div );
	$div->appendChild( 
	$session->html_phrase( "page:commentary_threads" ) );
	$div->appendChild($iframe); 
}
if(0){
	# Experimental OVID Link
	my $url ="http://linksolver.ovid.com/OpenUrl/LinkSolver?";
	$url .= "atitle=".$eprint->get_value( "title" );
	$url .= "&";
	my $authors = $eprint->get_value( "creators" );
	my $first_author = $authors->[0];
	$url .= "aulast=".$first_author->{name}->{family};
	$url .= "&";
	$url .= "date=".substr($eprint->get_value( "date" ),0,4);
	if( $eprint->is_set( "issn" ) )
	{
		$url .= "&issn=".$eprint->get_value( "issn" );
	}
	if( $eprint->is_set( "volume" ) )
	{
		$url .= "&volume=".$eprint->get_value( "volume" );
	}
	if( $eprint->is_set( "number" ) )
	{
		$url .= "&issue=".$eprint->get_value( "number" );
	}
	if( $eprint->is_set( "pagerange" ) )
	{
		my $pr = $eprint->get_value( "pagerange" );
		$pr =~ m/^([^-]+)-/;
		$url .= "&spage=$1";
	}

	my $ovid_block = $session->make_element( "p" );
	$page->appendChild( $ovid_block );
	my $ovid_link = $session->render_link( $url );
	$ovid_block->appendChild( $ovid_link );
	$ovid_link->appendChild( $session->make_text( "OVID" ) );
}


	unless( $preview )
	{
	  	# Add a link to the edit-page for this record. Handy for staff.
                my $edit_para = $session->make_element( "p", align=>"right" );
                $edit_para->appendChild( $session->html_phrase( 
                        "page:edit_link",
                        link => $session->render_link( $eprint->get_control_url ) ) );
                $page->appendChild( $edit_para );

		# A toolbar for links to sneep components
		my $tool_div = $session->make_element( "div", class=>"sneep_toolbar", id=>"sneep_toolbar:eprint" );

		# Here is the comment link
		#my $eprintid = $eprint->get_value( "eprintid" );
		# It goes into the sneep_toolbar div
		#$tool_div->appendChild( $comment->render_comment_link( "EPrint", $eprintid ) );

		# and here is the note link
		#$tool_div->appendChild( $session->make_text( " | " ) );
		#$tool_div->appendChild( $comment->render_note_link( "EPrint", $eprintid ) );
		# a tag link
		#$tool_div->appendChild( $session->make_text( " | " ) );
		#$tool_div->appendChild( $tag->render_tag_link( "EPrint", $eprintid ) );


#CIFE - My valoration

#        my $url ="/cgi/rating/";
#        $url .= $eprint->get_value( "eprintid" );
#         my $iframe = $session->make_element( "iframe",
#                         src=>$url,
#                         width=>"350px",
#                         height=>"28px",
#			 frameborder=>"0",
# 			 scrolling=>"no",
#                         style=>"border:0;position:relative;top:0px;left:0px;"
#                         );

	#$tool_div->appendChild( $session->make_text( "   |  " ) );
#	$tool_div->appendChild($iframe);

#end CIFE


		# sneep_toolbar div onto the page
		$page->appendChild( $tool_div );

		# Now we need to render some html to house the comments 
		# (this will be hidden if properly initialised... see cfg.d/dynamic_remplate.pl, templates/default.xml and 80_sneep_comments.js)
		$page->appendChild( $session->make_element( "br" ) );
		# A general sneep div
		my $sneep_div = $session->make_element( "div", id=>"sneep_main" );
		# into which the components can go (if you want)
		#$page->appendChild( $sneep_div );
		#$sneep_div->appendChild( $comment->render_comments_box( "EPrint", $eprintid ) );
		#$sneep_div->appendChild( $comment->render_notes_box( "EPrint", $eprintid ) );
		#$sneep_div->appendChild( $tag->render_tag_box( "EPrint", $eprintid ) );

	}

	my $title = $eprint->render_description();

	my $links = $session->make_doc_fragment();
	$links->appendChild( $session->plugin( "Export::Simple" )->dataobj_to_html_header( $eprint ) );
	$links->appendChild( $session->plugin( "Export::DC" )->dataobj_to_html_header( $eprint ) );

	return( $page, $title, $links );
};


