#!/usr/bin/perl -w

# Read a text file and a corrections file and insert corrections as comments /**/
# Usage: insert-words.pl corr-file.txt < inputfile.txt > output.txt
# Format of corrections file: each line contains a wrong word preceded by spaces, preceded by comments
# e.g. 
# corr-file contains:
#	-ior? behaviour
#	-nce? license
# inputfile contains:
#	the license for the behaviour
# outputfile contains:
#	the /*-nce?*/license for the /*-ior?*/behaviour
#
# First, prepare the list of misspelt words using "ispell -l | sort | uniq". Then look at that file and delete the words that are not misspelt. In front of each word that is clearly misspelt, optionally insert a comment string and a space.
# 

# for now, use Russian defaults (this should be eventually fixed)
# This means that only non-lower ASCII text will be considered as significant, while A-Za-z etc. will be considered word boundary characters.

$wb = '[- \t\nA-Za-z0-9_=+;:\'`",.<\[\]\{\}>?/`~!@#$%^&*()|]';

$old_nl = $/;

undef $/;
$input = <STDIN>;

$/ = $old_nl;

open CORR, $ARGV[0] || die "cannot open input file '$ARGV[0]'\n";



while(<CORR>)
{
	chomp;
	if (/^\s*([^ \t]+)\s*$/)
	{	# one word
		$word = $1;
		print STDERR "debug: single word $word\n";
		$input =~ s,($wb)$word($wb),$1/*?*/$word$2,g;
	}
	elsif (/^\s*(.+)\s\s*([^ \t]+)\s*$/)
	{
		$comment = $1;
		$word = $2;
		print STDERR "debug: word $word, comment $comment\n";
		$input =~ s,($wb)$word($wb),$1/*$comment*/$word$2,g;
	}
}

print $input;
