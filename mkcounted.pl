#!/usr/bin/perl -w
require 5.0;
use integer;
#use strict;

# Create lists of Russian "counting adjectives".
# Also, subroutines to convert integers to Russian language numerals in the nominative and genitive cases.
# Usage: mkcounted.pl [-old|-new] -dict filename
# the -old option is to generate words in the old orthography (default),
# the -new option is for new orthography
# the -dict option specifies the file name for dictionary
# dictionary format: 
#	dictionary = line [line] ...
#	line = flag_declaration | word_declaration | comment
#	comment = # <comment text>
#	flag_declaration = /<FLAGS>
#	word_declaration = <word> <number> [ <number> | - <number>] ...
# For example:

#	   # regular nouns
#	/K
#	������� 1 2 - 12 100
#	   # adjectives
#	/A
#	������ 1 2 3 - 12


# Russian words

%ru_nominative = (
"-" => "������",
"0" => "����",
"1" => "�����",
"1:f" => "����",
"2" => "���",
"2:f" => "�ע",
"3" => "���",
"4" => "������",
"5" => "����",
"6" => "�����",
"7" => "����",
"8" => "������",
"9" => "������",
"10" => "������",
"11" => "�����������",
"12" => "�ע�������",
"13" => "����������",
"14" => "������������",
"15" => "����������",
"16" => "�����������",
"17" => "����������",
"18" => "������������",
"19" => "������������",
"20" => "��������",
"30" => "��������",
"40" => "������",
"50" => "����������",
"60" => "�����������",
"70" => "����������",
"80" => "������������",
"90" => "���������",
"100" => "���",
"200" => "������",
"300" => "������",
"400" => "���������",
"500" => "��������",
"600" => "���������",
"700" => "��������",
"800" => "����������",
"900" => "����������",
"1000" => "������",
"1000:2" => "������",
"1000:5" => "������",
"1000000" => "���̦���",
"1000000:2" => "���̦���",
"1000000:5" => "���̦�����",
"1000000000" => "���̦����",
"1000000000:2" => "���̦����",
"1000000000:5" => "���̦������",
"1000000000000" => "����̦���",
"1000000000000:2" => "����̦���",
"1000000000000:5" => "����̦�����",
"1000000000000000" => "�������̦���",
"1000000000000000:2" => "�������̦���",
"1000000000000000:5" => "�������̦�����",
"1000000000000000000" => "�������̦���",
"1000000000000000000:2" => "�������̦���",
"1000000000000000000:5" => "�������̦�����",
);

%ru_counting = (
"-" => "������",
"0" => "����",	# e.g. ����͢����
"1" => "����",
"1:f" => "����",
"2" => "�����",
"2:f" => "�����",
"2'" => "���",
"3" => "�ң��",
"3'" => "���",
"4" => "����ң��",
"5" => "����",
"6" => "�����",
"7" => "����",
"8" => "������",
"8'" => "�����",
"9" => "������",
"10" => "������",
"11" => "�����������",
"12" => "�ע�������",
"13" => "����������",
"14" => "������������",
"15" => "����������",
"16" => "�����������",
"17" => "����������",
"18" => "������������",
"19" => "������������",
"20" => "��������",
"30" => "��������",
"40" => "������",
"50" => "����������",
"60" => "�����������",
"70" => "����������",
"80" => "������������",
"90" => "���������",
"100" => "���",
"200" => "��������",
"300" => "�ң�����",
"400" => "����ң�����",
"500" => "��������",
"600" => "���������",
"700" => "��������",
"800" => "����������",
"900" => "����������",
"1000" => "������",
"1000:2" => "������",
"1000:5" => "������",
"1000000" => "���̦����",
"1000000:2" => "���̦����",
"1000000:5" => "���̦����",
"1000000000" => "���̦�����",
"1000000000:2" => "���̦�����",
"1000000000:5" => "���̦�����",
"1000000000000" => "����̦����",
"1000000000000:2" => "����̦����",
"1000000000000:5" => "����̦����",
"1000000000000000" => "�������̦����",
"1000000000000000:2" => "�������̦����",
"1000000000000000:5" => "�������̦����",
"1000000000000000000" => "�������̦����",
"1000000000000000000:2" => "�������̦����",
"1000000000000000000:5" => "�������̦����",
);


# Russian crazy numerals index
sub crazy_index
{
	my $num = shift;
	if ($num >= 10 and $num <= 19 or ($num % 10 == 0) or ($num % 10 >= 5))
	{
		return ":5";
	}
	elsif ($num % 10 == 1)
	{
		return "";
	}
	else
	{
		return ":2";
	}
}

# return string corresponding to the integer
# this subroutine is not used to generate words, but I wanted to have it anyway.
sub numeral_ru
{
	my $num = shift || 0;
	my $result = "";

	if ($num<0)
	{
		$result = $ru_nominative{"-"};
		$num = -$num;
	}

	$result .= get_numeral(\%ru_nominative, $num, " ");
	# clean up extra padding
	$result =~ s/^ *//g;
	$result =~ s/  / /g;
	if ($want_new_rus == 1)
	{
		$result = old2new_simple($result);
	}
	return $result;
}

# return counting adjective prefix corresponding to an integer
sub counting_ru
{
	my $num = shift || 0;
	my $result = "";

	if ($num =~ /^([0-9]+)\'$/)	# special variant form
	{
		$result = $ru_counting{"$num"};
	} else
	{
		if ($num<0)
		{
			$result = $ru_counting{"-"};
			$num = -$num;
		}

		$result .= get_numeral(\%ru_counting, $num, "");
	}
	# clean up extra yer
# 	$result =~ s/�([^�Ţ��ʦ������\/A-Za-z0-9])/$1/g; # strict old orthography, not really supported
	$result =~ s/�([^Ţ�ʦ��\/A-Za-z0-9])/$1/g;
	return $result;
}

sub get_numeral
{
	my ($lang_data, $num, $padding) = (@_);
	my $result = "";
	my $order = 1;
	my $mod1000 = 0;
	my $threedigits = "";
	if ($num == 0)	# special case
	{
		$result = $$lang_data{"0"};
	}

	while($num > 0)
	{
		$mod1000 = $num % 1000;
		$num = $num / 1000;
		$threedigits = "";	# next portion
		# now we need to prepend the next portion to the list
		# e.g. $order=1000000, $mod1000 = 233: it means we have 233 million. So we prepend the number for "233" and the word "million" in the right case.
		$threedigits = get_under_1000($lang_data, $mod1000, (
			($order == 1000)
			? "fem"	# special: ���� ������, ��� ������, ���� ������
			: "masc"	# ����� ���̦���, ��� ���̦���, ���� ���̦�����
			), $padding)
				unless ($mod1000 == 1 and $num == 0 and $order > 1);	# don't say "����� ���̦���" but do say "�����"

		if ($order >= 1000 and $mod1000 > 0)	# don't say "������ ���̦���"
		{
			$threedigits .= $padding . $$lang_data{"$order" . crazy_index($mod1000)};
		}
		$result = $threedigits . $padding . $result;
		$order *= 1000;
	}
	return $result;
}

sub get_under_1000
{
	my ($lang_data, $num, $sex, $padding) = (@_);
	my $result = "";
	my $mod100 = ($num % 100);

	$num = 100 * ($num / 100);
	if ($num>0)
	{	# "���", "������" � �.�.
		$result .= $padding . $$lang_data{"$num"};
	}

	# sex is only significant if we have the last digit 1 or 2 and not teens
	# if we have teens, return right away
	if ($mod100 >= 10 and $mod100 <= 19)
	{
		$result .= $padding . $$lang_data{"$mod100"};
	}
	else	# have to print the decade first and then the single digit
	{
		$num = 10 * ($mod100 / 10);
		if ($num > 0) # if have decades
		{
			$result .= $padding . $$lang_data{"$num"};
		}

		$num = ($mod100 % 10);	# get last digit
		if($sex eq "fem" and ($num == 1 or $num == 2))
		{	# care about sex
			$sex = ":f";
		}
		else
		{
			$sex = "";
		}

		# print last digit
		if ($num > 0)	# if nonzero last digit
		{
			$result .= $padding . $$lang_data{"$num$sex"};
		}
	}
	return $result;
}

# parse the table and print the list of words with specified counting prefixes
sub expand_countable
{
	my ($line, $flags) = (@_);
	my ($word, $list, $have_range, $num, $prev_num, @real_list, $i);
	($word, @list) = split (" ", $line);
	$have_range = 0;
	$prev_num = 0;
	@real_list = ();
	# prepare the real list of indices
	foreach $num (@list)
	{
		if ($num eq "-")
		{
			$have_range = 1;
		} else
		{
			if ($have_range)
			{	# need to expand the range $prev_num to $num;
				# note: prev_num is already in the list @real_list
				for ($i=$prev_num+1; $i<=$num; $i++)
				{
					push (@real_list, $i);
				}
				$have_range = 0;
			} else
			{
				push(@real_list, $num);
			}
			$prev_num = $num;
		}
	}

	foreach $num (@real_list)
	{
		$word_and_flags = counting_ru($num) . $word . $flags;
		# remove the yer before some letters in the word
		$word_and_flags =~ s/�([^�Ţ��ʦ������\/A-Za-z0-9])/$1/g;
		$word_and_flags = old2new_simple($word_and_flags) if ($want_new_rus);
		print "$word_and_flags\n";
	}
}

# convert to new orthography, only simple words work
sub old2new_simple
{
	my $string = shift;
	$string =~ y/����/����/;
	$string =~ s/�$//g;
	$string =~ s/�([^ţ���\/A-Za-z0-9])/$1/g;
	return $string;
}

# main procedure

# parse options
$want_new_rus = ("@ARGV" =~ /-new/i) ? 1 : 0;
$dict_name = ("@ARGV" =~ /-dict=(.*)/) ? "$1" : "";
die "Error: dictionary file must be specified\n" if ($dict_name eq "");

# read dictionary
open (DICT, "$dict_name") || die "Error: cannot read dictionary file '$dict_name'\n";
$flag = "";
while(<DICT>)
{
	if (/^\s*$/ or m|^\s*#|)	# comment
	{
#		continue;
	}
	elsif (m|^\s*(/[^ ]*)$|)	# flag declaration
	{
		$flag = $1;
		chomp $flag;
	}
	elsif (/^[^ ]+\s*[-0-9'\s]+$/)	# word declaration
	{
		if ($flag eq "/")
		{
			$flag = "";
		}
		expand_countable($_, $flag);
	}
	else
	{
		print STDERR "Warning: malformed dictionary line:\n$_";
	}
}

# end of main procedure

