#!/usr/bin/perl

# Update flags in a dictionary from another dictionary (updaterfile)
# (check that a word already exists and only replace flags in that case)
# "flags" can also include grammatical information.
# Usage: updateflags.pl updaterfile < dictfile > newdictfile 2> errors

open(UF, "$ARGV[0]") || die "Cannot open input file '$ARGV[0]'\nUsage: updateflags.pl updaterfile < dictfile > newdictfile 2> errors\n";

# Read the updater file
while(<UF>) {
	s/[\x0A\x0D]+$//;
	if (m|^([^/ ]+)(/.*)?$| or m|^([^\#/ ]+)( #.*)?$|) {	# Word, maybe with flags or extra info
		$updater{$1} = $2;
	} else {
		print STDERR "Error: updater file is garbled, line:\n$_\n";
	}
}

close(UF);

# Read the dictionary file and replace stuff in it
while(<STDIN>) {
	s/[\x0A\x0D]+$//;
	if (m|^([^/ ]+)(/.*)?$| or m|^([^\#/ ]+)( #.*)?$|) {	# Word, maybe with flags or extra info
		if (defined($updater{$1})) {
			print $1 . $updater{$1} . "\n";
			delete ($updater{$1});	# Remove from the list of words to be updated
		} else {
			print "$_\n";
		}
	} else {
		print STDERR "Error: dictionary file is garbled\n";
	}
}

# Now print words from the updater that weren't used
foreach $word (keys %updater) {
	print $word . $updater{$word} . "\n";
}
