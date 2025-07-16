#!/bin/sh

[ x"$3" = x ] && {
	echo "`basename $0`: apply a patch to a dictionary"
	echo "Usage: `basename $0` srcdict targetdict name [-oldrus] [-lowmem]"
	echo "Makes targetdict using srcdict and files 'name.flags', 'name.add', 'name.rem'"
	exit
}

srcdict="$1"
targetdict="$2"
SORT=./sortkoi8c

add="$3".add
rem="$3".rem
flags="$3".flags

if [ x"$4" = x-oldrus ]
then
	shift
	if [ x"$4" = x-lowmem ]
	then
		bylines=-bylines
	else
		bylines=""
	fi
	cat "$srcdict" | perl rus_new2old.pl -nocaps $bylines | $SORT | uniq | perl excludelines.pl "$rem" -quiet | cat - "$add" | $SORT | perl applyflags.pl "$flags" > "$targetdict"
else
	cat "$srcdict" | perl excludelines.pl "$rem" -quiet | cat - "$add" | $SORT | perl applyflags.pl "$flags" > "$targetdict"
fi
