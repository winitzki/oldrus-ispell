#!/usr/bin/perl -w

# Script to convert new orthography text to old orthography using dictionary.
# Version 1.3 by Serge Winitzki. The script is part of the package oldrus-ispell
# and is distributed under GPL as free software.
# Needs a special dictionary and index ("make hugelistA.koi"). Uses the KOI8-C encoding.
# Looks up all words and replaces those found having yat', fita, i.
# If several words match, gives all variants. Preserves case of the first letters of words.

# Usage: text_new2old.pl [-dict=DICTFILE] [-index=INDEXFILE] [-noer] [-onlyone] [-mark=STRING] [-markall] [-readdict] < inputtext > outputtext
# The "-noer" option assumes that no trailing "yer" is desired (the dictionary does not have to conform to this)
# The "-onlyone" option suppresses output of variant spellings, only one variant is given, but word is marked by the "mark string" if several variants were possible
# The "-mark=..." option sets the string which will be used to mark variants. Default is asterisk "*"
# The "-dict=..." option sets dictionary file name (default "./hugelistA.koi")
# The "-index=..." option sets index file name (default "./hugelistA.idx")
# The "-markall" option additionally marks all words that were not found in the dictionary
# The "-readdict" option makes the script load the whole dictionary at once; this may be faster if a lot of RAM is available (about 40MB of *free* RAM). Default is not to load the whole dictionary but read parts of it from the file when necessary.

# Version history:
# 1.0	initial release, basic functionality
# 1.1	faster dictionary loading, bugfixes, improvements, needs less memory
# 1.2	reworked dictionary handling: now uses separately created index file (separate script "mkhugeidx.pl"), does not load the dictionary into memory (the OS will cache the file anyway), which reduces memory consumption and is faster when memory is low (unless -readdict option is given which may be faster if at least 40 MB of *free* RAM is available).
# 1.3	added some rules for words with "yo" that gets replaced by "yat'"

$want_noer = ("@ARGV" =~ /-noer/i) ? 1 : 0;
$want_no_variants = ("@ARGV" =~ /-onlyone/i) ? 1 : 0;
$dictname = ("@ARGV" =~ /-dict=([^ ]*)/i) ? $1 : "hugelistA.koi";
$indexname = ("@ARGV" =~ /-index=([^ ]*)/i) ? $1 : "hugelistA.idx";
$mark_string = ("@ARGV" =~ /-mark=([^ ]*)/i) ? "$1" : "*";
$want_mark_all = ("@ARGV" =~ /-markall/i) ? 1 : 0;

$want_read_dict = ("@ARGV" =~ /-readdict/) ? 1 : 0;

open(DICT, "$dictname") || die "Cannot read dictionary file '$dictname'\n";
open(INDEX, "$indexname") || die "Cannot read index file '$indexname'\n";
print STDERR "Reading index file '$indexname'...\n";

@bin_index = ();	# Array of first words in the bins, tr'd for sorting
@bin_pos = ();	# Array of string start positions of bins in $wordlist
$cur_bin = -1;	# The number of currently used bin
$part_of_dict = "";	# global to save memory

$prev_lcword = ""; $prev_capitalized = 0;	# globals for look-behind logic

# Read index file
$pos = 0;
while(<INDEX>)
{
	++$cur_bin;
	if (/^([0-9]+) (.*)$/)
	{
		$pos += $1;
		$bin_index[$cur_bin] = &tr_for_sort($2);
		$bin_pos[$cur_bin] = $pos;
	} else
	{
		print STDERR "Error: invalid line number $cur_bin in index file:\n$_";
	}
	
}
close INDEX;

# Read the whole dictionary file into one huge string $dictfile
if ($want_read_dict)
{
	$dictfile = "";
	&read_dictionary();
}

# Last bin has no word but it has an offset
$bin_pos[$cur_bin + 1] = $pos + length($bin_index[$cur_bin]);
# So the result is that @bin_index has one fewer elements than @bin_pos.

#print STDERR "Used $cur_bin bins\n";
print STDERR "Reading input text...\n";

@permitted_words = ();

$special_words{"���"} = "�΢";
$special_words{"����"} = "��΢";
$special_words{"��"} = "��";
$special_words{"ţ"} = "��";
$special_words{"���"} = "���";
$special_words{"�ţ"} = "���";

# Some special words have suppressed variants
$special_words{"����"} = "";
$special_words{"����"} = "";

# Some special words use look-behind
#$special_words{"���"} = "-";
#$special_words{"���"} = "-";
if ($want_noer) {
	$special_words{"����"} = "-";
	$special_words{"���"} = "-";
	$special_words{"���"} = "-";
	$special_words{"���"} = "-";
} else {
	$special_words{"�����"} = "-";
	$special_words{"����"} = "-";
	$special_words{"����"} = "-";
	$special_words{"����"} = "-";
}

while(<STDIN>) {	# Find words
	print "$1" if (/^([^�����������-��-�]+)/);	# the junk before the first word
	print &printword($1, $2) while (/([�����������-��-�]+)([^�����������-��-�]+)/g);	# $1 is word, $2 is the junk until the next word or until end
}

# End of main body

sub printword {
	my ($word, $nonword) = (@_);
	my ($i, $capitalized, $result, $lcresult, $lcword, $answer);
	$result = 0;
#	print STDERR "got word '$word' : '$nonword'\n";

	$capitalized = 0;	# This means either lowercase or mixed-case
	$trailing_yer = "�";	# This may need to be capitalized
	if ($word =~ /^([������-�])[������-�]+$/) {	# Capitalized word
		$capitalized = 1;
	} elsif ($word =~ /^[������-�]+$/) {	# Word in all capitals
		$capitalized = 2;
		$trailing_yer = "�";
	}
	$lcword = &koi_tolower($word);

	# Fix the dictionary in case it disagrees with the noer option
	if ($want_noer == 0 and $lcword =~ /([^�Ţ�ɦ����������])$/) {	# Add trailing yer
		if (length($word) > 1 or ($nonword !~ /^\./ and $lcword =~ /[���]/)) {	# Add trailing yer unless we have just one letter before a period, and unless it is a non-word
			$lcword .= "�";
			$word .= $trailing_yer;
		}
	} elsif ($want_noer == 1) {	# Remove trailing yer
		$lcword =~ s/([^�Ţ�ɦ����������])�$/$1/;
	}

#	print STDERR "got lcword '$lcword', cap. = $capitalized\n";

	$result = ($capitalized == 2) ? 0 : &convertword($word);	# First, search for the word as is, unless it is in all caps, in which case we assume that it is either not in the dictionary or not to be modified

	if ($capitalized > 0 and $result == 0) {	# Word was not lowercase and not found; try lowercase
		$result = &convertword($lcword);
		if ($result == 0 and $capitalized == 2) {	# Word was in all capitals and not found in lowercase form; try capitalizing the first letter only
			substr($lcword, 0, 1) = &koi_toupper(substr($lcword, 0, 1));
			$result = &convertword($lcword);
			$lcword = &koi_tolower($lcword);
			# Regardless of success here, we are on the right way
		}
		# Now, the list of lowercase variants is in @permitted_words and needs to be capitalized back
		# Avoid capitalizing yer after one-letter prepositions
		if ($want_noer == 0 and $lcword =~ /^[���]�$/ and $capitalized == 2) {
			$capitalized = 1 unless ($prev_capitalized == 2);
		}
		for ($i = 0; $i <= $#permitted_words; ++$i) {
			if ($capitalized == 1) {
				substr($permitted_words[$i], 0, 1) = &koi_toupper(substr($permitted_words[$i], 0, 1));
			} elsif ($capitalized == 2) {
				$permitted_words[$i] = &koi_toupper($permitted_words[$i]);
			}
		}
#	} else {	# Word is not capitalized, or it was capitalized and found in the dictionary, so proceed normally
	}
	if ($result == 0) {	# Word was not found
		$answer = $word;
		$answer = $mark_string . $answer if ($want_mark_all);
	} elsif ($want_no_variants and $#permitted_words > 0) {
		$i = " @permitted_words ";
		if ($i =~ / $word /) {	# Word was permitted, so no change
			$answer = $word;
		} else {	# Choose a variant
			$answer = $permitted_words[0];
		}
		$answer = $mark_string . $answer;
	} else {
		$answer = ($#permitted_words == 0) ? "@permitted_words" : "{{@permitted_words}}";
	}

	$prev_lcword = $lcword;
	$prev_capitalized = $capitalized;

	return $answer . $nonword;
}

sub convertword {
	# Find the old orthography analog of a word in the dictionary
	# All variants are returned in the global array @permitted_words
	# 1 is returned if variants were found
	# If word was not found in the dictionary, 0 is returned but the word is still put into @permitted_words
	# Assume that at most the first letter is capitalized and that the lowercase variant is tried before the capitalized
	my ($word) = (@_);
	my ($lcword, $word_a, $word_b, $word_re, $bin_i, $bin_b, $word1, $suff1);

#	print STDERR "convert: got word '$word'\n";

	# First, check special words (they are all lowercase)
	if (defined($special_words{$word})) {
		$permitted_words[0] = $word;	# put it there for now
		if ($special_words{$word} eq "-") {	# use look-behind
			if ($word =~ /^(����|���|���|���)�?$/) { # � or �?
				if ($prev_lcword =~ /^(�|��|���|��|���)�?$/ or ($prev_lcword =~ /^(�|��)�?$/ and $word =~ /^(���|���)�?$/)) {	# instrumental case, use �
					#$permitted_words[0] =~ s/�/�/;
				} elsif ($prev_lcword =~ /^(�|���|��|�|��|��|��|�)�?$/) {	# nominative case, use �
					$permitted_words[0] =~ s/�/�/;
				} elsif ($prev_lcword =~ /^(������|�����|������)�?$/ and $word =~ /^(����|���|���)�?$/) {
					$permitted_words[0] =~ s/�/�/;
				} else {	# undecided
					$permitted_words[1] = $word;
					$permitted_words[1] =~ s/�/�/;
				}
			}
		} else {
			# Sometimes a second variant is suppressed
			$permitted_words[1] = $special_words{$word} if ($special_words{$word} ne "");
		}
		return 1;
	} else {
		@permitted_words = ();
		$lcword = &koi_tolower($word);
		# Determine if the word is to be looked up at all
		if ($lcword =~ /[ţ�]/ or $lcword =~ /�[�ţɦ��������]/ or $lcword =~ /���/ or $lcword =~ /([��]��|[��]�)(��)?$/ or $lcword =~ /(��|�|��|��)��/) {	# Word has some interesting letters
			# Replace letters by classes and compute boundary words
			$word_a = $word;
			$word_b = $word;
			$word_re = $word;
			# must be $word_a < $word_re < $word_b for any match of $word_re
			# Order of replacements is important. Also, make sure "e" is after [
			$word_re =~ s/�/[Ƭ]/g;
			$word_re =~ s/�/[�]/g;
			$word_b =~ tr/��/��/;
			# ���-� ��-� ���-� ���-�
			$word_re =~ s/([��]�|[��]|[��][��])��/{$1 . "[��]�";}/ge;
			$word_a =~ s/([��]�|[��]|[��][��])��/{$1 . "��";}/ge;
			# ���-
			$word_re =~ s/([��]�)�([����������])/{$1 . "[��]$2";}/e;
			$word_a =~ s/([��]�)�([����������])/{$1 . "�$2";}/e;

			$word_re =~ s/�(��(��)?)$/[��]$1/;
			$word_a =~ s/�(��(��)?)$/�$1/;
			$word_re =~ s/�(��(��)?)$/[���]$1/;	# order of letters is important
			$word_a =~ s/�(��(��)?)$/�$1/;
			$word_b =~ s/�(��(��)?)$/�$1/;

			$word_re =~ s/([��])[ɦ]�/{$1 . "[��]�";}/e;
			$word_b =~ s/([��])[ɦ]�/{$1 . "��";}/e;

			$word_re =~ s/([ɦ�])�$/{(($1 eq "�") ? "�" : "�") . "[��]";}/e;	# important: "��"
			$word_b =~ s/([ɦ�])�$/{(($1 eq "�") ? "�" : "�") . "�";}/e;
			$word_re =~ s/([ɦ�])���$/{(($1 eq "�") ? "�" : "�") . "[��]��";}/e;
			$word_b =~ s/([ɦ�])���$/{(($1 eq "�") ? "�" : "�") . "���";}/e;
			# If $word_re contains "�[��]", we'll need to check adjectives
			$need_check_adjectives = ($word_re =~ /[^�]\[��\]/) ? 1 : 0;	# use "��"
			# i before a vowel
			$word_re =~ s/�([�ţɦ��������])/[ɦ]$1/g;
			$word_re =~ s/�([�ţɦ��������])/[�]$1/g;
			$word_b =~ s/�([�ţɦ��������])/�$1/g;
			$word_b =~ s/�([�ţɦ��������])/�$1/g;

			# Replace e/yo/yat'
			$word_re =~ s/(?<=[^\[])�/[ţ�]/g;
			# Special cases when yo is represented by yat'
			$word_re =~ s/([������])�/$1\[��\]/g;
			# Beginning of line - now careful, since some e's are inside []
			$word_re =~ s/^�/[ţ�]/;
			$word_re =~ s/^�/[�]/;
			# Prepare the upper boundary for search: lex. order e, yat', yo
			$word_b =~ s/(?<=[^\[])�/�/g;
			$word_b =~ s/([������])�/$1�/g;
			# Cannot have yo replaced at the beginning of word
			$word_b =~ s/^�/�/;
			$word_b =~ s/^�/�/;
			# Prepare the lower boundary: must make e out of yo
			$word_a =~ s/([������])�/$1�/g;

#		print STDERR "convert: searching '$word_a' < '$word_re' < '$word_b'\n";

			# Find the range of dictionary bins to search
			$bin_i = &find_bin($word_a);
			$bin_b = &find_bin($word_b);

	#	print STDERR "Looking up word '$word_re' in bins $bin_i to $bin_b, check_adj=$need_check_adjectives\n";
			# Look through the bins and accumulate @permitted_words

			# Find all matches
			# obtain the segment of the dictionary containing both bins
			&get_segment($bin_i, $bin_b, \$part_of_dict);
	#		print STDERR "searching bins $bin_i to $bin_b, positions $bin_pos[$bin_i], $bin_pos[$bin_b+1]\n";
			while ($part_of_dict =~ /(?<=\n)($word_re)(( [^ \n]+)?\n)/g) {
				$word1 = $1; $suff1 = $2;
				if ($need_check_adjectives == 0 or $suff1 =~ /A/ or $word1 =~ /��$/) {	# Allow alternative form ending with -�� only if that form is marked A (adjective) in the dictionary
					push (@permitted_words, $word1);
	#			} else {	# This happens with -��, -�� endings in non-adjectives that still have the -��, -�� forms for some reason - ignore for now
	#				print STDERR "Word pattern '$word_re' gave unneeded match '$word1'\n";
				}
			}
			# Finished finding all matches

			if ($#permitted_words >= 0) {	# more than one variant spelling
				return 1;
			} else {	# Nothing was found
				$permitted_words[0] = $word;
				return 0;
			}
		} else {	# Word was not interesting
			$permitted_words[0] = $word;
			return 1;
		}
	}
}

sub find_bin {
	# Lookup in a sorted array, using global @bin_index
	my ($word) = (@_);
	my ($a, $b, $c, $word1);
	$word1 = $word;
	$a = 0;
	$b = $#bin_index;
	$word1 = &tr_for_sort($word1);
	# The word must be >= a but if it is not we still assume it is in the bin 0
	if ($word1 lt $bin_index[$a]) {
		return 0;
	} elsif ($word1 ge $bin_index[$b]) {
		return $b;
	}
	while ($b-$a>1) {
		$c = int(($b+$a)/2);
		if ($word1 lt $bin_index[$c]) {
			$b = $c;
		} else {
			$a = $c;
		}
	}
#	print STDERR "for word '$word' found bin number $a with index '$bin_index[$a]'\n";
	return $a;
}

sub koi_tolower {
	my ($word) = (@_);
	$word =~ tr/�����峲��鶱�����������������������/�����ţ���ɦ������������Ƭ�����������/;
	return $word;
}

sub koi_toupper {
	my ($word) = (@_);
	$word =~ tr/�����ţ���ɦ������������Ƭ�����������/�����峲��鶱�����������������������/;
	return $word;
}

sub tr_for_sort {
	my ($word) = (@_);
	$word =~ tr/�����岳��鶱����������������������������Ţ���ɦ������������Ƭ�����������/��������������������������������������������������������������������������/;
	return $word;
}

# produce the portion of the dictionary that covers both bins; this is found at offsets $bin_pos[$bin1] to $bin_pos[$bin2+1]
# one of two methods is used, depending on $want_read_dict

sub get_segment {
	my ($bin1, $bin2, $result) = (@_);
	if ($want_read_dict)
	{
# method 1: use a substring of a huge string: this seems slower
		$$result = substr($dictfile, $bin_pos[$bin1]-1, $bin_pos[$bin2+1] - $bin_pos[$bin1]+1);
	}
	else
	{
# method 2: use file reading every time, hoping that the OS cache will speed this up
	#	$$result = "";
		seek(DICT, $bin_pos[$bin1]-1,0);
		print STDERR "Error: could not read from dictionary file\n" if (read(DICT, $$result, $bin_pos[$bin2+1]-$bin_pos[$bin1]+1) != $bin_pos[$bin2+1]-$bin_pos[$bin1]+1);
	}
}

sub read_dictionary  {
	print STDERR "Reading dictionary file '$dictname'...\n";
	my $old_line_separator = $/;
	undef $/;
	$dictfile = <DICT>;
	$/ = $old_line_separator;
	close DICT;
}

