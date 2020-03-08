$c->{set_document_defaults} = sub 
{
	my( $data, $session, $eprint ) = @_;

        $data->{content} = "published";
        $data->{language} = "es";
        $data->{license} = "cc_by_nc_nd";
	$data->{security} = "public";
};
