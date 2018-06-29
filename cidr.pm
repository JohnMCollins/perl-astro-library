package cidr;

use strict;
use Socket;
use Carp;

sub quad2bin ($) {
    my $quad = shift;
    my ($addr,$prof) = $quad =~ m;^([^/]+)(:?/(\d+))?$;;
    croak "Invalid IPv4 CIDR $quad" unless $addr;
	$addr = inet_aton($addr);
	croak "Invalid IPv4 addr $quad" unless $addr;
	$addr = unpack('L', $addr);
	if ($prof) {
		$prof += 0;
	}
	else {
		$prof = 32;
	}
	($addr, $prof);
}

sub bin2quad ($;$) {
    my $bin = shift;
    my $prof = shift or 32;
	my $addr = inet_ntoa(pack('L', $bin));
	$addr .= '/' . $prof if $prof < 32;
	$addr;
}
  
sub range2cidr ($$) {
    my $lo = shift;
    my $hi = shift;
    my @results;

    while ($lo <= $hi)  {
        
        my $prefix = 32;

        for (;;) {
            my $nmask = (0xffffffff << (33 - $prefix)) & 0xffffffff;
            last if ($lo & $nmask) < $lo;
            my $bcast = ($lo | ~$nmask) & 0xffffffff;
            last if $bcast > $hi;
            last if $prefix <= 0;
            $prefix--;
        }

        push @results, bin2quad($lo, $prefix);
        $lo = ((($lo | ~(0xffffffff << (32 - $prefix)))) & 0xffffffff) + 1;
    }
    
    @results;
}

sub cidr2range ($) {
	my $cidr = shift;
	my ($sip, $prof) = quad2bin($cidr);
	return ($sip, $sip) if $prof >= 32;
	my $mask = (0xffffffff << (32 - $prof)) & 0xffffffff;
	my $bcast = ($sip | ~$mask) & 0xffffffff;
	($sip, $bcast)
}

1;


