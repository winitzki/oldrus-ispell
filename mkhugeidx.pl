#!/usr/bin/perl -w

# Script to make an index of the "hugelist" dictionary.
# Usage: mkhugeidx.pl [-length=...] < infile > outfile
#
# An index consists of lines of the form
#      314 word
# where 314 is the byte offset of the place where "word" starts in the file relative to the previous indexed word. The offset is terminated by a space and starts at the beginning of line. The first word has offset from the beginning of file.
# This is used by text_new2old.pl to speed up the search and reduce memory consumption.
#
# Algorithm: read the dictionary line by line, store the current word and the previous word, accumulate the length of the segment of the dictionary from the previous indexed point to the current point, and print an index line when this length exceeds a certain value. That value is a command-line option.

# Default bin length is 512
$bin_length = ("@ARGV" =~ /length=([0-9]*)/i) ? $1 : 512;

#print STDERR "Info: using bin length $bin_length\n";

$cur_length = 0;

# first nonempty line must be indexed
while(<STDIN>)
{
	if(/^\s*$/)
	{
		$cur_length += length($_);
	}
	else { last; }
}

print "$cur_length $_";
$cur_length = length($_);

while(<STDIN>)
{
	if ($cur_length + length($_) >= $bin_length)
	{	# print an index line corresponding to the current word
		print "$cur_length $_";
		$cur_length = length($_);
	}
	else
	{
		$cur_length += length($_);
	}
}

# last line must be indexed
