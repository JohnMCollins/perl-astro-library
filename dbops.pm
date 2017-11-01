# Database operations using credientials

package dbops;

use DBI;
use Carp;
use dbcredentials;

sub opendb ($) {
    my $name = shift;
    my $creddb = dbcredentials->new;
    my $creds = $creddb->get($name);
    my $dbase = DBI->connect("DBI:mysql:database=$creds->{database};host=$creds->{host}", $creds->{user}, $creds->{password});
    croak "Cannot open DB for $name" unless $dbase;
    $dbase;
}

1;
