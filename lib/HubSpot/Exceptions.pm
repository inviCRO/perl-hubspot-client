package Exception;
	use base qw(Error);

	sub new
	{
		my $self = shift;
		my $text = "" . shift;
		my @args = ();

		local $Error::Depth = $Error::Depth + 1;
		local $Error::Debug = 1;  # Enables storing of stacktrace

		$self->SUPER::new(-text => $text, @args);
	}
  
	sub stringify
	{
		my $self = shift;
		return __PACKAGE__.": ".$self->stacktrace();
	}
1;

package UnknownTypeException;
	use base qw(Exception);
	
	sub stringify { my $self = shift; return __PACKAGE__.": ".$self->stacktrace(); }
1;

package NoPrimaryEmailFoundException;
	use base qw(Exception);
	
	sub stringify { my $self = shift; return __PACKAGE__.": ".$self->stacktrace(); }
1;

