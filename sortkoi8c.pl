#!/usr/bin/perl
# Sort STDIN in Cyrillic koi8-c encoding alphabetically. Take care of old Russian letters and hard signs at word ends.
#
# -nocase	Fold lower case characters into the equivalent upper case
# -with-yer	Sort ending hard sign specially

undef $/;

$fold = ("@ARGV" =~ /-nocase/) ? 1 : 0;	 # Default not to fold case
$do_yer = ("@ARGV" =~ /-with-yer/) ? 1 : 0;	# Default not to deal with "yer"

print join("\n", sort
	sortsub
	(split(/\n/,<STDIN>)));

print "\n";	# The last newline is swallowed above

sub sortsub
{
# $a and $b are two strings that need to be compared. Need to return -1, 0, or 1. Note that $a and $b are references and we shouldn't modify them!
# 1. Fold old Russian letters: yat', fita, izhitsa, i roman
# 2. Treat "yer" (hard sign) at end of word (i.e. before a non-Russian char) as empty string (option "-with-yer")
	$aa = $a; $bb = $b;
	if ($do_yer) {
		$aa =~ s/�([^�����������-�]*)$/\1/;
		$bb =~ s/�([^�����������-�]*)$/\1/;
	}
	if ($fold) {
		$aa =~ tr/������-�/������-�/;
		$bb =~ tr/������-�/������-�/;
	}
	$aa =~ tr/�����岳��鶱����������������������������Ţ���ɦ������������Ƭ�����������/��������������������������������������������������������������������������/;
	$bb =~ tr/�����岳��鶱����������������������������Ţ���ɦ������������Ƭ�����������/��������������������������������������������������������������������������/;
	# $aa and $bb don't fold old Russian letters into new ones
	$aaa = $aa; $bbb = $bb;
	$aaa =~ tr/��������/��������/;
	$bbb =~ tr/��������/��������/;
	# $aaa and $bbb fold them. So now we want to do a "weak sorting" of them.
	($aaa eq $bbb) ? ($aa cmp $bb) : ($aaa cmp $bbb);
}
