#!/usr/bin/perl

# find duplicated words and merge flags

$count = ("@ARGV" =~ /-c ([0-9]+)/) ? $1 : 0;

$merged = 0;

$oldflags = $oldword = "";

while(<STDIN>) {
	chomp;
	if (/^([^ \/]+)(\/.*)?$/) {
		$word = $1;
		$flags = $2 || "";
		$flags =~ s|^/||;
		if ($word eq $oldword and ($count == 0 or $merged < $count)) {	# repeated word
			$oldflags .= $flags;
			++$merged;
			$repeated = 1;
		} else {	# not repeated word
			if ($oldword ne "") {	# not first line
				&print_previous_line;
			}
			$oldword = $word;
			$oldflags = $flags;
			$repeated = 0;
		}
	$word=$1;
	$flags=$2 || "";
	}
}
&print_previous_line;

sub print_previous_line {
	$oldflags = join("", sort(split(//, $oldflags))) if ($repeated);
	print $oldword . (($oldflags ne "") ? "/" : "") . $oldflags . "\n";
}
