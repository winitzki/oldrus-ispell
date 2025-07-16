#!/usr/bin/perl

# Remove given lines from stdin
# Usage: excludelines sourcefile [-onlyfirst|-all|-counted] [-quiet] [-start] < input > output 2> error_output
# All lines in input stream will be printed except those that are in sourcefile
# -start makes it only compare the first word on the line (space, tab or / delimited)
# -quiet suppresses information messages
# Options not currently implemented:
# -onlyfirst, -all, -counted: specify how many coincident lines to remove:
# -onlyfirst removes only the first encountered line, -all removes all such lines,
# -counted removes exactly as many lines as found in the source file.
# Error output consists of lines that were to be excluded but were not encountered in input stream

$excl= $ARGV[0];

$onlyfirst = ("@ARGV" =~ /-start/) ? 1 : 0;
$verbose = ("@ARGV" =~ /-quiet/) ? 0 : 1;
$counted = ("@ARGV" =~ /-counted/) ? 1 : 0;

open(EXCL, "$excl");
$n=0;
while(<EXCL>) {
	s/[\x0A\x0D]+$//;
	$line = $_;
	if ($onlyfirst) {
		$line =~ s|^([^ \t/]+)([ \t/].*)?$|$1|;
	}
	++$excl{$line};
	++$n;
}
close(EXCL);
print STDERR "excludelines: info: Read $n lines from file '$excl'.\n" if ($verbose);

while(<STDIN>) {
	s/[\x0A\x0D]+$//;
	$line = $_;
	if ($onlyfirst) {
		$line =~ s|^([^ \t/]+)([ \t/].*)?$|$1|;
	}
	if(defined($excl{$line})) {	# Line identified as potentially to be excluded
		if ($counted) {	# Exclude only as many lines as we had seen
			if ($excl{$line} > 0) {	# Still have some exclusion lines left
				--$excl{$line};	# Decrement count
			} else {	# No exclusion lines left, so do not exclude
				print "$_\n";
			}
		} else {
			$excl{$line}=0;	# Mark this line as encountered
		}
	} else {
		print "$_\n";
	}
}
# Find a nonzero value in %excl
$have=0;
foreach $a (values %excl) {
	if ($a) {
		$have=1;
		last;
	}
}
if ($have and $verbose) {
	print STDERR "excludelines: info: Lines not encountered:\n";
	foreach $a (keys %excl) {
		print STDERR "$a\n" if ($excl{$a});
	}
}
