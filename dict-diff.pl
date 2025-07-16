#!/usr/bin/perl

# Find differences between ispell dictionaries
# Usage: dict-diff.pl targetdict < srcdict > add_remove_list 2> flags_list
# Creates add_list and remove_list streams such that srcdict becomes targetdict up to flags after removing remove_list lines and adding add_list lines
# add_remove_list consists of lines prefixed by + or - for add and remove
# flags_list consists of empty lines where flags are unchanged, "/" where a flag is to be removed, and flag lines where flags have to be replaced.
# both dictionaries have to be sorted

%excl = ();

$verbose = ("@ARGV" =~ /-verbose/) ? 1 : 0;

if ($#ARGV < 0) {
	print STDERR "Usage: dict-diff.pl targetdict < srcdict > add_remove_list 2> flags_list";
	exit;
}

while(<STDIN>) {
	s/[\x0A\x0D]+$//;
	m|^([^ \t/]+)([ \t/].*)?$|;
	$word = $1;
	$flags = $2;
	print STDERR "Warning: duplicate word '$word$flags' in source dictionary\n" if ($verbose and defined($excl{$word}->{$flags}));
	$excl{$word}->{$flags} = 1;	# >0 means have this in srcdict but not yet found in targetdict, 0 means have in targetdict and in srcdict, <0 means have in targetdict but not in srcdict.
}
close(STDIN);

open(DICT, "$ARGV[0]") || die "Error: cannot open file '$ARGV[0]'\n";
$word = "";
while(<DICT>) {
	s/[\x0A\x0D]+$//;
	m|^([^ \t/]+)([ \t/].*)?$|;
	if ($word ne $1 and defined($excl{$1})) {	# new word
		$srcwords = keys %{$excl{$1}};	# find # of srcwords
	}
	$word = $1;
	$flags = $2;
	$pflags = $flags;	# flags to be printed
	$pflags = "/" if ($flags eq "");
	if(defined($excl{$word})) {	# word found
		if (defined($excl{$word}->{$flags})) {	# flags found
			if ($excl{$word}->{$flags} > 0) {	# exact match
				$excl{$word}->{$flags} = 0;	# mark as found
				$pflags = "" if ($srcwords == 1);
			} else {
				print STDERR "Warning: duplicate word '$word$flags' in target dictionary\n" if ($verbose);
			}
		} else {	# flags not found but word exists
			$excl{$word}->{$flags} = -1;
		}
	} else {	# word not found
		$excl{$word}->{$flags} = -1;
		$pflags = "";
	}
	# Print flags
	print STDERR "$pflags\n";
}
close(DICT);
close(STDERR);
# Now we compile the add/remove list
# All words marked by positive number are to be removed, by negative to be added, and we minimize the add/remove list
foreach $word (keys %excl) {
	$have=0;
	@flags = (keys %{$excl{$word}});
	foreach $flag (@flags) {
		if ($excl{$word}->{$flag} > 0) {
			++$have;
		} elsif ($excl{$word}->{$flag} < 0) {
			--$have;
		}
	}
	if ($have > 0) {
		foreach $flag (@flags) {
			if ($excl{$word}->{$flag} > 0) {
				print "-$word$flag\n";
				--$have;
			}
			last if ($have == 0);
		}
	} elsif ($have < 0) {
		foreach $flag (@flags) {
			if ($excl{$word}->{$flag} < 0) {
				print "+$word$flag\n";
				++$have;
			}
			last if ($have == 0);
		}
	}
}
