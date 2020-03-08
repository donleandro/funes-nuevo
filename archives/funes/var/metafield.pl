push @{$c->{fields}->{eprint}}, (
	{
          'top' => 'enfoque',
          'allow_null' => 0,
          'required' => 1,
          'name' => 'enfoque',
          'type' => 'subject',
          'providence' => 'user'
        },
	{
          'allow_null' => 0,
          'name' => 'valoration',
          'required' => 1,
          'type' => 'text',
          'providence' => 'user'
        },
);

