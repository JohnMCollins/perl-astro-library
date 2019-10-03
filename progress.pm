package progress;
use Term::ReadKey;
use Carp;

sub new {
	my ($class, %args) = @_;
	my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();
	croak "Cannot find terminal size" unless defined $wchar;
	croak "Terminal width too short" unless $wchar > 20;
	my $self = {};
	$self->{WIDTH} = $wchar;
	$self->{CURRENT} = -1;
	$self->{LIMIT} = 0;
	$self->{SCALE} = 0;
	$self->{CURRENT} = $args{-current} if defined $args{-current};
	$self->{LIMIT} = $args{-limit} if defined $args{-limit};
	$self->{SCALE} = $args{-scale} if defined $args{-scale};
	$self->{DISPLAY} = "";
	$self->{FORMAT} = $self->{SCALE} <= 0? "%3.0f%%:": sprintf "%%%d.%df%%%%:",  $self->{SCALE}+4, $self->{SCALE};
	$self->{HWIDTH} = $self->{SCALE} <= 0? $self->{WIDTH} - 6: $self->{WIDTH} - $self{SCALE} - 7;
	bless $self, $class;
	$self->update;
	$self;
}

sub setlimit ($) {
	my $self = shift;
	my $limit = shift;
	$self->{LIMIT} = $limit;
	$self->update;
}

sub update (;$) {
	my $self = shift;
	my $value = shift;
	return if $self->{LIMIT} == 0;
	if (length($self->{DISPLAY}) == 0)  {
		  $self->{CURRENT} = $value if defined $value;
		  return if $self->{CURRENT} < 0;
	}
	else  {
	   return unless defined $value and $value != $self->{CURRENT};
	   print "\r";
	   $self->{CURRENT} = $value;
	}
	my $frac = $self->{CURRENT} / $self->{LIMIT};
    $self->{DISPLAY} = sprintf $self->{FORMAT}, $frac * 100.0;
    my $hashes = int($self->{HWIDTH} * $frac + 0.5);
    my $dots = $self->{HWIDTH} - $hashes;
    print $self->{DISPLAY}, '#' x $hashes, "." x $dots;
    select()->flush();
    $self;
}

sub finish {
	my $self = shift;
	return if length($self->{DISPLAY}) == 0;
	print "\n";
}

1;