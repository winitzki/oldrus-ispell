#!/usr/bin/perl

# Insert some old Russian orthography where it is trivial to do so.
# Version of Sept. 4, 2000
# Flags: -nocaps	disable modification of capitalized letters altogether
# -allcaps	modify all caps just as lowercase and insert capital er
# both -allcaps and -nocaps result in adding uppercase Er to uppercase prepositions only but not to other uppercase words
# default is to only add lowercase Er after "V", "K", "S" and not touch any other uppercase trailing consonants assuming that they are abbreviations
# -bylines: do not swallow all input but process it line by line and print results

# Parse options
$allcaps = ("@ARGV" =~ /-allcaps/) ? 1 : 0;
$nocaps = ("@ARGV" =~ /-nocaps/) ? 1 : 0;
$Er = ($allcaps) ? "Ъ" : "ъ";
$RL = ("@ARGV" =~ /-RL/i) ? 1 : 0;

$wb='[^A-z0-9Ю-Ъю-ъ╡╒╤╕╪╛Ёё╠║]';
$letter='[Ю-Ъю-ъ╡╒╤╕╪╛Ёё╠║]';

undef $/ unless ("@ARGV" =~ /-bylines/);

while(<STDIN>) {
# Insert hard signs and roman i's automatically.
	# Hard signs at end of words
	s/([бвгджзклмнпрстфхцчшщ╛])([^ёЁю-ъЮ-Ъ╛╪╒╡╠║╕╤])/$1ъ$2/g;
	s/([БВГДЖЗКЛМНПРСТФХЦЧШЩ╪])([^ёЁю-ъЮ-Ъ╛╪╒╡╠║╕╤])/$1Ъ$2/g if ($allcaps and not $nocaps);	# This allows modification of capitalized words (but danger to things like СССР which become СССРЪ)
	s/($wb)([ВКС])([^ёЁю-ъЮ-Ъ╛╪╒╡╠║╕╤."!?])/$1$2$Er$3/g if ($allcaps or not $nocaps);	# Prepositions may be capitalized
	s/^([ВКС])([^ёЁю-ъЮ-Ъ╛╪╒╡╠║╕╤."!?])/$1$Er$2/g if ($allcaps or not $nocaps);	# Prepositions may be capitalized but not followed by some punctuation
	# Roman i (╤╕)
	s/и([аеёийоуыэюяАЕЁИЙОУЫЭЮЯ╠║])/╕$1/g;
	s/И([аеёийоуыэюяАЕЁИЙОУЫЭЮЯ╠║])/╤$1/g;
	# Do not replace и in composite words with пяти- шести- семи- восьми-  девяти- десяти- -дцати-
	s/^([Пп]ят)╕/$1и/g;
	s/^([Шш]ест)╕/$1и/g;
	s/^([Сс]ем)╕(?=[уэ])/$1и/g;	# сем╕отика, но семиугольный, семиэтажный
	s/^([Вв]осьм)╕/$1и/g;
	s/^([Дд]е[вс]ят)╕/$1и/g;
	s/($wb)([Пп]ят)╕/$1$2и/g;
	s/($wb)([Шш]ест)╕/$1$2и/g;
	s/($wb)([Сс]ем)╕(?=[уэ])/$1$2и/g;	# сем╕отика, но семиугольный, семиэтажный
	s/($wb)([Вв]осьм)╕/$1$2и/g;
	s/($wb)([Дд]е[вс]ят)╕/$1$2и/g;
	s/(дцат)╕/$1и/g;
	# Prefixes без-, воз-, из-, раз-, роз-
	s/([Бб]е)с(?=[псфхцчшщ])/\1з/g;
	s/($wb)([Оо]?[Бб]е)с(?=(к[^а]|ка[$letter]|т[^╕с]))/\1\2з/g;	# Avoid арабеска, бест╕я, бестселлер
	s/^([Оо]?[Бб]е)с(?=(к[^а]|ка[$letter]|т[^╕с]))/\1з/g;
	s/([^БбТт])([Рр][ао])з(?=[с])/\1\2з/g;     # раз-(с), роз-(с). Avoid брасс, трасса
	s/^([Рр][ао])з(?=[с])/\1з/g; 
	s/([Вв]о)с(?=[с])/\1з/g;        # воз-(с)
	s/($wb)([Ии])с(?=[с])/\1\2з/g;  # ^из-(с)
	s/^([Ии])с(?=[с])/\1з/g;  # ^из-(с)

	# Replace some obsolete word spellings
	s/есурс/ессурс/g;	# рессурс
	s/офиц╕/оффиц╕/g;	# оффиц╕альный
	s/ксплуат/ксплоат/g;	# эксплоатац╕я
	s/([Аа])(плоди)(р[оу]|сме)/\1п\2\3/g;	# апплодировать

	# Replace ф by ╛ where it's unambiguous
	s/([Рр]и)ф([м])/\1╛\2/g;  # ри╛ма, логари╛м

	# Replace е by ╒ where it's unambiguous
	s/([ЦцСс]в)е([тчщ])/\1╒\2/g;  # цв╒т, св╒т, цв╒ч, св╒ч, св╒щ
	s/([^гкмлрчП])е(ть)/\1╒\2/g;  # most verbs on -╒ть
	s/([^о]м)е(ть)/\1╒\2/g;  # most verbs on -м╒ть (except опрометью)
	s/([^ет]р|${letter}тр)е(ть$|ть[^я])/\1╒\2/g;  # most verbs on -р╒ть (except мереть, тереть, переть) avoid полтретьяго
	s/([^Пп]л|${letter}пл)е(ть)/\1╒\2/g;  # most verbs on -л╒ть (avoid плеть)
	s/([^гкч])е([вй]ш)/\1╒\2/g;  # -╒вш╕й
	s/([^гклр]|[^бк]л|$letter[^б]р)е(ющ)/\1╒\2/g;  # -╒ющ╕й, но реющ╕й, бреющ╕й, клеющ╕й...
	s/^е(вш)/╒\1/g;  # ╒вши
	s/([ЗзСсУуИи]м)е(ть|[еёюя])/\1╒\2/g;  # зм╒я, см╒ю, ум╒ю, им╒ть, ...
	s/([Зз]м)е(й)/\1╒\2/g;  # зм╒й
	s/([Сс]ов|тв)е(т)/\1╒\2/g;  # отв╒тъ, сов╒тъ, ...
	s/([Оо]бр)е(т[аеёушья])/\1╒\2/g;  # обр╒т- ...
	s/([^яе]|$wb)бе(д[ин])/\1б╒\2/g;  # поб╒дный, ...
	s/^(б)е(д[ин])/\1╒\2/g;  # б╒дный, ...
	s/(з|по|с)не(ж)/\1н╒\2/g;  # сн╒жный
	s/([зс]р)е(ж[^и])/\1╒\2/g;  # ср╒жь, но не "срежиссировать"
	s/(Цц)е(л[аёкуъы]|льн|о[^в])/\1╒\2/g;  # ц╒лая, ...
	s/([аеоу]с)е(д)/\1╒\2/g;  # бес╒да, ...
	s/([Ссд]д)е([тл])(?=[^и])/\1╒\2/g;  # подд╒лка
	s/([Чч]елов)е([кч])/\1╒\2/g;  # челов╒къ, ...
	s/([Зз]в|[Гг]н)[её](зд)/\1╒\2/g;  # зв╒зда, гн╒здо, ...
	s/([Цц])е(п[илнь])/\1╒\2/g;  # ц╒пь, ц╒плять, зац╒пилъ, ...
	s/([Дд])е(ят)/\1╒\2/g;	# д╒ятель
	s/(([^у]|$wb)[Дд])е(йств)/\1╒\3/g;	# д╒йствовать, но ╕удейство, судейство
	s/^([Дд])е(йств)/\1╒\2/g;	# д╒йствовать, но ╕удейство, судейство
	s/(о)е(д[ъа])/\1╒\2/g;	# огло╒дъ
	s/([Цц])е(н[ня])/\1╒\2/g;	# ц╒нный
	s/([Гг]р)е([хш])/\1╒\2/g;	# гр╒х-, гр╒ш-
	s/([Вв])е(ш[^екн])/\1╒\2/g;	# в╒ш - кром╒ вешн, вешк, веше
	s/([Цц])е(ж[еёи])/\1╒\2/g;	# -ц╒ж-

	# Russkaja Latinica stuff: Replace f~ by fita, ~v by izhitsa, i~ by i roman, and e~ by yat'.
	if ($RL) {
		s/Ф~/╪/g;
		s/ф~/╛/g;
		s/~V/╠/g;
		s/~v/║/g;
		s/Е~/╡/g;
		s/е~/╒/g;
		s/И~/╤/g;
		s/и~/╕/g;
	}
	print;
}
