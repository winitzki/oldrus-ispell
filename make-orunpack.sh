#!/bin/sh

# Prepare patch of AL's rus-ispell package against corresponding oldrus-ispell
# We look in the directory "$1" for sources
# Sample usage: make-orunpack.sh ./rus-ispell [-lowmem]

srcdir="$1"
lowmem="$2"

[ x"$DICTS" = x ] && \
	DICTS='abbrev base computer for_name geography science rare'

echo -n "Processing "

for dict in $DICTS
do
	cp $srcdir/$dict.koi old$dict.koi
done

# Exclude words that are in new dictionaries from base.koi
tmpexclude="excluded$$.tmp"
cat names.koi church.koi counted.koi > $tmpexclude
perl excludelines.pl $tmpexclude -quiet < $srcdir/base.koi > oldbase.koi
rm $tmpexclude

# The procedure is repeated for each dictionary independently
for dict in $DICTS
do
	echo -n "$dict ."
	# File names
	oradd=$dict.add
	orrem=$dict.rem
	perl esq -d < $oradd.esq | tee $oradd | perl rus_old2new.pl > $oradd.tmp
	perl esq -d < $orrem.rem.esq > $orrem.rem
	perl esq -d < $orrem.add.esq > $orrem.add
	sh dict-patch.sh $oradd.tmp $orrem $orrem -oldrus $lowmem
	echo -n "."
	sh dict-patch.sh old$dict.koi $dict.koi $dict -oldrus $lowmem
	rm old$dict.koi
	echo -n ". "
	# Clean up temporary files
	rm -f $oradd $oradd.tmp $orrem $orrem.add $orrem.rem
done
echo
