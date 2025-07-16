#!/bin/sh

[ x"$3" = x ] && {
	echo "`basename $0`: compare two dictionaries and make a patch"
	echo "Usage: `basename $0` srcdict targetdict name [-oldrus] [-lowmem]"
	echo "Makes files 'name.flags', 'name.add', 'name.rem'"
	exit
}

srcdict="$1"
targetdict="$2"
SORT="sh ./sortkoi8c"

tmpra="$3".tmpra
add="$3".add
rem="$3".rem
flags="$3".flags
if [ x"$4" = x-oldrus ]
then
	shift
	if [ x"$4" = x-lowmem ]
	then
		bylines=-bylines
		dictdiff=dict-diff-lowmem.pl
	else
		bylines=""
		dictdiff=dict-diff.pl
	fi
	cat "$srcdict" | perl rus_new2old.pl -nocaps $bylines | $SORT | uniq | perl $dictdiff "$targetdict" > "$tmpra" 2> "$flags"
else
	if [ x"$4" = x-lowmem ]
	then
		bylines=-bylines
		dictdiff=dict-diff-lowmem.pl
	else
		bylines=""
		dictdiff=dict-diff.pl
	fi
	cat "$srcdict" | perl $dictdiff "$targetdict" > "$tmpra" 2> "$flags"
fi
grep "^+" < "$tmpra" | sed -e 's/^+//' | $SORT > "$add"
grep "^-" < "$tmpra" | sed -e 's/^-//' | $SORT > "$rem"
rm "$tmpra"
