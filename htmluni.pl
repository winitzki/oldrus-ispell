#!/usr/bin/perl -w

# Script to work with Unicode entities in HTML. version 2.

# Usage: htmluni -fromuni -map=./KOI8-C.txt < fileUnicode.html > file8bit.html
#	htmluni -touni -map=./ISO8859-1.txt < file8bit.html > fileUnicode.html

die "Converts text from/to 8-bit / HTML with Unicode entities / UTF-8. Usage:\n htmluni.pl [-fromuni|-touni] -map={file} [-utf8] [-bylines] < infile > outfile\n" if ($#ARGV == -1);

# HTML ISO-8859-1 entities
%html_entity =
(
"AElig" => "198",
"Aacute" => "193",
"Acirc" => "194",
"Agrave" => "192",
"Alpha" => "913",
"Aring" => "197",
"Atilde" => "195",
"Auml" => "196",
"Beta" => "914",
"Ccedil" => "199",
"Chi" => "935",
"Dagger" => "8225",
"Delta" => "916",
"ETH" => "208",
"Eacute" => "201",
"Ecirc" => "202",
"Egrave" => "200",
"Epsilon" => "917",
"Eta" => "919",
"Euml" => "203",
"Gamma" => "915",
"Iacute" => "205",
"Icirc" => "206",
"Igrave" => "204",
"Iota" => "921",
"Iuml" => "207",
"Kappa" => "922",
"Lambda" => "923",
"Mu" => "924",
"Ntilde" => "209",
"Nu" => "925",
"OElig" => "338",
"Oacute" => "211",
"Ocirc" => "212",
"Ograve" => "210",
"Omega" => "937",
"Omicron" => "927",
"Oslash" => "216",
"Otilde" => "213",
"Ouml" => "214",
"Phi" => "934",
"Pi" => "928",
"Prime" => "8243",
"Psi" => "936",
"Rho" => "929",
"Scaron" => "352",
"Sigma" => "931",
"THORN" => "222",
"Tau" => "932",
"Theta" => "920",
"Uacute" => "218",
"Ucirc" => "219",
"Ugrave" => "217",
"Upsilon" => "933",
"Uuml" => "220",
"Xi" => "926",
"Yacute" => "221",
"Yuml" => "376",
"Zeta" => "918",
"aacute" => "225",
"acirc" => "226",
"acute" => "180",
"aelig" => "230",
"agrave" => "224",
"alefsym" => "8501",
"alpha" => "945",
"amp" => "38",
"and" => "8869",
"ang" => "8736",
"aring" => "229",
"asymp" => "8776",
"atilde" => "227",
"auml" => "228",
"bdquo" => "8222",
"beta" => "946",
"brvbar" => "166",
"bull" => "8226",
"cap" => "8745",
"ccedil" => "231",
"cedil" => "184",
"cent" => "162",
"chi" => "967",
"circ" => "710",
"clubs" => "9827",
"cong" => "8773",
"copy" => "169",
"crarr" => "8629",
"cup" => "8746",
"curren" => "164",
"dArr" => "8659",
"dagger" => "8224",
"darr" => "8595",
"deg" => "176",
"delta" => "948",
"diams" => "9830",
"divide" => "247",
"eacute" => "233",
"ecirc" => "234",
"egrave" => "232",
"empty" => "8709",
"emsp" => "8195",
"ensp" => "8194",
"epsilon" => "949",
"equiv" => "8801",
"eta" => "951",
"eth" => "240",
"euml" => "235",
"exist" => "8707",
"fnof" => "402",
"forall" => "8704",
"frac12" => "189",
"frac14" => "188",
"frac34" => "190",
"frasl" => "8260",
"gamma" => "947",
"ge" => "8805",
"gt" => "62",
"hArr" => "8660",
"harr" => "8596",
"hearts" => "9829",
"hellip" => "8230",
"iacute" => "237",
"icirc" => "238",
"iexcl" => "161",
"igrave" => "236",
"image" => "8465",
"infin" => "8734",
"int" => "8747",
"iota" => "953",
"iquest" => "191",
"isin" => "8712",
"iuml" => "239",
"kappa" => "954",
"lArr" => "8656",
"lambda" => "955",
"lang" => "9001",
"laquo" => "171",
"larr" => "8592",
"lceil" => "8968",
"ldquo" => "8220",
"le" => "8804",
"lfloor" => "8970",
"lowast" => "8727",
"loz" => "9674",
"lrm" => "8206",
"lsaquo" => "8249",
"lsquo" => "8216",
"lt" => "60",
"macr" => "175",
"mdash" => "8212",
"micro" => "181",
"middot" => "183",
"minus" => "8722",
"mu" => "956",
"nabla" => "8711",
"nbsp" => "160",
"ndash" => "8211",
"ne" => "8800",
"ni" => "8715",
"not" => "172",
"notin" => "8713",
"nsub" => "8836",
"ntilde" => "241",
"nu" => "957",
"oacute" => "243",
"ocirc" => "244",
"oelig" => "339",
"ograve" => "242",
"oline" => "8254",
"omega" => "969",
"omicron" => "959",
"oplus" => "8853",
"or" => "8870",
"ordf" => "170",
"ordm" => "186",
"oslash" => "248",
"otilde" => "245",
"otimes" => "8855",
"ouml" => "246",
"para" => "182",
"part" => "8706",
"permil" => "8240",
"perp" => "8869",
"phi" => "966",
"pi" => "960",
"piv" => "982",
"plusmn" => "177",
"pound" => "163",
"prime" => "8242",
"prod" => "8719",
"prop" => "8733",
"psi" => "968",
"quot" => "34",
"rArr" => "8658",
"radic" => "8730",
"rang" => "9002",
"raquo" => "187",
"rarr" => "8594",
"rceil" => "8969",
"rdquo" => "8221",
"real" => "8476",
"reg" => "174",
"rfloor" => "8971",
"rho" => "961",
"rlm" => "8207",
"rsaquo" => "8250",
"rsquo" => "8217",
"sbquo" => "8218",
"scaron" => "353",
"sdot" => "8901",
"sect" => "167",
"shy" => "173",
"sigma" => "963",
"sigmaf" => "962",
"sim" => "8764",
"spades" => "9824",
"sub" => "8834",
"sube" => "8838",
"sum" => "8721",
"sup" => "8835",
"sup1" => "185",
"sup2" => "178",
"sup3" => "179",
"supe" => "8839",
"szlig" => "223",
"tau" => "964",
"there4" => "8756",
"theta" => "952",
"thetasym" => "977",
"thinsp" => "8201",
"thorn" => "254",
"tilde" => "732",
"times" => "215",
"trade" => "8482",
"uArr" => "8657",
"uacute" => "250",
"uarr" => "8593",
"ucirc" => "251",
"ugrave" => "249",
"uml" => "168",
"upsih" => "978",
"upsilon" => "965",
"uuml" => "252",
"weierp" => "8472",
"xi" => "958",
"yacute" => "253",
"yen" => "165",
"yuml" => "255",
"zeta" => "950",
"zwj" => "8205",
"zwnj" => "8204",
);
# Read map

$map = ("@ARGV" =~ /-map=([^ ]*)/i) ? $1 : "";

($map eq "") && die "Error: need 8 bit encoding table (-map option).\n";

open (MAP, "$map") || die "Error: cannot open map file '$map'.\n";

$makeuni = ("@ARGV" =~ /-touni/i) ? 1 : 0;	# By default, convert from Unicode

$want_utf8 = ("@ARGV" =~ /-utf-?8/i) ? 1 : 0;	# By default, do not use UTF8

$bylines = ("@ARGV" =~ /-bylines/i) ? 1 : 0;	# By default, read all text at once

for ($i=0; $i<256; ++$i) {
	$table[$i] = 0;
}

# Read the 8-bit mapping table
while(<MAP>) {
	s/#.*$//;
	if (/^\s*(0x[0-9A-F]+)\s+(0x[0-9A-F]+)/i) {
		$char8 = hex($1);
		$charU = hex($2);
		$table[$char8] = $charU;
		$unitable{"$charU"} = $char8;
#		print "$char8 -> $charU\n";
	}
	
}

close MAP;

# whether to read all text at once
undef $/ unless ($bylines);

while(<STDIN>) {
  if ($want_utf8)
  {
	if ($makeuni)
	{	# convert 8-bit text (perhaps with HTML entities) into Unicode UTF-8
		# HTML entities are either &#1234; or &Ntilde; etc.
		# Tab, space, CR must be handled separately due to KOI8-C madness
		s/(&#[0-9]+;|&[A-Za-z][A-Za-z0-9]+;|[^-A-z0-9 \t\n])/{&make_uni_from_text($1);}/ge;
	}
	else
	{	# convert Unicode UTF-8 into 8-bit text, perhaps with HTML entities
		my $result = "";
		for (my $index=0; $index<length($_); )
		{
        	# Now read one char from UTF string
        	# Don't need more than 6 bytes for the UTF reader
        	my ($curchar, $incr)   = &read_UTF_char(substr($_, $index, 6));  
        	# Check if $curchar is not -1 -- then it was the invalid char
        	# Invalid char symbol coming from UTF text
        	$curchar            = 0xFFFD if ($curchar == -1);
			# Represent the char as either 8-bit encoded, or as special (\t, \n, \r), or as HTML entity
			if ($curchar == 0x09 or $curchar == 0x0A or $curchar == 0x0D)	# special
			{
				$result .= pack("C", $curchar);
			}
			elsif (defined($unitable{$curchar}) and $unitable{$curchar} >= 0x20)
			{	# Do not use symbols from the lower ASCII that are below 0x20
				$result .= pack("C", $unitable{$curchar});
			}
			else	# as HTML entity
			{
				$result .= "&#" . $curchar . ";";
			}
			$index += $incr;
		}
		$_ = $result;
	}
  }
  else
  {
	if ($makeuni) {	# convert 8-bit text into Unicode HTML entities
		s/([^-A-z0-9 \t\n])/{ $i = unpack("C", $1); ($i > 127) ? "&#" . $table[$i] . ";" : $1;}/ge;
	}
	else
	{	# convert Unicode HTML entities into 8-bit text
		s/&#([0-9]+);/{ (defined($unitable{$1})) ? pack("C", $unitable{$1}) : "&#" . $1 . ";"; }/ge;
	}
  }
	print;
}

# Unicode stuff

sub make_uni_from_text
{	# take a string which is either a char or an HTML entity &....; and convert it to a Unicode string.
	my ($text) = (@_);
	my ($i);
	if ($text =~ /&#([0-9]+);/)	# Unicode HTML entity
	{
		return &make_unicode($1);
	}
	elsif ($text =~ /&(.+);/)	# other HTML entity)
	{
		if (defined($html_entity{$1}))
		{
			return &make_unicode($html_entity{$1});
		}
		else
		{	# undefined entity, do nothing, don't have to convert to Unicode since all chars are lower ASCII
			return $text;
		}
	}
	else	# single character
	{
		$i = unpack("C", $text);
		return &make_unicode($table[$i]);
	}
}

sub read_UTF_char
{
    # Read one character from UTF-8 string, return char code and # of bytes read as a list (char code, # of bytes).
    # Assuming valid start of UTF-8 string or else return charcode -1.
    my ($text)  = (@_);

    my $invalid_charcode = -1;
    my (
        $index,
        $byte,
        $charcode,
        $expect
       )        = (0, 0, $invalid_charcode, 0);

    for (; $index < length($text) and ($expect != 0 or $charcode == $invalid_charcode); ++$index)
    {
        $byte   = unpack("C", substr($text, $index, 1));
        if ($expect > 0)
        {
            # Expecting a data byte
            if (($byte & 0xC0) == 0x80)
            {
                # data byte
                if ( $index == 1 and $charcode == 0 and ( ($byte & 0x3F)>>(7-$expect) == 0 ))
                {
                    # Detect some bad UTF-8
                    $charcode   = $invalid_charcode;
                    last;
                }
                $charcode       = (($charcode << 6) | ($byte & 0x3F));
                last if (--$expect == 0);
            }
            else
            {
                # no data byte
                $charcode       = $invalid_charcode;
                last;
            }
        }       # Now not expecting anything i.e. must be on first byte
        elsif (($byte & 0x80) == 0)
        {       # ASCII range. Either we have prematurely terminated a chunk, or it's the first byte
            $charcode   = ($index == 0) ? $byte : $invalid_charcode;
            last;
        } elsif (($byte & 0xE0) == 0xC0) {      # expect 1
            $charcode   = ($byte & 0x1F);
            if ($charcode < 2) {        # Detect some bad UTF-8
                $charcode = $invalid_charcode;
                last;
            }
            $expect     = 1;
        } elsif (($byte & 0xF0) == 0xE0) {      # expect 2
            $charcode   = ($byte & 0x0F);
            $expect     = 2;
        } elsif (($byte & 0xF8) == 0xF0) {      # expect 3
            $charcode   = ($byte & 0x07);
            $expect     = 3;
        } elsif (($byte & 0xFC) == 0xF8) {      # expect 4
            $charcode   = ($byte & 0x03);
            $expect     = 4;
        } elsif (($byte & 0xFE) == 0xFC) {      # expect 5
            $charcode   = ($byte & 0x01);
            $expect     = 5;
        } else {        # Invalid UTF-8 string
            $charcode   = $invalid_charcode;
            last;
        }
    }
    ($charcode, $index+1);
}

sub make_unicode
{	# return a Unicode string corresponding to a given char index (between 0x0 and 0x7FFFFFFF)
	my ($char) = (@_);
	my $result = "";
	my $first_byte = 0;
	my $length = 0;
	if (0 <= $char and $char < 0x80)
	{	# lower ASCII
		$result = pack("C", $char);
	}
	else
	{	# build a byte sequence
	  $length = 1;
	  $first_byte = 0x1;
	  while($char > 0x3F)	# more than 6 bits: cut straightforwardly in pieces of 6 bits each
	  {
		$length++;
		$first_byte = ($first_byte << 1) + 1;
		$result = pack("C", 0x80 | ($char & 0x3F)) . $result;
		$char = $char >> 6;
	  }
	  # now, $char is less than 6 bits. We may need 1 or 2 more bytes.
	  # With 1 byte, we would have 7-$length free bits. If $char fits into this many bits, then we should use 1 byte.
	  if (($char >> (7-$length)) == 0)
	  {	# fits into one extra byte
		$first_byte = $first_byte << (8-$length);
		$result = pack("C", $first_byte | $char) . $result;
	  }
	  else
	  {	# does not fit, need 2 extra bytes: the first byte will be 10xxxxxx, and the 0th byte will be 11...10...0.
	  	$result = pack("C", 0x80 | $char) . $result;
		$first_byte = ($first_byte << 1) + 1;
		$length++;
		$first_byte = $first_byte << (8-$length);
		$result = pack("C", $first_byte) . $result;
	  }
	}
	
	return $result;
}

