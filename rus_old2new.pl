#!/usr/bin/perl

# Convert old Russian orthography to new
# After running this script, check "-ия" -> "ие", "аго", "оне"

undef $/ unless ("@ARGV" =~ /-bylines/);

$wb='[^A-z0-9Ю-Ъю-ъ╡╒╤╕╠║╪╛Ёё]';
$letter='[Ю-Ъю-ъ╡╒╤╕╠║╪╛Ёё]';

while(<STDIN>) {
	# Replace some prefixes.
	s/([Бб]е)з(?=[кпстфхцчшщ])/\1с/g;	# без-(...)
	s/([Рр][ао])з(?=[с])/\1с/g;	# раз-(с), роз-(с)
	s/([Вв]о)з(?=[с])/\1с/g;	# воз-(с)
	s/($wb)([Ии])з(?=[с])/\1\2с/g;	# ^из-(с)
	# Replace obsolete words: ея, нея, он╒, одн╒
	s/($wb)([Ее])я(?=$wb)/\1\2ё/g;
	s/($wb)нея(?=$wb)/\1неё/g;
	s/($wb)([Оо]д?)н╒(?=$wb)/\1\2ни/g;
	# Replace obsolete word endings: -ыя, -аго, -яго
	s/ыя(?=$wb)/ые/g;
	s/(цк|ск|[аое]нн|ш|щ|оч)╕я(?=$wb)/\1ие/g;	# Careful with replacing -╕я! Lots of words end with a legitimate -╕я.
	s/([цчшщ])аго(?=$wb)/\1его/g;	# Careful
	s/([^м][б]|$letter[с]|[^б][л]|$letterб[л]|[вгджзкмнпртфх])аго(?=$wb)/\1ого/g;	# Careful: благо, саго, люмбаго. Но: гиблаго, б╒лесаго.
	s/яго(?=$wb)/его/g;
	# Replace some obsolete word spellings
	s/ессурс/есурс/g;	# рессурс
	s/оффиц/офиц/g;	# оффиц╕альный
	s/ксплоат/ксплуат/g;	# эксплоатац╕я
	s/([Аа])п(плоди)(р[оу]|сме)/\1\2\3/g;	# апплодировать

	# Now can replace Yat' by E, I roman by I, Fita by F
	tr/╡╒╤╕╠║╪╛/ЕеИиИиФф/;
	# Remove trailing er
	s/([бвгджзклмнпрстфхцчшщ╛БВГДЖЗКЛМНПРСТФХЦЧШЩ╪])[Ъъ](?=$wb)/\1/g;
	s/([бвгджзклмнпрстфхцчшщ╛БВГДЖЗКЛМНПРСТФХЦЧШЩ╪])[Ъъ]([- .,?!\/\\\"\':;+*^\t\n])/\1\2/g;
	s/([бвгджзклмнпрстфхцчшщ╛БВГДЖЗКЛМНПРСТФХЦЧШЩ╪])[Ъъ]$/\1/g;

	# Remove er before non-ioted vowels
	s/ъ(?=[аоуыэ])//g;
	s/ъ([и])/ы/g;

	print;
}
