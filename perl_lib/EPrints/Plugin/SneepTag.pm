######################################################################
#
# EPrints::Plugin::SneepTag;
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

package EPrints::Plugin::SneepTag;

use strict;
use Switch;
use POSIX qw(strftime);

our @ISA = qw/ EPrints::Plugin /;

sub get_system_field_info
{
	my( $class ) = @_;

	return 
	( 
		{ name=>"tagid", type=>"int", required=>1 },

		{ name=>"eprintid", type=>"int", required=>1 },

		{ name=>"documentid", type=>"int", required=>1 },
		
		{ name=>"userid", type=>"int", required=>1 },

		{ name=>"created", type=>"date", required=>1 },

		{ name=>"lastmod", type=>"date", required=>1 },

		{ name=>"text", type=>"longtext" },

	);
}

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{tag_table} = "sneep_tags";
	$self->{stat_table} = "sneep_tag_stat";
	$self->{tag2item_table} = "sneep_tag2item";
	$self->{itemtype_table} = "sneep_tag_itemtypes";
	$self->{error} = undef;
	$self->{error_msg} = undef;
	$self->{component_name} = "tag";

	return $self;
}

sub insert_tag
{
	my( $self, $tag_type, $id, $ownerid, $text ) = @_;

	my $session = $self->{session};
	
	my $created = strftime "%Y-%m-%d %H:%M:%S", localtime;
	$self->{tag2_table} = "sneep_tag2".$tag_type;
	my $orig_text = $text;
	my @tags;
	if($text =~ /,/){ # a comma! this must be a list of tags
		@tags = split(/,/,$text);
	}else{
		$tags[0] = $text;
	}
	my $i=0;
	for my $tag(@tags){ 
		$tag =~ s/^\s+//;
		$tag =~ s/\s+$//;
		my $dbh = $session->get_database->{dbh};
		my $orig_tag = $tag;
		$tag = $session->get_database->{dbh}->quote($tag);
		$created = $session->get_database->{dbh}->quote($created);
		my $lastmod = $created;
		if($tag_type eq "eprint"){
			$tag_type =~ s/^(\w\w)(.*)/\U$1\L$2/g;
		}else{
			$tag_type = ucfirst($tag_type);
		}
		my $object = eval("EPrints::DataObj::$tag_type->new( \$session, \$id, \$session->get_repository->get_dataset( \"archive\" ) );");
		
		# Is there already a tag for this item? 1: yes -1: yes but not for this item 0: no
		my $tag_exists = $self->tag_exists($tag, $tag_type, $id);
		if($tag_exists>0){ 
			$self->{error} = 1;
			my $err_str = "This item (".$object->get_value("title").") has already been tagged with the tag \"$orig_tag\"";
			push (@{$self->{error_msgs}}, $err_str);
			next; 
		}
		
		 #gets the itemtype (int) that corresponds to the tag_type (which woulc probably be better named item_type!!)
#		my $itemtype = $self->get_itemtype($tag_type) or die("unknown item type $tag_type!");
		$dbh->{'AutoCommit'} = 0;
		#trap errors using eval}
		eval {
			my $tagid;
			if($tag_exists==0){
			    	# insert tag text
				$dbh->do("INSERT INTO ".$self->{tag_table}." (tag_text) VALUES (".$tag.")");
				$tagid = $dbh->{ q{mysql_insertid} };
				$self->{tagid} = $tagid;
			}else{
				$dbh->do("UPDATE ".$self->{tag_table}." SET ownerid = $ownerid WHERE tag_text = $tag");
				$tagid = $self->{tagid};
			}
		    	
			# insert tag2[tag_type] mapping
			$dbh->do("INSERT INTO ".$self->{tag2_table}." (tagid, ".$tag_type."id, ownerid) values ($tagid, $id, $ownerid)");
	
			# insert tag2item mapping
#			$dbh->do("INSERT INTO ".$self->{tag2item_table}." (tagid, itemid, itemtype, ownerid) values ($tagid, $id, $itemtype, $ownerid)");
	
			$self->update_count($tagid, $tag_type);
			# no errors so far
			# commit changes
			$dbh->commit();
		};

		# any errors
		# rollback
		if ($@) {
		    print "Transaction aborted: $@";
		    $dbh->rollback();
		    $self->{error} = 1; 
	 	    my $err_str = "There was a problem updating the database."; 
		    push (@{$self->{error_msgs}}, $err_str);
		    next;
		}else{
			print "<sneep_tag_message id=\"sneep_tag_message_".$i."\" sneep_tag_text=\"$orig_tag\">\"".EPrints::XML::to_string($object->render_description)."\" has been tagged with \"$orig_tag\"</sneep_tag_message>\n";
		}
		$i++;
	}
}

sub delete_tag
{
	my($self, $tag_type, $id, $ownerid, $tag_text) = @_;

	my $session = $self->{session};
	my $dbh = $session->get_database->{dbh};

	$self->{tag2_table} = "sneep_tag2".$tag_type;

	$tag_text = $session->get_database->{dbh}->quote($tag_text);
	my $lc_tag_type = lc $tag_type;
  	my $sql = "select t.tagid, ".$lc_tag_type."id as itemid, ownerid, tag_text from ".$self->{tag2_table}." t2 inner join ".$self->{tag_table}." t on t.tagid = t2.tagid where ownerid = $ownerid and tag_text = $tag_text";
	if($id =~/\d+/){
		$sql.=" and ".$lc_tag_type."id = ".$id;
	}
#	print $sql."<br/>";
	my $sth=$session->get_database->prepare( $sql );
	my $rv=0;
	$session->get_database->execute( $sth, $sql );
	$rv = $sth->rows;
	if(!$rv){
	}else{
		my $i=0;
		while(my $result = $sth->fetchrow_hashref){
			my $tagid = $result->{tagid};
			my $itemid = $result->{itemid};

			$dbh->{'AutoCommit'} = 0;
			eval{
				# delete tag2tag_type mapping
				$dbh->do("DELETE FROM ".$self->{tag2_table}." WHERE tagid = $tagid and ".$lc_tag_type."id =$itemid");
		
				# delete tag2item mapping
#				$dbh->do("DELETE FROM ".$self->{tag2item_table}." WHERE tagid = $tagid and ".$lc_tag_type."id =$itemid");
	
		#		$dbh->do("UPDATE ".$self->{tag_table}." SET ownerid = NULL WHERE tagid = $tagid");
	
				$self->update_count($tagid, $tag_type, "REDUCE");
		
				# no errors so far
				# commit changes
				$dbh->commit();
			};
			# any errors
			# rollback
			if ($@) {
			    print "Transaction aborted: $@";
			    $dbh->rollback();
			    $self->{error} = 1; 
		 	    my $err_str = "There was a problem updating the database."; 
			    push (@{$self->{error_msgs}}, $err_str);
			}else{
				if($tag_type eq "eprint"){
					$tag_type =~ s/^(\w\w)(.*)/\U$1\L$2/g;
				}else{
					$tag_type = ucfirst($tag_type);
				}
				my $object = eval("EPrints::DataObj::$tag_type->new( \$session, \$itemid, \$session->get_repository->get_dataset( \"archive\" ) );");
				print "<sneep_tag_message id=\"sneep_tag_message_$i\" sneep_tag_text=\"$tag_text\">\"". EPrints::XML::to_string($object->render_description)."\" is no longer tagged with \"".$tag_text."\"</sneep_tag_message>\n";
			}
			$i++;
		}
	}
}

# Checks the text against existing tags, 
# If there is already a tag with the same text for exactly the same item reurns 1
# If there is already a tag but it is associated with a different item returns -1 and sets the $self->{tagid}
# If the tag is brand new returns 0

sub tag_exists
{
	my( $self, $text, $tag_type, $id) = @_;

	my $session = $self->{session};

	my $sql="SELECT * FROM ".$self->{tag_table}." t JOIN ".$self->{tag2_table}." t2e ON t.tagid = t2e.tagid where tag_text = $text and t2e.".$tag_type."id = $id" ;

	my $sth=$session->get_database->prepare( $sql );
	my $rv=0;
	$session->get_database->execute( $sth, $sql );
	$rv = $sth->rows;
	if($rv){
		return 1;
	}
	
	# Maybe the tag exists but it is not associated to this item
	$sql="SELECT * FROM ".$self->{tag_table}." where tag_text = $text";
	$sth=$session->get_database->prepare( $sql );
	$rv=0;
	$session->get_database->execute( $sth, $sql );
	$rv = $sth->rows;
	if($rv){
		my $result  = $sth->fetchrow_hashref;
		$self->{tagid} = $result->{tagid};
		return -1;
	}

	return 0;
	
}
# Update counter values in sneep_tag_stat
sub update_count
{
	my ($self, $tagid, $tag_type, $reduce) = @_;

	my $session = $self->{session};
	my $dbh = $session->get_database->{dbh};

	# does count already exist for this tag?
	my $sql="SELECT num_".$tag_type."s as num_tags, num_items FROM sneep_tag_stat where tagid = $tagid";
	my $sth=$session->get_database->prepare( $sql );
	my $rv=0;
	$session->get_database->execute( $sth, $sql );
	$rv = $sth->rows;
	if(!$rv){
		$dbh->do("INSERT INTO ".$self->{stat_table}." (tagid, num_".$tag_type."s, num_items) VALUES ($tagid, 1, 1)");
	}else{
		my $result  = $sth->fetchrow_hashref;
		my $num_tags;
		my $num_items;
		if($reduce eq "REDUCE"){
			$num_tags = $result->{num_tags} - 1;
			$num_items =  $result->{num_items} - 1;
		}else{
			$num_tags = $result->{num_tags} + 1;
			$num_items =  $result->{num_items} + 1;
		}
		$dbh->do("UPDATE ".$self->{stat_table}." SET num_".$tag_type."s = ".$num_tags.", num_items = ".$num_items." WHERE tagid=$tagid");
	}
}

sub get_itemtype
{
	my ($self, $tag_type) = @_;
	
	my $session = $self->{session};

	my $dbh = $session->get_database->{dbh};
	$tag_type = $session->get_database->{dbh}->quote($tag_type);

	my $sql="SELECT * FROM ".$self->{itemtype_table}." where itemtype_name = $tag_type";
#	print $sql."<br/>\n";
	my $sth=$session->get_database->prepare( $sql );
	my $rv=0;
	$session->get_database->execute( $sth, $sql );
	$rv = $sth->rows;
	if($rv){
		my $result  = $sth->fetchrow_hashref;
		return $result->{itemtype};
	}
	return 0;

}

sub get_tag_density
{
	my ($self, $tag_types, $filter, $eprint) = @_;

	my $session = $self->{session};
	# Right now I'm not sure how to implement cross item density querying...
	# So implementing either one or all, but leaving the ability to request 
	# tags across multiple items
	my $tag_type = @{$tag_types}[0];
	my $lc_tag_type = lc $tag_type;
	if($tag_type eq "All") { $lc_tag_type = "item"; }
	my $sql;
	my $itemid = undef;
	if(defined $eprint){
		$itemid = $eprint->get_id;
	}
	my $ownerid = undef;
	if($session->current_user()){
		$ownerid = $session->current_user()->get_id;			
	}

	if($filter eq "myItemTags"){
		$sql = "SELECT tag_text, ownerid, ts.num_".$lc_tag_type."s as density, t2.".$lc_tag_type."id as itemid FROM sneep_tag2".$lc_tag_type." t2 INNER JOIN sneep_tags t ON t2.tagid = t.tagid INNER JOIN sneep_tag_stat ts on t.tagid = ts.tagid where t2.".$lc_tag_type."id = $itemid and ownerid = $ownerid GROUP BY tag_text";
	}elsif($filter eq "myTags"){
		$sql = "SELECT tag_text, ownerid, ts.num_".$lc_tag_type."s as density, t2.".$lc_tag_type."id as itemid FROM sneep_tag2".$lc_tag_type." t2 INNER JOIN sneep_tags t ON t2.tagid = t.tagid INNER JOIN sneep_tag_stat ts on t.tagid = ts.tagid where ownerid = $ownerid GROUP BY tag_text";
	}elsif($filter eq "itemTags"){
		$sql = "SELECT tag_text, ownerid, ts.num_".$lc_tag_type."s as density, t2.".$lc_tag_type."id as itemid FROM sneep_tag2".$lc_tag_type." t2 INNER JOIN sneep_tags t ON t2.tagid = t.tagid INNER JOIN sneep_tag_stat ts on t.tagid = ts.tagid where t2.".$lc_tag_type."id = $itemid GROUP BY tag_text";	
	}else{
		$sql = "SELECT tag_text, ownerid, ts.num_".$lc_tag_type."s as density, t2.".$lc_tag_type."id as itemid FROM sneep_tag2".$lc_tag_type." t2 INNER JOIN sneep_tags t ON t2.tagid = t.tagid INNER JOIN sneep_tag_stat ts on t.tagid = ts.tagid GROUP BY tag_text";
	}
	my $sth=$session->get_database->prepare( $sql );
	my $rv=0;
	$session->get_database->execute( $sth, $sql );
	$rv = $sth->rows;
	
	my %density;
	if($rv){
		while(my $result  = $sth->fetchrow_hashref ){
			$density{$result->{tag_text}} = {"density" => $result->{density}, "itemtype" => $tag_type, "ownerid"=> $result->{ownerid}, "itemid" => $result->{itemid} };
		}

		return \%density;
	}else{
		return 0;
	}

}

sub get_tag_index
{
	my ($self, $tag_text, $tag_types) = @_;

	my $session = $self->{session};
	my $dbh = $session->get_database->{dbh};
	$tag_text = $session->get_database->{dbh}->quote($tag_text);

	my $tag_type = @{$tag_types}[0];
	my $lc_tag_type = lc $tag_type;
	if($tag_type eq "All") { $lc_tag_type = "item"; }

	my $sql = "SELECT t.tagid, ".$lc_tag_type."id ";
	if($lc_tag_type eq "item"){
		$sql.= ", itemtype_name as object ";
	}
	$sql .= "FROM sneep_tags t INNER JOIN sneep_tag2".$lc_tag_type." t2 ON t.tagid = t2.tagid ";
	if($lc_tag_type eq "item"){
		$sql.=	"INNER JOIN sneep_tag_itemtypes ti ON ti.itemtype = t2.itemtype ";
	}
	$sql.=	"WHERE t.tag_text = $tag_text";
	
	my $sth=$session->get_database->prepare( $sql );
	my $rv=0;
	$session->get_database->execute( $sth, $sql );
	$rv = $sth->rows;
	
	my @tag_index;
	if($rv){
		while(my $result  = $sth->fetchrow_hashref ){
			my $id = $result->{$lc_tag_type."id"};
			if($lc_tag_type eq "item"){
				$tag_type = $result->{object};
			}
			push @tag_index, {"id" => $id, "itemtype" => $tag_type};

		}

		return \@tag_index;
	}else{
		return 0;
	}
}


sub render_tag_cloud
{
	my ($self, $densities) = @_;
	
	my $session = $self->{session};
	my $base_pt = 10;
	my $tag_cloud;
	if($densities){
		$tag_cloud = $session->make_element("p", class=>"sneep_tag_cloud");
		foreach my $tag_text (sort keys %$densities) {
			my $hits = $densities->{$tag_text}->{density};
			my $itemtype = $densities->{$tag_text}->{itemtype};
			my $itemtype_o = $itemtype;
			if($itemtype_o eq "eprint"){
				$itemtype_o =~ s/^(\w\w)(.*)/\U$1\L$2/g;
			}else{
				$itemtype_o = ucfirst($itemtype);
			}
	
			my $pt_size = $base_pt + $hits*5;
			my $tag_url = $session->get_repository->get_conf( "perl_url" )."/tag/".$itemtype_o."/".$tag_text;
	
			my $span = $session->make_element("span", class=>"sneep_tag_cloud_span", id=>"sneep_tag_tag:".$tag_text ,style=>"font-size: ".$pt_size."pt;");
			my $a = $session->make_element("a", 
						href=>$tag_url, 
						title=>$session->phrase("sneep/tag:link_title", itemtype=>$itemtype_o, tag_text=>$tag_text),
						onclick=>"sneep_tag('$tag_text','".$itemtype_o."',false,'sneep_wait_cloud',false,false,this); return false;");
			$a->appendChild($session->make_text($tag_text));
			$span->appendChild($a);
			$tag_cloud->appendChild($span);
			$tag_cloud->appendChild($session->make_text(" "));
		}
	}else{
		$tag_cloud=$session->make_doc_fragment();
		$tag_cloud->appendChild($session->html_phrase("sneep/tag:no_tags"));
	}
	$self->{tags_html} = $tag_cloud;
}

sub render_tag_list
{
	my ($self, $densities, $filter) = @_;
	
	my $session = $self->{session};

	my $base_pt = 10;
	my $tag_list;
	if($densities){
		$tag_list = $session->make_element("ul", class=>"sneep_tag_list");
		my $user = undef;
		if($session->current_user()){
			$user = $session->current_user();			
		}

		foreach my $tag_text (sort keys %$densities) {
			my $hits = $densities->{$tag_text}->{density};
			my $itemtype = $densities->{$tag_text}->{itemtype};
			my $ownerid = $densities->{$tag_text}->{ownerid};
			my $itemid = "global";
			if($self->{item}){
				$itemid = $self->{item}->get_id;
			}
			#my $itemid = $densities->{$tag_text}->{itemid};
	
			my $pt_size = $base_pt + $hits*5;
			my $tag_url = $session->get_repository->get_conf( "perl_url" )."/tag/".$itemtype."/".$tag_text;
	
			my $li = $session->make_element("li", class=>"sneep_tag_list_li");
	#, style=>"font-size: ".$pt_size."pt;");
			my $a = $session->make_element("a", 
							href=>$tag_url, 
							title=>$session->phrase("sneep/tag:link_title", itemtype=>$itemtype, tag_text=>$tag_text),
							onclick=>"sneep_tag('$tag_text','".$itemtype."',false,'sneep_wait_cloud',false,false,this); return false;");

			$a->appendChild($session->make_text($tag_text));
			$li->appendChild($a);
			$li->appendChild($session->make_text(" "));
			if(defined $user && $user->get_id == $ownerid && $filter =~ /my/){
				my $del_tag_url = $session->get_repository->get_conf( "perl_url" )."/users/tag/".$itemtype."/".$tag_text."/delete";
				my $del = $session->make_element("a", 
								href=>$del_tag_url, 
								title=>$session->phrase("sneep/tag:delete_title", tag_text=>$tag_text),
								class=>"sneep_tag_delete_link",
								onclick=>"sneepTagDelete('".$itemtype."','".$itemid."', '".$tag_text."', ''); return false;");
				$del->appendChild($session->html_phrase("sneep/tag:delete_icon"));
				$li->appendChild($del);
			}
			$tag_list->appendChild($li);
		}
	}else{
		$tag_list=$session->make_doc_fragment();
		$tag_list->appendChild($session->html_phrase("sneep/tag:no_tags"));
	}
	$self->{tags_html} = $tag_list;
}

sub render_tag_index
{
	my ($self, $tag_index) = @_;
	my $session = $self->{session};
	my $tag_index_div = $session->make_element("div", class=>"sneep_tag_index");
	my $objecttype = @$tag_index[0]->{itemtype}; # NB: this assumes aonly eprints are being tagged... boo!
	my $back_url = $session->get_repository->get_conf( "perl_url" )."/tag/".$objecttype."/~cloud";
	my $back_link_span = $session ->make_element("span", class=>"sneep_t_tools");
	my $back_from_index = $session->make_element("a", 
					href=>$back_url,
					class=>"sneep_tool_link",
					onclick=>"sneep_tag(false,'$objecttype',false,'sneep_wait_cloud',false,false,this); return false;");
	
	$back_from_index->appendChild($session->html_phrase("sneep/tag:back_from_index"));
	$back_link_span->appendChild($back_from_index);
	$tag_index_div->appendChild($back_link_span);

	my $ul = $session->make_element("ul", class=>"sneep_tag_index_list");
	$tag_index_div->appendChild( $ul );
	foreach my $t_ind(@$tag_index){
		
		my $id = $t_ind->{id};
		my $itemtype = $t_ind->{itemtype};
		my $item;
		eval("\$item = EPrints::DataObj::$itemtype->new( \$session, \$id );");
		my $li = $session->make_element("li", class=>"sneep_tag_index_list_item");
#		my %params;
#		$params{url} = $item->get_url;

		$li->appendChild( $item->render_citation_link() );


		$ul->appendChild( $li );
	}
	$self->{tags_html} = $tag_index_div;
}

sub render_tag_box
{
	my ( $self, $objecttype, $objectid) = @_;
	
	my $session = $self->{session};
	my $objecttype_lc = lc $objecttype;

	my $tag_url = $session->get_repository->get_conf( "perl_url" )."/users/tag/$objectid/$objecttype";

	# main_tag_div (sneep_t_main) holds all the tag paraphanalia save for the show tag link 
	# which is rendered by render_link and called separately from within eprint_render.pl (or whatever page the tags are embedded in)
	my $main_tag_div = $session->make_element( "div", id=>"sneep_t_main:".$objecttype_lc, class=>"sneep_t_dialog" );

	# Rounded corners - Thanks to David Kane of www.wit.ie
	my $div_hd = $session->make_element("div", class=>"sneep_t_hd");
	$main_tag_div->appendChild($div_hd);
	my $div_c_empty = $session->make_element("div", class=>"sneep_t_c");
	$div_hd->appendChild($div_c_empty);

	my $div_bd = $session->make_element("div", class=>"sneep_t_bd");
	$main_tag_div->appendChild($div_bd);
	my $div_c = $session->make_element("div", class=>"sneep_t_c");
	$div_bd->appendChild($div_c);
	######################

	# tag_div holds that tags them selves (retrived by comment/Serve)
#	my $tag_div = $session->make_element( "div", id=>"sneep_t_tag:".$objecttype_lc );
#	$div_c->appendChild($tag_div);
	
	# form for adding new tags (editing and deleting is done via a separate form)
	my $tag_add_form = $session->make_element( "form", method=>"post", action=>$tag_url );
	# tag_top_div has the title and view controls in it
	my $tag_top_div = $session->make_element( "div", id=>"sneep_t_top:".$objecttype_lc );
	$div_c->appendChild($tag_top_div);
	$tag_top_div->appendChild($session->html_phrase("sneep/tag:tag_title"));

	my $tag_tools_span = $session ->make_element("span", id=>"sneep_t_tools:".$objecttype_lc, class=>"sneep_t_tools");

	my $tag_view_list_label_js = $session->phrase("sneep/tag:view_toggle_list");
	my $tag_view_cloud_label_js = $session->phrase("sneep/tag:view_toggle_cloud");
	my $tag_view_toggle_link = $session->make_element("a", href=>"", onclick=>"sneep_tag_view_toggle(this,'~list','~cloud','$tag_view_list_label_js','$tag_view_cloud_label_js', '".$objecttype."', $objectid); return false;", class=>"sneep_tool_link");
	$tag_view_toggle_link->appendChild($session->html_phrase("sneep/tag:view_toggle_list"));
	$tag_tools_span->appendChild($tag_view_toggle_link);

	my $tag_view_my_label_js = $session->phrase("sneep/tag:view_my_item_tags");
	my $tag_view_item_label_js = $session->phrase("sneep/tag:view_item_tags");
	my $tag_view_mine_link = $session->make_element("a", href=>"", onclick=>"sneep_tag_filter_toggle(this,'myItemTags','itemTags','$tag_view_my_label_js','$tag_view_item_label_js', '".$objecttype."', $objectid); return false;", class=>"sneep_tool_link");
	$tag_view_mine_link->appendChild($session->html_phrase("sneep/tag:view_my_item_tags"));
	$tag_tools_span->appendChild( $session->make_text(" | ") );
	$tag_tools_span->appendChild($tag_view_mine_link);

	$tag_top_div->appendChild($tag_tools_span);

	my $tag_msg = $session->make_element("ul", 
						id=>"sneep_tag_msg:".$objecttype_lc,
						class=>"sneep_tag_message",
						style=>"display: none;");

	$tag_top_div->appendChild( $tag_msg );

	# tag_add_textarea (the form itself spreads between the two tag_add_X divs)
	my $tag_add_textarea_div = $session->make_element( "div", id=>"sneep_t_add_textarea:".$objecttype_lc, class=>"sneep_t_add_div" );
		

	#this bit has the title
	
	#The tags (defaults to cloud)
	my $view_box = $self->render_tag_view_box($objecttype,$objectid);
	$div_c->appendChild($view_box);

	$div_c->appendChild($tag_add_form);
	$tag_add_form->appendChild($tag_add_textarea_div);

	#wait for it...
	my $img_src = $session->get_repository->get_conf( "base_url" )."/style/images/ajax-loader.gif";
	my $wait_icon = $session->make_element( "img", id=>"sneep_wait_add:".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );
	my $save_input = $session->make_element("input",
					type=>"submit",
					class=>"sneep_button_as_link",
					id=>"sneep_n_add_save:".$objecttype_lc,
					onclick=>"SneepTagAdd('".$objecttype."', '".$objectid."', 'sneep_wait_add'); return false;",
						#  sneep_tag_init_tag(); return false;",
					name=>"save_add",
					value=>$session->phrase("sneep/tag:save") );
	# This fellow is here to help the non JS souls out there
	my $hidden_input = $session->make_element("input",
					type=>"hidden",
					name=>"add_form",
					value=>"1" );
	
	$tag_add_textarea_div->appendChild($hidden_input);
	
	my $tag_add_title = $session->make_element("input", 
						    name=>"sneep_new_tag_title",
						    id=>"sneep_new_tag_title:".$objecttype_lc,
						    class=>"sneep_tag_add_title" );

	$tag_add_textarea_div->appendChild($session->html_phrase("sneep/tag:input_label"));
	$tag_add_textarea_div->appendChild($tag_add_title);
	$tag_add_textarea_div->appendChild($save_input);
	$tag_add_textarea_div->appendChild( $wait_icon );

	# Rounded corners - Thanks to David Kane
	my $div_ft = $session->make_element("div", class=>"sneep_t_ft");
	$main_tag_div->appendChild($div_ft);
	my $div_ftl = $session->make_element("div", class=>"sneep_t_ft-l");
	$div_ft->appendChild($div_ftl);
	######################

	return $main_tag_div;
}

sub render_tag_view_box
{
	my ( $self, $objecttype, $objectid, $show) = @_;
	
	my $session = $self->{session};
	my $objecttype_lc = lc $objecttype;

	my $main_tag_div = $session->make_element( "div", id=>"sneep_t_main_view:".$objecttype_lc );

	#A div to put tag views in
	my $tag_view_div;
	if($show){
		$tag_view_div = $session->make_element( "div", id=>"sneep_tag_view:".$objecttype_lc, class=>"sneep_tag_view");
	}else{
		$tag_view_div = $session->make_element( "div", id=>"sneep_tag_view:".$objecttype_lc, style=>"display: none;", class=>"sneep_tag_view");
	}
	$main_tag_div->appendChild($tag_view_div);

	return $tag_view_div;
#	return $main_tag_div;

}
sub render_tag_link
{
	my ( $self, $objecttype, $objectid) = @_;

	my $session = $self->{session};
 	my $objecttype_lc = lc $objecttype;

	my $tag_header = $session->make_element( "span", id=>"sneep_tag_link_span:".$objecttype_lc );
	my $tag_url = $session->get_repository->get_conf( "perl_url" )."/users/tag/$objectid/$objecttype/insert"; #or not...

	my $objecttype_o = $objecttype;
	if($objecttype eq "eprint"){
		$objecttype_o =~ s/^(\w\w)(.*)/\U$1\L$2/g;
	}else{
		$objecttype_o = ucfirst($objecttype);
	}
	my $object = eval("EPrints::DataObj::$objecttype_o->new( \$session, \$objectid, \$session->get_repository->get_dataset( \"archive\" ) );");
#	my $repo_open = $session->phrase("sneep/tag:repository_open");
	
	my $img_src = $session->get_repository->get_conf( "base_url" )."/style/images/ajax-loader.gif";
	my $wait_icon = $session->make_element( "img", id=>"sneep_t_wait:".$objecttype_lc, src=>$img_src, style=>"border: none; display: none;" );

	# put down an invisible marker flagging component status (hidden or unhidden)
	my $view_flag = $session->make_element("span", id=>"sneep_t_view_flag:".$objecttype_lc, style=>"display: none;");
	$view_flag->appendChild($session->make_text("~cloud"));
	my $filter_flag = $session->make_element("span", id=>"sneep_t_filter_flag:".$objecttype_lc, style=>"display: none;");
	$filter_flag->appendChild($session->make_text("itemTags"));
	my $item_flag = $session->make_element("span", id=>"sneep_t_item_flag:".$objecttype_lc, style=>"display: none;");
	$item_flag->appendChild($session->make_text($objectid));

	my $tag_link_label = $session->html_phrase("sneep/tag:link_label");
	my $tag_link_label_js = $session->phrase("sneep/tag:link_label");
	my $tag_link_label_hide_js = $session->phrase("sneep/tag:link_label_hide");

	my $tag_link = $session->make_element("a", 
						  id=>"sneep_tag_link:".$objecttype_lc,
						  href=>"$tag_url", 
						  onclick=>"sneep_tag_toggle('sneep_t_main:".$objecttype_lc."',this,'$tag_link_label_js','$tag_link_label_hide_js', '".$objecttype."',$objectid); return false;");
	
	$tag_link->appendChild( $tag_link_label );
	$tag_header->appendChild( $tag_link );
	$tag_header->appendChild( $wait_icon );

	$tag_header->appendChild( $view_flag );
	$tag_header->appendChild( $filter_flag );
	$tag_header->appendChild( $item_flag );

	return $tag_header;

}

1;
