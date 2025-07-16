#!/bin/sh

# Transform dictionary from old to new orthography
# Usage: sh old2new.sh directory_name

SORT="./sortkoi8c"

newdir="$1"

rm -rf "$newdir"
mkdir -p "$newdir"

# Prepare lists of words to be added and removed. This list must be in new orthography with yo and short i.
# The first list consists of words that have 'ё' sound represented by '╒'. The old list after conversion will have them with "е" and we need to remove them
cat << EOF1 | tee base.add | grep 'ё' | sed -e 's/ё/е/g' > base.rem
безапелляционен
безапелляционность/F
безапелляционный/AEX
беззвёздный/A
вдёжка/I
вёшка/I
галерейка/I
галерейный/A
галерея/I
гнёзд
гнёзда/O
гнёздышек
гнёздышко/K
дозвёздный/A
запечатлённый/AS
засёдланный/AS
звёзд
звёздность/F
звёздный/AZ
звёздочка/I
звёзды/O
зёвывать/BL
издёвка/I
издёвочка/I
йог/K
йога/H
йоговский/A
йогурт/K
йод/J
йодирование/J
йодированный/AS
йодистый/A
йодный/A
йодоформ/J
йота/H
йотация/H
йотированный/A
квазизвёзд
квазизвёзды/O
кинозвёзд
кинозвёзды/O
краснозвёздный/A
лояльность/F
лояльный/AS
малоисследован
малоисследованный/AX
медвёдка/I
межзвёздный/A
надёванный/AX
надёвывать/BL
надзвёздный/A
неисследованный/A
неиссякаемость/F
неиссякаемый/A
некий/A
нелояльность/F
ненадёванный/AX
околозвёздный/A
осёдланный/AS
пересёдланный/AS
пересёдлывавший/A
пересёдлывать/LMP
позёвывавший/A
позёвывание/J
позёвывающий/A
пятизвёздочный/A
рассёдланный/AS
рассёдлывавший/A
рассёдлывать/BLMP
рассёдлываться/LS
рассёдлывающий/A
сверхзвёзд
сверхзвёзды/O
сёдел
сёдла/O
смётка/H
суперзвёзд
суперзвёзды/O
трёхзвёздочный/A
чересполосица/HQ
чересседельник/K
чересседельный/A
чересстрочный/A
чересчур
четырёхзвёздочный/A
шестизвёздочный/A
январский/A
EOF1

# Second list consists of words we want in both yo and ye variants (new orthography here!)
cat << EOF2 >> base.add
засёкший/A
осёкся/L
осёкший/A
осёкшийся/A
посёкся/L
посёкший/A
подсёкший/A
посёкшийся/A
отсёкший/A
чёрт/J
чёртик/K
чёртов/A
EOF2

# Third list consists of words we need to remove - list them in new orthography here, after rus_old2new.pl, but only words that rus_old2new cannot remove itself
cat << EOF3 >> base.rem
безаппелляционен
безаппелляционность/F
безаппелляционный/AEX
галлерейка/I
галлерейный/A
галлерея/I
иог/K
иога/H
иоговский/A
иогурт/K
иод/J
иодирование/J
иодированный/AS
иодистый/A
иодный/A
иодоформ/J
иота/H
иотация/H
иотированный/A
корридор/K
корридорный/A
лойяльность/F
лойяльный/AS
малоизследован
малоизследованный/AX
неизследованный/A
неизсякаемость/F
неизсякаемый/A
некая
некие
некими/G
некого
некое
некой
неком
некому
некою
некую
нелойяльность/F
однем
однеми
однех
переседланный/AS
пятизвездочный/A
трёхзвездочный/A
шестизвездочный/A
черезполосица/HQ
черезседельник/K
черезседельный/A
черезстрочный/A
черезчур
четырёхзвездочный/A
чорт/J
чортик/K
чортов/A
январьский/A
EOF3

# these words get mangled by rus_new2old.pl, need to fix them. This is in old orthography.
cat << EOF4 | tee geography.add | perl ./rus_old2new.pl > geography.rem
Сантьяго
Чикаго
EOF4

# replace the beginning "Йо" in some words. This is in new orthography.
cat << EOF41 >> geography.add
Йемен/J
Йена/H
Йокогама/H
Йорк/J
Йоркшир/J
Йоханнесбург/J
Йошкар
Чувашия/H
йеменский/A
йенский/A
йокогамский/A
йоркский/A
йоркширский/A
йоханнесбургский/A
EOF41

cat << EOF42 >> geography.rem
Иемен/J
Иена/H
Иокогама/H
Иорк/J
Иоркшир/J
Иоханнесбург/J
Иошкар
Чувашие/H
иеменский/A
иенский/A
иокогамский/A
иоркский/A
иоркширский/A
иоханнесбургский/A
EOF42

# same for science.koi
cat << EOF5 | tee science.add | grep 'ё' | sed -e 's/ё/е/g' > science.rem
протозвёзд
протозвёзды/O
EOF5


for dict in abbrev base church computer for_name geography names science rare redundant
do
	echo -n "$dict ... "
	touch $dict.add $dict.rem	# In case they don't exist
	perl ./rus_old2new.pl < $dict.koi | sh $SORT | uniq | perl ./excludelines.pl -quiet $dict.rem | cat - $dict.add | sh $SORT | uniq > "$newdir"/$dict.koi
	rm -f $dict.add $dict.rem
done
echo "done"

# special "counted.idx" dictionary
perl ./rus_old2new.pl < counted.idx > "$newdir"/counted.idx


# Make a full affix file for new orthography by 1) uncommenting lines that are NOYER-specific; 2) removing lines that are YER-specific and lines specific to old orthography; 3) removing YER from affix rules; 4) cleaning up affix rules that were corrupted after removing YER; removing empty lines; 5) convert rules and comments to new orthography, replacing certain words 

cat oldrussian.aff.koi | sed -e 's/^#noer//; s/^#nr//; s/^#r.*$//; s/^#o.*$//;' | perl -e 'while(<>){s/[Ъъ]([ \t.,\/\#])/\1/g;s/[Ъъ]$//; s/-,//;s/,\t/,-\t/; print unless(/^\s*$/);}' | sed -e 's/Е╡/Е/;y/╡╤╪╒╕╛/ЕИФеиф/;s/^\#o.*$$//;s/^\#r.*$//;s/АГО/ОГО/;s/ЯГО/ЕГО/;s/агося/огося/;s/аго /ого /;s/аго$/ого$/;s/ягося/егося/;s/яго /его /;s/яго$/его$/;s/ыя/ые/;' > "$newdir"/oldrussian.aff.koi

