#!/usr/bin/perl

# Print duplicated words

$need=1;

while(<>) {
	if (/^(.*)(\/.*)$/ or /^(.*)$/) {
		if ($word eq $1) {
			print"$word$cat\n" if ($need);
			print;
			$need=0;
		} else {
			$need=1;
		}
	$word=$1;
	$cat=$2;
	}
}
