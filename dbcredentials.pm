# @Author: John M Collins <jmc>
# @Date:   2017-11-01T18:09:34+00:00
# @Email:  jmc@toad.me.uk
# @Filename: dbcredentials.pm
# @Last modified by:   jmc
# @Last modified time: 2019-01-17T16:08:21+00:00

# Attempts to do the same thing as ther Python version

package dbcredentials;
use Cwd 'abs_path';
use Carp;

our $Configfilepaths;
our @credfields = qw/host database user password/;
our @addfields = qw/login localport remoteport/;

$Configfilepaths->{system} = '/etc/dbcred.ini';

my $hdir;
if (defined $ENV{'HOME'})  {
    $hdir = $ENV{'HOME'};
}
else  {
    my @pwbits = getpwuid($<);
    $hdir = $pwbits[7];
}
$Configfilepaths->{lib} = $hdir . '/lib/dbcred.ini';
$Configfilepaths->{current} = abs_path('.dbcred.ini');

our %Sysdict;

$Sysdict{DBHOST} = 'localhost';
for my $e (qw/LOGNAME DBHOST/)  {
    $Sysdict{$e} = $ENV{$e} if defined $ENV{$e};
}

sub parsefile {
    my $this = shift;
    my $fsn = shift;
    return $this unless open(CF, $Configfilepaths->{$fsn});
    my $csect = 'DEFAULT';
    while (<CF>)  {
        chop;
        if (/^\s*\[(\w+)\]\s*$/)  {
            $csect = $1;
            next;
        }
        if (/\s*(\w+)\s*=\s*(.*)/)  {
            $this->{$csect}->{$1} = $2;
            next;
        }
    }
    close CF;
    $this;
}

sub new {
    my $class = shift;
    my $this = {};
    bless $this, $class;
    $this->{DEFAULT} = {};
    $this->parsefile('system');
    $this->parsefile('lib');
    $this->parsefile('current');
    $this;
}

sub lookup_var {
    my $this = shift;
    my $name = shift;
    my $var = shift;
    return $this->{$name}->{$var} if exists($this->{$name}->{$var});
    return $this->{DEFAULT}->{$var} if exists($this->{DEFAULT}->{$var});
    return $Sysdict{$var} if exists $Sysdict{$var};
    croak "Cannot find var $var in lookup";
}

sub expand_vars {
    my $this = shift;
    my $name = shift;
    my $orig = shift;
    my $text = $orig;
    my $n = 10;
    while  ($text =~ s/%\((\w+)\)/$this->lookup_var($name, $1)/eg) {
        croak "Too many leverls of recursion in $orig" if --$n <= 0;
    }
    $text;
}

sub get {
    my $this = shift;
    my $name = shift;
    croak "No section $name defined" unless defined $this->{$name};
    my $ret = {};
    for my $part (@credfields)  {
        my $p = $this->{$name}->{$part} || $this->{DEFAULT}->{$part};
        croak ucfirst $part . " missing from section $name" unless defined $p;
        $p = $this->expand_vars($name, $p) unless $part eq 'password';
        $ret->{$part} = $p;
    }
    for my $part (@addfields) {
        my $p = $this->{$name}->{$part} || $this->{DEFAULT}->{$part};
        $ret->{$part} = $p;
    }
    $ret;
}

sub set_creds {
    my $this = shift;
    my $name = shift;
    my $creds = shift;
    $this->{$name} = {} unless exists $this->{$name};
    while (my ($k,$v) = each %$creds)  {
        $this->{$name}->{$k} = $v;
    }
    for my $c (@credfields, @addfields) {
        delete $this->{$name}->{$c} unless exists $creds->{$c};
    }
    $this;
}

sub set_defaults {
    my $this = shift;
    my $creds = shift;
    $this->set_creds('DEFAULT', $creds);;
}

sub delcreds {
    my $this = shift;
    my $sectname = shift;
    delete $this->{$sectname} if exists($this->{$sectname}) && $sectname ne 'DEFAULT';
    $this;
}

sub writesect {
    my $this = shift;
    my $sect = shift;
    print CF "[$sect]\n";
    for my $i (sort keys %{$this->{$sect}})  {
        print CF "$i=$this->{$sect}->{$i}\n";
    }
    $this;
}

sub write {
    my $this = shift;
    my $filename = shift || 'lib';
    $filename = $Configfilepaths->{$filename} if exists($Configfilepaths->{$filename});
    croak "Cannot open $filename" unless open(CF, ">$filename");
    $this->writesect('DEFAULT');
    for my $s (sort keys %$this) {
        next if $s eq 'DEFAULT';
        print CF "\n";
        $this->writesect($s);
    }
    close CF;
    $this;
}

1;
