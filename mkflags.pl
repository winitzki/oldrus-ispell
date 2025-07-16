#!/usr/bin/perl -w

# Reads a dictionary and prints a modified dictionary with added flags and removed superfluous standalone forms
# words are removed only if they have no flags, unless prefix flags are requested, in which case words are removed when parent words have the same flags
# The list of possible flags is given as argument
# sample usage: perl mkflag.pl PQ [-v] < dictionary > newdictionary
# Note: the resulting dictionary is unsorted

# Supported flags: CDPQSTYZ
# S, Z - certain impersonal verb forms
# P, Q - instrumental case for nouns ending on sibilants
# C - prefix "za", D - negation prefix
# T - нести > неся
# Y - треплемъ > треплю, ... Warning: many false identifications with this flag!
# see known_flags below
# the -v option is for verbose operation

$verbose = (defined($ARGV[1]) and "$ARGV[1]" == "-v") ? 1 : 0;

%known_flags = (
# 'Flag' => [ 'pre|post', [ [ parentregex, regex, replace, guard_flag], ... ] ]
# [ regex, replace, guard_flag] is the array of "rules" for a given flag
# the regex/replace should produce a prospective parent word from a given word.
# the word will be removed unless its prospective parent word is not in dictionary or has guard_flag or does not match parentregex
# any number of 'rules' can be given
	'C' => [ 'prefix', [
		['.*', 'за(.*)', '', 'D'],
	]],
	'D' => [ 'prefix', [
		['.*', 'не(.*)', '', 'C'],
	]],
	'P' => [ 'postfix', [
		['.*[жцчшщ]ъ', '(.*[жцчшщ])омъ', 'ъ', ''],
	]],
	'Q' => [ 'postfix', [
		['.*[жцчшщ]ъ', '(.*[жцчшщ])е[вм]ъ', 'ъ', ''],
		['.*ецъ', '(.*)ьце[вм]ъ', 'ецъ', ''],
		['.*ецъ', '(.*[^аеиоуыьэюя])це[вм]ъ', 'ецъ', ''],
		['.*ца', '(.*)цей', 'ца', ''],
	]],
	'S' => [ 'postfix', [
		['.*ться', '(.*)[еюя]тся', 'ться', ''],
		['.*иться', '(.*)[ия]тся', 'иться', ''],
		['.*ть', '(.*)[еюя]тъ', 'ть', ''],
		['.ить', '(.*)[ия]тъ', 'ить', ''],
	]],
	'Z' => [ 'postfix', [
		['.*оваться', '(.*)у[ею]тся', 'оваться', 'S'],
		['.*овать', '(.*)у[ею]тъ', 'овать', 'S'],
	]],
	'T' => [ 'postfix', [
		['.*сти', '(.*)ся', 'сти', ''],
		['.*скать', '(.*)щ[аи]', 'скать', ''],
		['.*скать', '(.*)щите', 'скать', ''],
		['.*стись', '(.*)сясь', 'стись', ''],
		['.*скаться', '(.*)щ[аи]сь', 'скаться', ''],
		['.*скаться', '(.*)щитесь', 'скаться', ''],
	]],
	'Y' => [ 'postfix', [
		['.*ёмъ', '(.*)[ую]', 'ёмъ', ''],
		['.*ёмъ', '(.*)ёшь', 'ёмъ', ''],
		['.*ёмъ', '(.*)ётъ', 'ёмъ', ''],
		['.*ёмъ', '(.*)ёте', 'ёмъ', ''],
		['.*ёмъ', '(.*)[ую]тъ', 'ёмъ', ''],
		['.*емъ', '(.*)[ую]', 'емъ', ''],
		['.*емъ', '(.*)ешь', 'емъ', ''],
		['.*емъ', '(.*)етъ', 'емъ', ''],
		['.*емъ', '(.*)ете', 'емъ', ''],
		['.*емъ', '(.*)[ую]тъ', 'емъ', ''],
		['.*ёмся', '(.*)[ую]', 'ёмся', ''],
		['.*ёмся', '(.*)ёшь', 'ёмся', ''],
		['.*ёмся', '(.*)ётся', 'ёмся', ''],
		['.*ёмся', '(.*)ёте', 'ёмся', ''],
		['.*ёмся', '(.*)[ую]тся', 'ёмся', ''],
		['.*емся', '(.*)[ую]', 'емся', ''],
		['.*емся', '(.*)ешь', 'емся', ''],
		['.*емся', '(.*)ется', 'емся', ''],
		['.*емся', '(.*)ете', 'емся', ''],
		['.*емся', '(.*)[ую]тся', 'емся', ''],
	]],
);

$given_flags = $ARGV[0];

if (not defined($given_flags) or $given_flags eq "" or not $given_flags =~ /^[A-Z]+$/) {
	die "Usage: mkflags.pl FLAGS < dict1 > dict2\n";
}

@flags = ();
# make an array of requested @flags
	map {push(@flags, $_) if (defined($known_flags{$_})); } split (//, $given_flags);

# Read dictionary into hash of hash references
# We need this structure to allow for repeated words with different flags
while(<STDIN>) {
	chomp;
	$word = "";
	if (/^(.+)(\/.*)$/) {
		$word = $1;
		$flags = $2;	# Word with flags
	} elsif (/^([^\/]+)$/) {
		$word = $1;
		$flags = "";	# Word with no flags
	}
	next if ($word eq "");
	$dict{$word}->{$flags} = 1;
}

# Result: $dict{'word'} is a hash of flags with values 1. Value 0 or empty value are special. Test for word presence in dictionary must be (defined($dict{$word}->{$flag}) and $dict{$word}->{$flag} == 1)

close STDIN;

foreach $word (keys %dict) {
	# Find out whether the word needs to be deleted
	# all flags need to be checked
	$done = 0;	# global flag to exit all loops
	foreach $flag (@flags) {
		if ($known_flags{$flag}->[0] eq 'postfix') {
			# Looking for standalone forms with no flags
			next unless (&dict_has_word_flag(\%dict, $word, ""));
		} #else {	# prefix flags may be combined, will check later
		#}

		# Only one rule may be effective but several may match a word
		foreach $rule (@{$known_flags{$flag}->[1]}) {
			($parentregex, $regex, $affix, $guard_flag) = @$rule;
			if ($word =~ /^$regex$/) {
				# make parent word
				$parent = $1;
				if ($known_flags{$flag}->[0] eq 'prefix') {
					$parent = $affix . $parent;
				} else {
					$parent .= $affix;
				}
				next if (not ($parent =~ /^$parentregex$/) or not &dict_has_word(\%dict, $parent));	# try next rule

				# $parent is in dictionary, so check whether $word can be removed
				# use different procedures for prefix and postfix flags
				if ($known_flags{$flag}->[0] eq 'prefix') {
					# prefix flags: find instance of parent word with identical flags
					foreach $p_flag (keys %{$dict{$word}}) {
						if (not $p_flag =~ /$guard_flag/ and &dict_has_word_flag(\%dict, $parent, $p_flag)) {
							&dict_add_flag(\%dict, $parent, $p_flag, $flag);
							&dict_delete_word_flag(\%dict, $word, $p_flag);
							$done = 1;
							last;
						}
					}	# foreach $p_flag
				} else {
					# add $flag to the first matching instance of the parent word that doesn't have $guard_flag and delete word since have only one instance of it (empty flags only)
					foreach $p_flag (keys %{$dict{$parent}}) {
						if (not $p_flag =~ /$guard_flag/) {
							&dict_add_flag(\%dict, $parent, $p_flag, $flag);
							&dict_delete_word(\%dict, $word);
							$done = 1;
							last;
						}
					}	# foreach $p_flag
				}	# if 'prefix'
				last if ($done);
			}	# if $word matches $regex
		}	# foreach $rule
		last if ($done);	# only one flag may be effective
	}	# foreach $flag
}	# foreach $word

# print everything
foreach $word (keys %dict) {
	foreach $flag (keys %{$dict{$word}}) {
		print "$word$flag\n" if &dict_has_word_flag(\%dict, $word, $flag);
	}
}

# service routines
sub dict_add_flag {	# $flag will be merged with $word/$oldflag
	my ($dict, $word, $oldflag, $flag) = @_;
	my ($newflag) = ($oldflag);
	if (not $oldflag =~ /$flag/) {	# Don't add twice
		delete $dict->{$word}->{$oldflag};
		$newflag = "/" if ($newflag eq "");	# Replace empty flag by flag separator
		my @flags = sort (split(//, $flag . $newflag));
		$newflag = join("", @flags);
		$dict->{$word}->{$newflag} = 1;
		print STDERR "Added flag $flag to word $word$newflag\n" if ($verbose);
	}
}

sub dict_delete_word {
	my ($dict, $word) = @_;
	delete $dict->{$word} if (defined($dict->{$word}));
	print STDERR "Deleted word $word\n" if ($verbose);
}

sub dict_delete_word_flag {
	my ($dict, $word, $flag) = @_;
	delete $dict->{$word}->{$flag} if (defined($dict->{$word}->{$flag}));
}

sub dict_has_word {	# test for word presence
	my ($dict, $word) = @_;
	return (defined($dict->{$word}));
}

sub dict_has_word_flag {	# (\%dict, $word, $flags)
	# returns boolean, whether the dictionary contains the given word with *exactly* given flags. Example: $flags='LM'. If the $flags argument is empty, test for word with empty flags.
	my ($dict, $word, $flags) = @_;
	return (defined($dict->{$word}->{$flags}) and $dict->{$word}->{$flags} == 1);
}
