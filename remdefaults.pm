package remdefaults;

use Sys::Hostname;
use Cwd;

sub default_database {
    my $hostn = hostname;
    return "remfits" if $hostn eq "nancy" or $hostn eq "foxy";
    return "cluster" if $hostn eq "uhhpc" or $hostn =~ /herts\.ac\.uK/;
    "cluster";
}

sub get_tmpdir {
	my $td = $ENV{'REMTMP'};
	return $td if defined $td;
	getcwd;
}

1;
