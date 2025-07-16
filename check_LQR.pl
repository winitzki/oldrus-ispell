#!/usr/bin/perl

# Check dictionary for various superfluous forms

# Usage: checkdict.pl < dictionary

# Read dictionary into hash

while(<STDIN>) {
	s/[\x0A\x0D]$//;
	m|^([^/]+)(/.*)?$|;
	if (defined($2)) {
		$dict{$1} = $2;
	} else {
		$dict{$1} = "";
	}
}

close STDIN;

foreach $word (keys %dict) {
	# Check flags LQR and add flag Z
	 $extra1 = "";
	 $extra2 = "";
	if ($word =~ /^(.*)оваться$/) {
	 $part=$1;
	 if ($dict{$word} =~ /^\/[LQR]+$/) {
		$extra1="${part}уются";
		$extra2="${part}уется";
		$extraflag = "Z";
	 }
	} elsif ($word =~ /(.*)ть(ся)?$/) {
	 $part=$1;
	 $suff=$2;
	 $suff="ъ" if ($suff eq "");
	 if ($dict{$word} =~ /^\/[LPR]+$/) {
		$extra1="${part}ют$suff";
		$extra2="${part}ет$suff";
		$extraflag = "S";
	 }
	}
	
		if (defined($dict{$extra1}) and defined($dict{$extra2})) {
			print "+$word$dict{$word}$extraflag\n", "-$word$dict{$word}\n", "-$extra1\n-$extra2\n";
		}
}
