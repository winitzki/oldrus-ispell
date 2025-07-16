#!/usr/bin/perl

# Reads a dictionary and replaces words with flags C or D by pairs of words
# Removes flags C and D
# Note: these flags cannot occur simultaneously in any word

# Usage: perl rmflagsCD.pl  < dictionary > newdictionary
# Note: the resulting dictionary is unsorted

while(<>) {
	s/[\x0A\x0D]$//;
	if (/^(.*)(\/.*[CD].*)$/) {	# Word with either C or D flag
		$word = $1;
		$flags = $2;
		if ($flags =~ /C/) {
			$flags =~ s/C//;
			$flags =~ s/^\/$//;
#			if ($word =~ /[ ÿﬂ]$/) {
#				$word1 = $word . "”—";
#			} elsif ($word =~ /[¡≈…¶œ’¿—]$/) {
#				$word1 = $word . "”ÿ";
#			}
			$word1 = "⁄¡" . $word;
			print "$word1$flags\n";
		} elsif ($flags =~ /D/) {
			$flags =~ s/D//;
			$flags =~ s/^\/$//;
			$word1 = "Œ≈" . $word;
			print "$word1$flags\n";
		} else {
			print STDERR "Internal error 1\n";
		}
		print "$word$flags\n";
	} else {
		print "$_\n";
	}
}
