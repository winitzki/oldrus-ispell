#!/usr/bin/perl

# Script to help add new words to the dictionary if the new words are similar to already existing words

# Usage: $0 dictionary.koi < updatertext > newwordlist

# Format of the updater text: 
# word/FLAGS
#   this just adds a new word with given flags
# word/FLAGS - oldword
#	this will take the flags from oldword and add FLAGS to it, assign all flags to word


# Read dictionary into hash
sub read_dict {
	my $hash = shift;	# hash reference
	open(DICT, $ARGV[0]) || die "Error: Cannot read dictionary '$ARGV[0]'.\n";
	while(<DICT>) {
		chomp;
		if (m|^([^/ ]+)(/.*)?$| or m|^([^\#/ ]+)( #.*)?$|)
		{    # Word, maybe with flags or extra info
			$hash->{$1} = (defined($2)) ? $2 : "";
		}
		else
		{
			print STDERR "Error: dictionary file is garbled:\n$_\n";
		}
	}
}

# Script starts here

%dict = ();

read_dict(\%dict);

# Read updater file
while(<STDIN>)
{
	chomp;
	if (m|^([^/ ]+)(/[^ \t]*)?$|)
	{	# just one word
		print "$_\n";
	}
	elsif (m|^([^/ ]+)(/[^ \t]*)?\s*-\s*([^ \t/]*)$|)
	{	# word with a similar word
		$new_word = $1;
		if (defined($3))
		{
			$new_flag = $2;
			$old_word = $3;
		}
		else
		{
			$new_flag = "";
			$old_word = $2;
		}
		if (defined($dict{$new_word}))
		{
			print STDERR "Warning: word '$new_word' is already in the dictionary\n" ;
			print "$new_word$dict{$new_word}\n";
		}
		if (defined($dict{$old_word}))
		{	# found old word
			print $new_word . join("", sort split("", $new_flag . $dict{$old_word})) . "\n";
		}
		else
		{
			print STDERR "Warning: reference word '$old_word' not in dictionary\n";
			print "$new_word$new_flag\n";
		}
	}
}
