#!/usr/bin/perl

use strict;

# reimplementation of dict-diff.pl, 2x slower but needs much less memory (e.g. 2MB instead of 36MB on base.koi)
# Find differences between ispell dictionaries
# Usage: dict-diff.pl targetdict < srcdict > add_remove_list 2> flags_list
# Creates add_remove_list and flags_streams such that srcdict becomes targetdict after 1) removing all lines mentioned in remove list and adding all lines in add list, 2) in the resulting dictionary, flags are to be replaced according to the flag_list
# add_remove_list consists of lines prefixed by + or - for add and remove
# flags_list consists of empty lines indicating that flags are unchanged, "/" where a flag is to be removed, and flag lines where flags have to be replaced.
# both initial dictionaries have to be sorted using sortkoi8c and case-sensitive option

# use "merge" sort algorithm; comparison of empty word with non-empty word are done as if the empty word is lexically greater than any non-empty word; keep flags for identical words in arrays
# the read routine returns the next flag array (which may be empty if we have reached end of file) as well as the next word
# flag output should be optimized, but be careful: the order of flags may prevent aggressive optimization, e.g. {A,B,C} -> {C, D, E} may simply give the {C, D, E} output instead of a more optimized but unsorted and difficult to generate {D, E, }

sub wordset_init {
	my ($self, $FH) = (@_);
	$self->{'nextline'} = "";	# word with flags
	$self->{'word'} = "";	# word without flags
	$self->{'flags'} = ["", "", "", "", "", "", "", ""];	# array of flags; preallocate 8 items
	$self->{'FH'} = $FH;	# filehandle ref
	$self->{'eof'} = 0;	# EOF status
	$self->{'count'} = 0;	# array size

	if ($_ = <$FH>) {	# read something
		chomp;
		$self->{'nextline'} = $_;
	} else {	# EOF now (empty file)
		wordset_set_eof_pending($self);
		wordset_set_eof_real($self);
	}
}

sub wordset_set_eof_pending {	 # set EOF status pending
	my ($self) = (@_);
	delete $self->{'nextline'};
}

sub wordset_set_eof_real {	 # set real EOF status
	my ($self) = (@_);
	delete $self->{'word'};
	$self->{'count'} = 0;
	$self->{'eof'} = 1;
}

sub wordset_read {	# Read next set of word(s); previous one has been read; on EOF, set EOF status
	my $self = shift;
	my $FH = $self->{'FH'};
	my ($flags, $nextword);
	if (defined($self->{'nextline'})) {	# no EOF pending yet
		# assume that we have read the next line on the previous run
		$self->{'nextline'} =~ m|^([^ \t/]+)([ \t/].*)?$|;
		$self->{'word'} = $nextword = $1;
		$flags = $2 || "";
		$self->{'count'} = 0;	# clear array
		# keep reading until we encounter an EOF or a different word
		while ($self->{'word'} eq $nextword) {
			$self->{'flags'}->[$self->{'count'}++] = $flags;	# store flags
			if ($_ = <$FH>) {	# try reading more
				chomp;
				$self->{'nextline'} = $_;
				m|^([^ \t/]+)([ \t/].*)?$|;
				$nextword = $1;
				$flags = $2 || "";
			} else {	# EOF now pending
				wordset_set_eof_pending($self);
				$nextword = "";
			}
		}
	} else {	# EOF already
		wordset_set_eof_real($self);
	}
}

sub wordset_count {	# Give count of flags
	my ($self) = (@_);
	return $self->{'count'};
}

sub wordset_print {	# Print all words from a wordset and prefix them; return count; if $limit is given, print only $limit first words
	my ($self, $prefix, $limit) = (@_);
	return if ($self->{'eof'});
	$limit = wordset_count($self) if (not defined($limit));
	my $i;
	for ($i = 0; $i < $limit; ++$i) {
		print $prefix, $self->{'word'}, $self->{'flags'}->[$i], "\n";
	}
}	

sub wordset_print_flags {	# Print all flags from a wordset to STDERR
	my $self = shift;
	return if ($self->{'eof'});
	my $limit = wordset_count($self);
	my ($i, $flags);
	for ($i = 0; $i < $limit; ++$i) {
		$flags = $self->{'flags'}->[$i];
		$flags = "/" if ($flags eq "");
		print STDERR $flags, "\n";
	}
}	

sub koi8c_compare {	# returns -1, 0 or 1 according to whether w1 <=> w2
# note that undef is larger than anything
	my ($w1, $w2) = (@_);
	return 1 if (not defined($w1));
	return -1 if (not defined($w2));
	return 0 if ($w1 eq $w2);
	return (koi8c_sort($w1) cmp koi8c_sort($w2));
}

sub koi8c_sort {	# returns word recoded to aid sorting; assume case-sensitive sort
	my ($word) = shift;
	$word =~ tr/áâ÷çäå²³öúé¶±êëìíîïğòóôõæ¼èãşûıÿùøüàñÁÂ×ÇÄÅ¢£ÖÚÉ¦¡ÊËÌÍÎÏĞÒÓÔÕÆ¬ÈÃŞÛİßÙØÜÀÑ/¡¢£¦¬±²³¶¼ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäåæçèéêëìíîïğñòóôõö÷øùúûüışÿ/;
	return $word;
}

my (%wordset_src, %wordset_dest);

wordset_init(\%wordset_src, \*STDIN);

	# print "Debugging:\n"; while (not $wordset_src{'eof'}) { wordset_read(\%wordset_src); print "$wordset_src{'word'}: '", join("', '", @{$wordset_src{'flags'}}), "'\n"; wordset_print(\%wordset_src, ":"); }

open(DICT, "$ARGV[0]") || die "Error: cannot open file '$ARGV[0]'\n";
wordset_init(\%wordset_dest, \*DICT);

my ($cmpstatus, $countdest, $countsrc, $i, $flags);

# Read both the first time
wordset_read(\%wordset_src);
wordset_read(\%wordset_dest);
# main loop
while (not $wordset_src{'eof'} or not $wordset_dest{'eof'}) {
	$cmpstatus = koi8c_compare($wordset_src{'word'}, $wordset_dest{'word'});
	if ($cmpstatus == 0) {	# two wordsets with identical words, need to sort out flags; if flags are identical, do nothing, otherwise print the full set of flags
		$countdest = wordset_count(\%wordset_dest);
		$countsrc = wordset_count(\%wordset_src);
		if ($countdest == $countsrc) {
			for ($i = 0; $i < $countdest; ++$i) {
				$flags = $wordset_dest{'flags'}->[$i];
				if ($flags eq $wordset_src{'flags'}->[$i]) {
					$flags = "";
				} elsif ($flags eq "") {
					$flags = "/";
				}
				print STDERR "$flags\n";
			}
		} elsif ($countdest > $countsrc) {
			wordset_print(\%wordset_dest, "+", $countdest - $countsrc);
			wordset_print_flags(\%wordset_dest);
		} elsif ($countdest < $countsrc) {
			wordset_print(\%wordset_src, "-", $countsrc - $countdest);
			wordset_print_flags(\%wordset_dest);
		} else {	#
			print STDERR "Internal error 1\n";
		}
		wordset_read(\%wordset_src);
		wordset_read(\%wordset_dest);
	} elsif ($cmpstatus == 1) {	# src > dest
		$countdest = wordset_count(\%wordset_dest);
		wordset_print(\%wordset_dest, "+", $countdest);
		print STDERR "\n" x $countdest;	# skip flags
		wordset_read(\%wordset_dest);
	} else {	# src < dest
		wordset_print(\%wordset_src, "-");
		wordset_read(\%wordset_src);
	}
}
