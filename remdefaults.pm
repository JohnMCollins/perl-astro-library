package remdefaults;

use Sys::Hostname;
use Cwd;

sub default_database {
    my $hostn = hostname;
    return "remfits" if $hostn eq "nacny" or $hostn eq "foxy";
    return "cluster" if $hostn eq "uhhpc" or $hostn =~ /herts\.ac\.uK/;
    "remfits";
}

sub get_tmpdir {
	my $td = $ENV{'REMTMP'};
	return $td if defined $td;
	getcwd;
}

1;