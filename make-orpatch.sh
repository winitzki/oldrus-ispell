#!/bin/sh

# Prepare patch of AL's rus-ispell package against corresponding oldrus-ispell
# We look in the directory "$1" for rus-ispell sources and in current directory for oldrus-ispell sources
# Prepare all files in given directory "$2"
# Sample usage: make-orpatch.sh ./rus-ispell-orig ./oldrus-ispell-0.99d8p9 [-lowmem]

srcdir="$1"
distdir="$2"
lowmem="$3"
dictionaries='abbrev base for_name computer geography science rare'

# Copy sources to temporary location for pre-compression processing
for dict in $dictionaries
do
	cp $srcdir/$dict.koi $distdir/old$dict.koi
done

# Exclude words that are in new dictionaries from base.koi
tmpexclude="excluded$$.tmp"
cat names.koi church.koi counted.koi > $tmpexclude
perl excludelines.pl $tmpexclude -quiet < $srcdir/base.koi > $distdir/oldbase.koi
rm $tmpexclude

echo -n "Processing "
# The procedure is repeated for each dictionary independently
for dict in $dictionaries
do
	echo -n "'$dict' ."
	# File names
	oradd=$dict.add
	orrem=$dict.rem
	sh dict-diff.sh $distdir/old$dict.koi $dict.koi $dict -oldrus $lowmem
	rm $distdir/old$dict.koi
	echo -n "."
	# Made add/remove files
	# Now $oradd contains old orthography words (with flags) to be added to the converted dictionary and $orrem contains the same reconverted to old orthography
	# We use the fact that the difference between $oradd and $orrem comes from transition to old orthography, i.e. most of the differing words are really incorrectly converted from new to old orthography and are already present in $oradd, so we'll compare these files after double conversion
	cat $oradd | perl rus_old2new.pl > $oradd.tmp
	sh dict-diff.sh $oradd.tmp $orrem $orrem -oldrus $lowmem
	echo -n ". "
	perl esq < $oradd > $distdir/$oradd.esq
	perl esq < $orrem.add > $distdir/$orrem.add.esq
	perl esq < $orrem.rem > $distdir/$orrem.rem.esq
	mv $dict.flags $orrem.flags $distdir
	# Clean up temporary files
	rm -f $oradd $oradd.tmp $orrem $orrem.add $orrem.rem
done
echo
echo done.
