# @Author: John M Collins <jmc>
# @Date:   2017-11-01T18:09:34+00:00
# @Email:  jmc@toad.me.uk
# @Filename: dbops.pm
# @Last modified by:   jmc
# @Last modified time: 2019-01-17T17:43:58+00:00

# Database operations using credientials

package dbops;

use DBI;
use Carp;
use dbcredentials;

sub connlocal {
    my $creds = shift;
    my %attr = (
        PrintError => 0,
        RaiseError => 0
    );
    $dbase = DBI->connect("DBI:mysql:database=$creds->{database};host=127.0.0.1;port=$creds->{localport}", $creds->{user}, $creds->{password}, \%attr);
}

sub opendb ($) {
    my $name = shift;
    my $creddb = dbcredentials->new;
    my $creds = $creddb->get($name);
    unless  ($creds->{login})  {
        my $dbase = DBI->connect("DBI:mysql:database=$creds->{database};host=$creds->{host}", $creds->{user}, $creds->{password});
        croak "Cannot open DB for $name" unless $dbase;
        return  $dbase;
    }
    # First try assumes SSH running
    my $dbase = connlocal($creds);
    return $dbase if $dbase;
    if (fork == 0)  {
        my @args = ("-nNT", "-L", "$creds->{localport}:localhost:$creds->{remoteport}", "$creds->{login}\@$creds->{host}");
        exec "ssh", @args;
        exit 255;
    }
    sleep 5;
    $dbase = connlocal($creds);
    croak "Cannot open DB for $name after starting ssh" unless $dbase;
    $dbase;
}

1;
