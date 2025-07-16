#!/bin/sh

# Update oldrus-ispell dictionaries using two distributions of rus-ispell
# Using files xxxx.diff if present
# Usage: update-dicts.sh rus-ispell-dir-old rus-ispell-dir-new

# Normal procedure for update: first, unpack the old distribution and the new distribution of rus-ispell into two directories. Then run update-dicts.sh on two directories. This will create *.koi.diff files. First, examine the affix file differences and fix them by hand. Then, examine these .diff files and see if any of them need editing by hand (look at each word and insert extra "yat'" and "fita" if needed). If so, edit them and move (dict).koi.diff to (dict).diff. If not, don't bother with the *.koi.diff files. Then run update-dicts.sh again with the same arguments. By running update-dicts.sh, new files (dict).koi.new are created. Examine all (dict).koi.rej files to see if any words were not excluded correctly; if so, fix those words by hand (they were not found probably because they were changed already in the old distribution of oldrus-ispell, in which case it's okay to ignore them; or because you didn't correct the yat' in the words to be removed, and the dictionary has them in different spelling; in this case, they have to be fixed by hand). Then move (dict).koi.new to (dict).koi and you are done. (After this, run mkflags SZPQYG on the base dictionary to add my flags; run make check_dup and make check_redundant.)

dir1="$1"
dir2="$2"

[ x"$dir1" = x ] && {
	echo Utility to update dictionaries.
	echo Usage: $0 rus-ispell-dir-old rus-ispell-dir-new
	exit 2
}

suff=koi

echo Updating dictionaries:
	# List all dictionaries here
for dict in abbrev base computer for_name geography rare science
do
	a=$dict.$suff
	echo -n "$a: "
	if [ -r $dict.diff ]
	then
		diff=$dict.diff
		echo "using special diff file '$diff'."
	else
		diff=$a.diff
		echo "no special diff file '$dict.diff' so creating '$diff'."
		diff $dir1/$a $dir2/$a | perl rus_new2old.pl | sed -e 's,^[^<>].*,,' > $diff
	fi
	grep '^<' $diff | cut -d ' ' -f 2 > $a.x
	grep '^>' $diff | cut -d ' ' -f 2 > $a.tmp
	perl excludelines.pl $a.x < $a >> $a.tmp 2> $a.rej
	cat $a.tmp | ./sortkoi8c | uniq > $a.new
	echo "Created and sorted '$a.new'"
	rm $a.tmp $a.x
done

aff=russian.aff.koi
echo Creating $aff.diff
diff $dir1/$aff $dir2/$aff > $aff.diff

echo All done.
