#!/usr/bin/perl
########################################################################
#
#	Universal filter of Russian encodings version 2.6a
#	created by Serge Winitzki (1997-2000). This is free software.
#	http://members.linuxstart.com/~winitzki/
#
#	Features:
#
#	- Self-contained perl script, does not require any Perl packages.
#	- Supported encodings: DOS CP-866 or "alternative" ('alt'),
#	ISO8859-5 ('iso'), KOI-8 ('koi'), Russkaja Latinica ('lat'),
#	Macintosh ('mac'), Unicode ('uni'), UTF-8 ('utf'), Windows CP-1252 ('win').
#	- Letters 'YO' and 'yo' correctly supported in all encodings.
#	- Strict 'Russkaja Latinica' conformance for the 'lat' encoding which allows
#	almost unambiguous repeated native<->latinized translations of Russian text.
#	- Determines the required encodings from invoked script's name
#	(if renamed alt2koi etc.) or from command line option.
#	- Supports KOI8-C extension for old Russian letters (Yat', Izhitsa, I, Fita)
#	The experimental KOI8-C encoding is a mix of KOI8-U and 1251.
#	Old Russian letters are only supported for WIN, KOI and UTF
#	encodings. (not in ALT, ISO, MAC!)
#	Recognizes copyright sign in Win, KOI (using KOI8-C), Mac.
#
#	Limitations:
#
#	- Unicode/UTF-8 support is preliminary and does not fully conform to the
#	official ISO8859-5 to Unicode cross-map (it works only for Cyrillic text).
#	- Unicode/UTF-8 support only recognizes Cyrillic Unicode characters, so results
#	on mixed cyrillic/other languages texts are most likely going to be wrong.
#	- Unicode/UTF-8 output options may not generate valid Unicode unless input is
#	strictly a mix of Cyrillic and normal ASCII letters (no "copyright"
#	characters, hyphens or anything like that).
#	- Old Russian support is only compatible with MY OWN "KOI8-C"
#	extension! Unicode symbols are generated and recognized in
#	UTF-8 mode only (i.e. -koi2utf, -utf2koi) and for letters only.
#	Converting text with these extra letters to any other encoding
#	will give wrong results. Fake ISO entries (0x80-0x9F) are generated
#	for internal purposes only. Win encoding of old Russian letters
#	corresponds to the font "Oldrus.TTF" (warning: the font does not
#	contain Copyright sign, therefore conversion KOI->Win->Koi will
#	lose Capital Izhitsa!)
#
#	Command line options (all options are case-insensitive):
#	e.g. -alt2koi or -mac2win or whatever	select required encodings
#	-bylines	convert text line by line instead of loading all into memory
#
#	Options for lat -> ... conversion:
#	-tex	do not translate text inside $..$, $$..$$ and \command names
#	-wisv	translate w as v (default w is tshcha)
#	-qisja	translate q as ja (default q is tshcha)
#	-usekh	translate kh as h (default kh='k''h')
#	-oldrus	allow old Russian letters (Yat', Izhitsa, I, Fita)
#
#	Example usage (if this file is 323.pl in current directory):
#		perl 323.pl -wisv -lat2utf < inputfile > outputfile
#
########################################################################
#
#	Installation:
#	if needed, edit the first line to reflect your perl location (`which perl`);
#	put this script somewhere on the path with executable permission;
#	optionally make links to this script named alt2win, win2koi etc.
#	(The script can determine the source/target encoding from its *name*.)
#	e.g. copy this file to /usr/local/bin/323.pl and then say
#	cd /usr/local/bin; chmod 755 323.pl
#	ln -s 323.pl alt2koi; ln -s 323.pl koi2alt; and so on (optional) for all needed
#	combinations of alt, iso, koi, mac, win, lat. Names are case-insensitive.
#	After all this, use as a filter. For example, `lat2koi < file1 > file2`
#	or else have to specify encoding as `323.pl -lat2koi < file1 > file2`
#
############################# start of script ##########################
#
#	Direct native encodings: The tables may have unequal length, since
#	the translation only uses the initial parts of the tables. For instance,
#	non-Russian cyrillic symbols are only present in Win, ISO and KOI tables (and not all)
#	Symbols missing in a table are substituted by 0x7F
#	The order of letters must be otherwise the same in all tables:
#	\x7F (c) (No.)
#	ABVGDE Zh ZIJKLMNOPRSTUFHC Ch Sh Shch ~ Y ' E' Yu Ya
#	abvgde zh zijklmnoprstufhc ch sh shch ~ y ' e' yu ya
#	YO yo Iroman iroman YI yi IE ie Yat' yat' Fita fita Izhitsa izhitsa Psi psi
#

$rusmac="\x7F\xA9\xDC\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xDF\xDD\xDE\xA7\xB4\xBA\xBB\xB8\xB9";
$rusalt="\x7F\x7F\xFC\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\x49\x69\xF4\xF5\xF2\xF3";	# No Iroman/iroman, substituting I/i
$ruswin="\x7F\xA9\xB9\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF\xA8\xB8\xB2\xB3\xAF\xBF\xAA\xBA\x80\x90\xAA\xBA\xA1\xA2";	# old Russian for "oldrus.ttf", except yat' which is faked by the Serbian (0x80, 0x90), and no Belarussian
$ruskoi="\x7F\xBF\xB9\xE1\xE2\xF7\xE7\xE4\xE5\xF6\xFA\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFE\xFB\xFD\xFF\xF9\xF8\xFC\xE0\xF1\xC1\xC2\xD7\xC7\xC4\xC5\xD6\xDA\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDE\xDB\xDD\xDF\xD9\xD8\xDC\xC0\xD1\xB3\xA3\xB6\xA6\xB7\xA7\xB4\xA4\xB2\xA2\xBC\xAC\xB1\xA1\xBA\xAA";	# KOI8-C really
$rusiso="\x7F\x7F\xF0\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xA1\xF1\xA6\xF6\xA7\xF7\xA4\xF4\x82\x83\x92\x93\x94\x95\x90\x91";	# All codes outside of A0-FF range are not really ISO but our hack for old Russian letters.

#
####################### main part of the script ########################
#

$from="nothing";
$to="nothing";
$lat_output="no";	#whether latinized output is requested. special flag.
$lat_input="no";	#same for input
$uni_output="no";	#whether unicode output is requested
$uni_input="no";
$utf_output="no";	#whether UTF-8 output is requested
$utf_input="no";

$help='Universal converter of Russian encodings version 2.4
Created by Serge Winitzki, 1999. No warranty. This is free software.
http://www.geocities.com/CapeCanaveral/Lab/5735/1/

   Supported encodings: alt, iso, koi, lat, mac, uni, utf, win
   Example usage:

	323 -alt2koi < inputfile > outputfile

   Or rename/link to "xxx2xxx" where xxx is one of the supported encodings and

	alt2koi < inputfile > outputfile

   Note: latinized encoding "lat" is implemented according to the "Russkaja
Latinica" scheme. See http://www.geocities.com/Athens/Forum/5344/RL/ for
more details. Sample options for "lat" input:

	323 -lat2koi -usekh -wisv -qisja -tex < inputfile > outputfile

   See the script preamble for more information.
';

$all_enc="acfiklmnostuw";

if ("@ARGV" =~ /-([$all_enc]{3})2([$all_enc]{3})/i) {
	$a1=$1;
	$a2=$2;
	$error="Incorrect encoding '$a1 -> $a2' on command line.";
} else {
	#decide the source and target encoding based on our name
	$name=`basename $0`;
	if ($name =~ /([$all_enc]{3})2([$all_enc]{3})/i) {	#this should match koi2win etc.
	$a1="$1";
	$a2="$2";
	}
	$error="Incorrect usage of this script, see $0 for documentation.";
}

if ("@ARGV" =~ /help/i) {
	print $help . "\n";
	exit;
}


{
	if ($a1 =~ /win/i) {
		$from="$ruswin";
	} elsif ($a1 =~ /koi/i) {
		$from="$ruskoi";
	} elsif ($a1 =~ /alt/i) {
		$from="$rusalt";
	} elsif ($a1 =~ /mac/i) {
		$from="$rusmac";
	} elsif ($a1 =~ /iso/i) {
		$from="$rusiso";
	} elsif ($a1 =~ /uni/i) {
		$from="$rusiso";
		$uni_input="yes";
	} elsif ($a1 =~ /utf/i) {
		$from="$rusiso";
		$utf_input="yes";
	} elsif ($a1 =~ /lat/i) {
		$from="$ruskoi";	#this is because our latin table is for koi
		$lat_input="yes";
	}
	if ($a2 =~ /win/i) {
		$to="$ruswin";
	} elsif ($a2 =~ /koi/i) {
		$to="$ruskoi";
	} elsif ($a2 =~ /alt/i) {
		$to="$rusalt";
	} elsif ($a2 =~ /mac/i) {
		$to="$rusmac";
	} elsif ($a2 =~ /iso/i) {
		$to="$rusiso";
	} elsif ($a2 =~ /uni/i) {
		$to="$rusiso";
		$uni_output="yes";
	} elsif ($a2 =~ /utf/i) {
		$to="$rusiso";
		$utf_output="yes";
	} elsif ($a2 =~ /lat/i) {
		$to="$ruskoi";	#this is because our latin table is for koi
		$lat_output="yes";
   }

}

if ($to eq "nothing" or $from eq "nothing") {	#wrong options
	print "$error\n$0 -help for brief usage instructions.\n";
	exit 1;
}

if (not ("@ARGV" =~ /-bylines/i)) {
	undef $/;	#make it convert the whole file at once, usually much faster.
}

while(<STDIN>) {	#main loop

#effectively we want to do e.g.
# eval ("tr/$ruswin/$rusalt/");	#because tr requires constant strings


	if ($lat_input eq "yes") {
		&translate_lat_to_koi();	#call special procedure operating on $_
	} elsif ($uni_input eq "yes") {
		&translate_uni_to_iso();
	} elsif ($utf_input eq "yes") {
		&translate_utf_to_iso();
	}
	#now $_ contains all cyrillic text and we need to transform it
	# Main transformation. First check that $from is not longer than $to, then transform $_
	if (length($from)>length($to)) {
		$from=substr($from, 0, length($to));
	}
	eval ("tr/$from/$to/") unless ($from eq $to);	#we need to do this now
	#now $_ contains correctly transformed text
	if ($lat_output eq "yes") {
		&translate_koi_to_lat();	#call special procedure operating on $_
	} elsif ($uni_output eq "yes") {
		&translate_iso_to_uni();
	} elsif ($utf_output eq "yes") {
		&translate_iso_to_utf();
	}
	print;
}

#################### end of main part of the script ####################

sub translate_koi_to_lat {
#use this procedure to replace each character in $_

#using Russkaja Latinica standard (by Alexy Khabrov and Serge Winitzki, 1995)

#first, break digraphs Y-A, Y-U, Y-O - just in case we get them in the text although they are ungrammatical. Insert the canonical breaking char \\.

	s/([\xF9\xD9])([\xE1\xEF\xF5\xC1\xCF\xD5])/$1\\$2/g;

#also break the sh-ch which should rarely happen but still

	s/([\xFB\xDB])([\xFE\xDE])/$1\\$2/g;

#second, transform letters that require combinations. Using "x" for "kha", "j'" for "i kratkoe, "shch" for "tshcha", "e'" for "e oborotnoe".
	s/\xB3/Yo/g;
	s/\xF6/Zh/g;
	s/\xEA/J'/g;
	s/\xFE/Ch/g;
	s/\xFB/Sh/g;
	s/\xFD/Shch/g;
	s/\xFC/E'/g;
	s/\xE0/Yu/g;
	s/\xF1/Ya/g;

	s/\xA3/yo/g;
	s/\xD6/zh/g;
	s/\xCA/j'/g;
	s/\xDE/ch/g;
	s/\xDB/sh/g;
	s/\xDD/shch/g;
	s/\xDC/e'/g;
	s/\xC0/yu/g;
	s/\xD1/ya/g;

	if ("@ARGV" =~ /-oldrus/i) {
		# KOI8-C extension: EXPERIMENTAL. Designed not to conflict with KOI8-U.

		s/\xB6/I~/g;	# I roman
		s/\xA6/i~/g;	# i roman
		s/\xB2/E~/g;	# Yat'
		s/\xA2/e~/g;	# yat'
		s/\xBC/~F/g;	# Fita
		s/\xAC/~f/g;	# fita
		s/\xB1/~V/g;	# Izhitsa
		s/\xA1/~v/g;	# izhitsa
	}

#then replace other letters

tr/\xE1\xE2\xF7\xE7\xE4\xE5\xFA\xE9\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE3\xFF\xF9\xF8\xC1\xC2\xD7\xC7\xC4\xC5\xDA\xC9\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC3\xDF\xD9\xD8/ABVGDEZIKLMNOPRSTUFXC~Y'abvgdeziklmnoprstufxc~y'/;
}

sub translate_lat_to_koi {	#operate on $_ only, translate latinized input to KOI8

	# Rules for digraphs: 1. An all-lowercase digraph must be defined.
	# 2. If the first letter is [A-z], then the digraph is lowercase if both letters are lowercase and uppercase otherwise.
	# 3. If the first letter is not [A-z], then the case of the 2nd letter determins the case of the digraph.

	%translit=(
		# Canonical RL scheme
		"Shch" => "\xFD",
		"shch" => "\xDD",
		"Yo" => "\xB3",
		"yo" => "\xA3",
		"Jo" => "\xB3",
		"jo" => "\xA3",
		"Zh" => "\xF6",
		"zh" => "\xD6",
		"J'" => "\xEA",
		"j'" => "\xCA",
		"J`" => "\xEA",
		"j`" => "\xCA",
		"Ch" => "\xFE",
		"ch" => "\xDE",
		"Sh" => "\xFB",
		"sh" => "\xDB",
		"E'" => "\xFC",
		"e'" => "\xDC",
		"E`" => "\xFC",
		"e`" => "\xDC",
		"`E" => "\xFC",
		"`e" => "\xDC",
		"Yu" => "\xE0",
		"yu" => "\xC0",
		"Ju" => "\xE0",
		"ju" => "\xC0",
		"Ya" => "\xF1",
		"ya" => "\xD1",
		"Ja" => "\xF1",
		"ja" => "\xD1",
	);

	if ("@ARGV" =~ /-oldrus/i) {
		# EXPERIMENTAL: KOI8-C extensions
		$translit{"~F"} = "\xBC";	# Fita
		$translit{"~f"} = "\xAC";	# fita
		$translit{"E~"} = "\xB2";	# Yat'
		$translit{"e~"} = "\xA2";	# yat'
		$translit{"I~"} = "\xB6";	# I roman
		$translit{"i~"} = "\xA6";	# i roman
		$translit{"~V"} = "\xB1";	# Izhitsa
		$translit{"~v"} = "\xA1";	# izhitsa
	}

	%malleable=(	# lowercase
		'~' => "\xDF",
		'`' => "\xD8",
		"'" => "\xD8",
		'@' => "\xDC",
	);

	%malleable_uc=(	# uppercase
		'~' => "\xFF",
		'`' => "\xF8",
		"'" => "\xF8",
		'@' => "\xFC",
	);

	$i=0;	#pointer into the input string ($_)
	
	$EnglishNow=0;	#state flag for the digestion machine
	#now need to set some options
	$want_tex = ("@ARGV" =~ /-tex/i) ? 1 : 0;
	$want_wisv = ("@ARGV" =~ /-wisv/i) ? 1 : 0;
	$want_qisja = ("@ARGV" =~ /-qisja/i) ? 1 : 0;
	$want_kh = ("@ARGV" =~ /-usekh/i) ? 1 : 0;
	
	#need to modify the tables now
	if ($want_kh) {
		$translit{"Kh"} = "\xE8";
		$translit{"kh"} = "\xC8";
	}
		
	$output="";	#to hold the output text

	while ($i < length($_)) {	#loop through the input
		# The current char is substr($_,i,1).
		# Note that $i will not always advance by 1 and sometimes be changed inside &digest_some()
		my $doutput = &digest_some();
		$i += length($doutput);
		$output .= $doutput;
	}
	$_ = $output;
}

sub digest_some {	# Return next output char(s), using $i as read-only position in $_ and using flags $want_tex and $want_wisv

# our state: $EnglishNow=2 if inside $$ or after '\ ', 1 if inside \command, 0 if in Russian.
# the '$' and \commands are all ignored unless $want_tex
	my $thischar = substr($_, $i, 1);	#just caching, aren't going to change it
	my $nextchar = substr($_, $i+1, 1);	#this may be changed

	if ($EnglishNow == 2) {
	  if ($want_tex) {
		if ($thischar . $nextchar eq '$$') {
			$EnglishNow= 0;
			return '$$';
		}
		if ($thischar eq '$') {
			$EnglishNow= 0;
			return '$';
		}
	  }
		# insert any additional switchers here
		if ($thischar . $nextchar eq '\\ ') {
			#switching back to Russian
			$EnglishNow= 0;
			$i += 2;	#incrementing $i here since not returning anything
			return "";
		}
		# ok, English is still going on
		return $thischar;
	} # case of $EnglishNow == 2 is done	

	if ($EnglishNow == 1 and $want_tex) {
		if ($thischar eq ' ' or $thischar eq '\n') {	# terminates \command
			$EnglishNow= 0;
			return $thischar;
		}
		if ($thischar . $nextchar eq '$$') {
			$EnglishNow= 2;
			return '$$';
		}
		if ($thischar eq '$') {
			$EnglishNow= 2;
			return '$';
		}
		if ($thischar eq '\\') {
			if ($nextchar =~ /[0-9A-z@\\\"\':]/) { # starts another \command right after this one
				$EnglishNow= 1;
				return $thischar;
			}
		}	
		# didn't switch to Russian, continue without translation
		return $thischar;
	} # case of $EnglishNow == 1 is done
	
	if ($EnglishNow == 0) {
	  if ($want_tex) {
		if ($thischar . $nextchar eq '$$') {
			$EnglishNow= 2;
			return '$$';
		}
		if ($thischar eq '$') {
			$EnglishNow= 2;
			return '$';
		}
	  }
	  if ($thischar eq '\\') {
	  	if ($want_tex) {
			if ($nextchar =~ /[0-9A-z@\\\"\':]/) { # starts \command
				$EnglishNow= 1;
				return $thischar;
			}
		}
		if ($nextchar eq ' ') {	# switch to English now
			$EnglishNow = 2;
			$i += 2;
			return "";
		}
		if ($nextchar eq '\\') {	# double backslash, skipping one
			$i += 1;
			return "\\";
		}
		
		#we get a backslash in Russian mode and not followed by space
		#tex mode quirks and double backslashes are already done
		#so we should swallow it and go on with the next char
		$i += 1;
		return "";
	  }	# End of processing backslash char
		# all switches have been processed, now do Russian stuff
		
		# first, the 4-letter combination for "tshcha"
		
		if (substr($_, $i, 4) eq 'shch') {	#lowercase
			$i += 3;
			return $translit{'shch'};
		}
		
		if (substr($_, $i, 4) =~ /shch/i) {	# uppercase: we now know it's not lowercase so any case combination works
			$i += 3;
			return $translit{'Shch'};
		}
		
		#now looking for digraphs
		$digraph = $thischar . $nextchar;
		$digraph =~ tr/A-Z/a-z/;	#now it's all lowercase
		if (defined($translit{$digraph})) {	# Found a digraph!
			if ($nextchar =~ /[A-Z]/ or $thischar =~ /[A-Z]/) {	# uppercase
				$thischar =~ tr/a-z/A-Z/;	# Clobber, clobber
				$nextchar =~ tr/A-Z/a-z/ if ($thischar =~ /[A-Z]/);	# Do not lowercase the second char if the first char is not a letter!
				$digraph = $thischar . $nextchar;
			}
			$i += 1;
			return $translit{$digraph};
		}

		# now search for malleables
		if (defined($malleable{$thischar})) {	# Found a malleable.
			$prevchar = ($i>0) ? substr($_, $i-1, 1) : "";
			if ($thischar eq '`' or $thischar eq "'") {
				if (not ($prevchar =~ /[\@A-Za-z]/) and $nextchar =~ /[\@A-Za-z]/) {	# ' and ` at beginning of word are not translated
					return $thischar;
				}
				
			}
			if ($prevchar eq '\\') {
				return $thischar;	# ' and ` prefixed by \ are not translated
			}
			if ($prevchar eq '^') {	# Special cases.
				return $malleable_uc{$thischar};
			}
			if ($prevchar eq '_') {
				return $malleable{$thischar};
			}
			if (($prevchar =~ /[A-Z \n\t]/ or length($prevchar) == 0) and $nextchar =~ /[A-Z \n\t]/) {
				return $malleable_uc{$thischar};
			}
			return $malleable{$thischar};
		}

		#if we are still here, we have a simple letter
		if ($want_qisja) {
			$thischar = ($thischar eq 'Q') ? $translit{'Ja'} : (($thischar eq 'q') ? $translit{'ja'} : $thischar);
		}
		if ($want_wisv) {
			$thischar = ($thischar eq 'W') ? 'V' : (($thischar eq 'w') ? 'v' : $thischar);
		}
		$thischar =~ tr/ABVGDEZIKLMNOPRSTUFXHCYWQJabvgdeziklmnoprstufxhcywqj/\xE1\xE2\xF7\xE7\xE4\xE5\xFA\xE9\xEB\xEC\xED\xEE\xEF\xF0\xF2\xF3\xF4\xF5\xE6\xE8\xE8\xE3\xF9\xFD\xFD\xEA\xC1\xC2\xD7\xC7\xC4\xC5\xDA\xC9\xCB\xCC\xCD\xCE\xCF\xD0\xD2\xD3\xD4\xD5\xC6\xC8\xC8\xC3\xD9\xDD\xDD\xCA/;
		return $thischar;

	} # case of EnglishNow == 0 is done

}

sub translate_iso_to_uni {
	$output="";
	$i=0;
	while ($i < length($_)) {	#loop through the input char by char, slow
		$thischar=substr($_,$i,1);
		$output .= (unpack("C", $thischar)> 160) ? "\x04" . pack("C", unpack("C" ,$thischar)-160) : "\x00" . $thischar;
		++$i;
	}
	$_=$output;
}

sub translate_uni_to_iso {
	$output="";
	$i=0;
	while ($i < length($_)) {	#loop through the input char by char, slow
		$thischar=substr($_,$i,1);
		if ($thischar eq "\x04" and $i < length($_)-1) {	# Now look at the second part of the 16 bit code.
#			$nextchar=pack("C", unpack("C", substr($_,$i+1,1))+160);
			$nextchar = unpack("C", substr($_,$i+1,1))+160;
			if ($nextchar > 160 and $nextchar < 256) {	#we are in range for ISO cyrillics
				$nextchar = pack("C", $nextchar);
#				$output .= (index($rusiso, $nextchar)>=0) ? $nextchar : substr($_,$i,2);	#this would be too paranoid. Let's give lje, nje &co. a chance.
				$output .= $nextchar;
			} else {	#we are out of range, preserve Unicode as is
				$output .= substr($_,$i,2);
			}
			$i += 2;
		} else {	#we are not looking at a Unicode cyrillic wide char
			$output .= "$thischar" unless ($thischar eq "\x00");
			$i += 1;
		}
	}
	$_=$output;
}

#UTF-8 encoding scheme. We are converting it to ISO or to it from ISO.
#So 1) We create phony ISO codes for our extra letters:
#WinISO	KOI8-C		Irom irom YI yi IE ie Yat' yat' Fita fita Izhitsa izhitsa Psi psi
#B2	A6	"\xB6";	# I roman
#B3	F6	"\xA6";	# i roman
#AF	A7	"\xB7";	# YI (I:)
#BF	F7	"\xA7";	# yi (i:)
#AA	A4	"\xB4";	# IE
#BA	F4	"\xA4";	# ie
#	82	"\xB2";	# Yat'
#	83	"\xA2";	# yat'
#	92	"\xBC";	# Fita
#	93	"\xAC";	# fita
#	94	"\xB1";	# Izhitsa
#	95	"\xA1";	# izhitsa
#	90	"\xBA";	# Psi
#	91	"\xAA";	# psi
#2) All UTF-8 entities will be 2 bytes long, so we create the leading byte by hand.
#For ISO characters c in range 0x80 to 0x9F, the UTF-8 is 0xD1 0x(c+0x20)
#For ISO characters c in range 0xA1 to 0xDF, the UTF-8 is 0xD0 0x(c-0x20)
#For ISO characters c in range 0xE0 to 0xFF, the UTF-8 is 0xD1 0x(c-0x60)

sub translate_iso_to_utf {
	$output="";
	$i=0;
	while ($i < length($_)) {	#loop through the input
		$thischar=substr($_,$i,1);
		$thischarcode=unpack("C", $thischar);
		$output .= ($thischarcode >= 0xE0) ? "\xD1" . pack("C", $thischarcode-0x60) : ($thischarcode >= 0xA1) ? "\xD0" . pack("C", $thischarcode-0x20) : ($thischarcode >= 0x80) ? "\xD1" . pack("C", $thischarcode+0x20) : $thischar;
		++$i;
	}
	$_=$output;
}

sub translate_utf_to_iso {	# Warning: output may be wrong if input contains anything but UTF-8 cyrillic chars or ASCII!
	$output="";
	$i=0;
	while ($i < length($_)) {	#loop through the input
		$thischar=substr($_,$i,1);
		if (($thischar eq "\xD0" or $thischar eq "\xD1")  and $i < length($_)-1) {	# Now look at the second part of the 16 bit code.
			
			$nextchar = unpack("C", substr($_,$i+1,1))-128+160 + (($thischar eq "\xD1") ? 64 : 0);
			$nextchar -= 128	# Compensate for our fake ISO codes for old Russian.
				if ($thischar eq "\xD1" and $nextchar >= 256);
			if ($nextchar > 127 and $nextchar < 256) {	#we are in range for ISO cyrillics plus our fake ISO codes
				$nextchar = pack("C", $nextchar);
#				$output .= (index($rusiso, $nextchar)>=0) ? $nextchar : substr($_,$i,2);	#this would be too paranoid. Let's give lje, nje &co. a chance.
				$output .= $nextchar;
			} else {	#we are out of range, preserve UTF-8 as is
				$output .= substr($_,$i,2);
			}
			$i += 2;
		} else {	#we are not looking at a Unicode cyrillic wide char
			$output .= "$thischar";
			$i += 1;
		}
	}
	$_=$output;
}
