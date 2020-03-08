$c->{irstats_abstract_content} = sub
{
	my ($session, $eprint) = @_;

	my $frag = $session->make_doc_fragment;

	my $repository = $session->get_repository;

        my @documents = $eprint->get_all_documents();
        my $docs_to_show = scalar @documents;

	if ($docs_to_show > 0)
	{
		$frag->appendChild($repository->call('irstats_js', $session));

                my $div = $session->make_element( "div", class=>"ep_block" );
                $frag->appendChild( $div );
                my $h2 = $session->make_element( "h2" );
                $h2->appendChild( $session->make_text( "Fulltext Downloads" ) );
                $div->appendChild( $h2 );

		my $graph1_div = $session->make_element('div', id => 'irstats_graph1');
		$div->appendChild($graph1_div);
		my $graph2_div = $session->make_element('div', id => 'irstats_graph2');
		$div->appendChild($graph2_div);

		$div->appendChild($repository->call(
			'insert_irstats_view',
			$session,
			'irstats_graph2',
			$repository->call('irstats_eprint_monthly_downloads_params', $eprint->get_id)
		));

		$div->appendChild($repository->call(
			'insert_irstats_view',
			$session,
			'irstats_graph1',
			$repository->call('irstats_eprint_daily_downloads_params', $eprint->get_id)
		));

	}

	return $frag;
};


$c->{irstats_js} = sub
{
	my ($session) = @_;

	return $session->make_javascript('
        function js_irstats_load_stats(div_id,params)
        {

                new Ajax.Request(
                        eprints_http_cgiroot+"/irstats.cgi",
                        {
                                method: "post",
                                onFailure: function() {
                                        alert( "AJAX request failed..." );
                                },
                                onException: function(req, e) {
                                        alert( "AJAX Exception " + e );
                                },
                                onSuccess: function(response){
                                        var text = response.responseText;
                                        if( text.length == 0 )
                                        {
                                                alert( "No response from server..." );
                                        }
                                        else
                                        {
                                                $(div_id).innerHTML = response.responseText;
                                        }
                                },
                                parameters: params
                        }
                );
        }
');

};

$c->{insert_irstats_view} = sub
{
	my ($session, $div_id, $params) = @_;

	my @params;
	foreach (keys %{$params})
	{
		push @params, $_ . " : '" . $params->{$_} . "'";
	}
	my $params_string = join(" , ", @params);

	return $session->make_javascript("

        Event.observe(window,'load',function () {
                        js_irstats_load_stats( '$div_id', { $params_string } );
                });
	");
};

$c->{irstats_eprint_daily_downloads_params} = sub
{
	my ($eprintid) = @_;

	return {
		'page' => 'get_view2',
		'IRS_epchoice' => 'EPrint',
		'eprint' => $eprintid,
		'IRS_datechoice' => 'period',
		'period' => '-1m',
		'view' => 'DailyDownloadsGraph',
	};
};

$c->{irstats_eprint_monthly_downloads_params} = sub
{
	my ($eprintid) = @_;

	return {
		'page' => 'get_view2',
		'IRS_epchoice' => 'EPrint',
		'eprint' => $eprintid,
		'IRS_datechoice' => 'period',
		'period' => '-12m',
		'view' => 'MonthlyDownloadsGraph',
	};
};

