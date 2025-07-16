#!/usr/bin/perl

# Apply flags patch to a dictionary

# Usage: applyflags.pl flagsfile < srcdict > targetdict

# example: flagsfiles contains "\n/\n/A\n" and srcdict contains "word1/A\nword2/B\nword3/C\n". Then targetdict will be "word1/A\nword2\nword3/A\n"

open(FLAGS, "$ARGV[0]") || die "Error: cannot open flags file '$ARGV[0]'\n";

while(<STDIN>) {
	$newflag = <FLAGS>;
	s/[\x0A\x0D]$//;
	$newflag =~ s/[\x0A\x0D]$//;
	m|^([^ \t/]+)([ \t/].*)?$|;
	$word = $1;
	$flag = $2;
	if ($newflag eq "/") {
		$flag = "";
	} elsif ($newflag ne "") {
		$flag = $newflag;
	}
	print "$word$flag\n";
}
