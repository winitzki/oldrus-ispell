#!/usr/bin/perl -w

use strict;

# Convert a text file to PS using a given BDF font. Script by Serge Winitzki. Both the script and the embedded PS code are in public domain.
# http://www.linuxstart.com/~winitzki/
my ($NAME, $VERSION) = ("txtbdf2ps",  "0.6.6");
#
# Sample usage: "cat font.bdf text.txt | txtbdf2ps > output.ps"
# or run "perl txtbdf2ps help"
######################################################################
# Version history
#	Version 0.1: nothing works except fixed width fonts and no wrapping
#	Version 0.5: first public release. Wrapping works, still bugs in font spacing. Added pagebreak char (formfeed 0x0C)
#	Version 0.6: fixed -gap option; fixed and added better indentation.
#	Version 0.6.5: restructured script; ascii85 option, more compact PS output, initial support for >256 chars in font but no UTF-8 input yet
#	Version 0.6.6: fixed bug: characters sometimes omitted from font
######################################################################
# TO DO:
#	1. Support printing of page numbers, flexibly (top,bottom,left,right,odd,even,first=1)
#	2. Add more special actions driven by special characters, a` la formfeed. Require headers to be declared like that.
#	3. Option for writing prologue separately (will improve performance on very large files).
#	4. Use some special characters for font sizes, headers a` la Moshkow? How to make bold fonts using PS? (shift by at most one pixel and superimpose, repeat if need more than 1 pixel, for larger fonts)
#	5. Automatic generation of slanted font using PS transforms. Special chars to switch on/off italic and bold text? (Use any chars below 0x20.)
#	6. Draw horizontal rules using PS?
#	7. Support special etext features: ___, ---, --, advanced poetry formatting?
#	8. Unicode UTF-8 input support.

my ($textfile	# name of the input text file
	, $textinput	# File handle of the input text file
	, $BDFinput	# file handle of the input BDF file
	, %options	# general options relating to printing
	, %BDFfont	# the whole BDF font structure and all options relating to it, and PS code needed to define font
	, %PSoutput	# the whole PS output structure and all info about what is needed to print. Should be able to print the PS file using only %PSoutput and %BDFfont
	);	# These objects are global

# Parse options
if ("@ARGV" =~ /help/i) {
	die << "--H00";
$NAME: convert plain text to PostScript using a given BDF font
Script by Serge Winitzki, in public domain. Version $VERSION
Sample usage:	$NAME options ... < input.txt > output.ps
	cat fontfile.bdf input.txt | $NAME options ... > output.ps
Options: (the BDF file and the text file are required)
 -help	print this help message
 -bdf=BDFfile.bdf	use BDF file as text font (give full path if necessary)
 -text=textfile.txt	read given text file (ditto)
	default is to take BDF and/or text input from STDIN
	if taking both inputs from STDIN, the BDF file *must* go first
Formatting options:
 -justify	justify text, compress spaces between words (default not to)
 -nowrap	break lines exactly as in text and do not wrap any lines
	(default to wrap until paragraph ends: empty line, TAB, 4+ spaces)
	"-justify -nowrap" means no wrapping but leave only one space between words
	NB: with -nowrap, even lines that are too long will *not* be wrapped
	otherwise, any words that do not fit will be broken across lines
Size options: (all parameters are floating point values unless indicated)
 -fontsize=XXX	use given font size (default 12.0)
 -page=XXX	use given page size (default smallest of letter and A4)
	page may be "letter", "A4", or exact bounding box "XX,XX,XX,XX"
	e.g. "-page=letter" or "-page=0,0,612,792" (integers and no spaces!)
 -lineskip=XXX	set relative lineskip amount (default 1.1)
 -gap=XXX	insert additional horizontal space between letters in units of font size
	(default 0, XXX=1 means insert a gap "fontsize" points wide)
 -indent=XXX	set paragraph indent in units of fontsize (default 1.5)
 -tab=XXX	set tab expansion as the number of space chars (integer)
	default: same as the -indent value if given, or else 8
 -margin=XXX	set margin size relative to page size, for each margin
	(default 0.05)
Postscript options:
 -ascii85	use Postscript Level 2 encoding for more compact output (slower!)
 -allchars	include all font chars, not just those actually used in text (larger PS!)
--H00
# -pagenumber=<options> 	how to number pages, options can be top/bottom/left/right/even/odd/XXX (default not to)
}

$BDFfont{'gap'} = ("@ARGV" =~ /-gap=([.0-9]+)/i) ? $1 : 0;
$BDFfont{'ascii85'} = ("@ARGV" =~ /-ascii85/i) ? 1 : 0;
$PSoutput{'allchars'} = ("@ARGV" =~ /-allchars/i) ? 1 : 0;

$options{'justify'} = ("@ARGV" =~ /-justify/i) ? 1 : 0;
$options{'wrap'} = ("@ARGV" =~ /-nowrap/i) ? 0 : 1;
$options{'lineskip'} = ("@ARGV" =~ /-lineskip=([.0-9]+)/i) ? $1 : 1.1;
$options{'fontsize'} = ("@ARGV" =~ /-fontsize=([.0-9]+)/i) ? $1 : 12;
$options{'margin'} = ("@ARGV" =~ /-margin=([.0-9]+)/i) ? $1 : 0.05;
$options{'indent'} = ("@ARGV" =~ /-indent=([.0-9]+)/i) ? $1 : 1.5;
$options{'tab'} = ("@ARGV" =~ /-tab=([0-9]+)/i) ? int($1) : (("@ARGV" =~ /-indent=([.0-9]+)/i) ? int ($1) : 8);
$options{'numberpages'} = ("@ARGV" =~ /-pagenumber=(top|bottom)/i) ? $1 : 0;
$options{'page'} = "0,0,596,792";	 #default to common minimum of A4 and letter
if ("@ARGV" =~ /-page=([^ ]+)/i) {
	$options{'page'} = "$1";
	$options{'page'} =~ tr/[A-Z]/[a-z]/;
}
	# Open input files
$BDFinput = ("@ARGV" =~ /-bdf=([^ ]+)$/i or "@ARGV" =~ /-bdf=([^ ]+)\s/i) ? $1 : "";
$textfile = ("@ARGV" =~ /-text=([^ ]+)$/i or "@ARGV" =~ /-text=([^ ]+)\s/i) ? $1 : "";
if ($BDFinput ne "") {
	open(BDF, "$BDFinput") || die "Error: can't open '$BDFinput'.\n";
	$BDFinput = \*BDF;
} else {
	$BDFinput = \*STDIN;
}
if ($textfile ne "") {
	open(TEXT, "$textfile") || die "Error: can't open '$textfile'.\n";
	$textinput = \*TEXT;
} else {
	$textinput = \*STDIN;
	$textfile = "STDIN";
}

$options{'textinput'} = $textinput;
$options{'textfile'} = $textfile;

$PSoutput{'headers_printed'} = 0;	# Whether the headers are already printed to STDOUT
# Read the font
print STDERR "Reading BDF font...";

&bdf2ps3($BDFinput, \%BDFfont);

# Convert text to PS using options. This should create the PS object and STDERR diagnostics.
print STDERR "Generating PS output...";
&txt2ps(\%BDFfont);

# PSoutput object:
# PSheader, PSprolog, maintext, PSfooter: string
# The PS file should contain the prolog after the font definition

my $output = \*STDOUT;

&print_PSheader($output, \%BDFfont) unless ($PSoutput{'headers_printed'});	# The headers and the maintext may have been printed by txt2ps if we are in pipe mode

print $output $PSoutput{'maintext'}, $PSoutput{'PSfooter'};

exit;

#
# End of main
#

sub print_PSheader {
	my ($output, $font) = (@_);

	print $output $PSoutput{'PSheader'}, $$font{'PSheader'};
	for (my $i=0; $i<=$$font{'maxindex'}; ++$i) {
		print $output $$font{'chardefs'}[$i]
			if ($PSoutput{'charused'}[$i] or $PSoutput{'allchars'});
	}
	print $output $$font{'PSfooter'}, $PSoutput{'PSprolog'};
}

#
################################ bdf2ps3
#
sub bdf2ps3 {	# Arguments: BDF input stream, BDFfont object. Output: creates PS3 font and prints diagnostics to STDERR

# BDFfont object: data members only
#	fontwidth, fontsize:	integer, font dimensions in pixels
#	charwidths:	array of float, in pixels
#	fontname:	string, PS font name is PS3font_<fontname>
#	gap:	float, in original units
#	chardefs: array of string, PS strings that define each character
#	PSheader, PSfooter:	string, the font will be complete if we print PSheader, then some chardefs, then PSfooter

	my ($fontname, $bdffontsize, $fontwidth, $font_header, $hres, $vres, $h, $w, $swidthx, $swidthy, $dwidthx, $dwidthy, $units, $havecomments, $factor, $factor_x, $n, $bbx, $bby, $hexstring, $i);
	my ($input, $BDFfont)  = (@_);
	$$BDFfont{'charwidths'} = [];
	$$BDFfont{'chardefs'} = [];
	for ($i=0; $i<256; ++$i) {
		$$BDFfont{'charwidths'}[$i] = 0;
		$$BDFfont{'chardefs'}[$i] = "";
	}

	# PS name of the font: arbitrary but have to set it to something
	$$BDFfont{'fontname'} =  $fontname = "font";
	$$BDFfont{'gap'} = 0 unless (defined($$BDFfont{'gap'}));
	$$BDFfont{'ascii85'} = 0 unless (defined($$BDFfont{'ascii85'}));

	$units = 1000;	# Magic number setting the units scale (constant)

	$_ = <$input>;
	die "Input does not look like a BDF font.\n" unless (/^STARTFONT\s/);
	$font_header .= "%!FontType3-1.0\n% PS Type 3 font converted from BDF format by $NAME $VERSION\n";

	$havecomments = 0;
	while (<$input>) {
		if (/^SIZE\s(\d+)\s(\d+)\s(\d+)\s*$/) {
			$bdffontsize = $1; $hres = $2; $vres = $3;
	#		$factor=$units/$bdffontsize;	# Actually this would probably be wrong. Let's try to redo the bdffontsize when we have the BB
	#		$factor_x = $factor * $vres / $hres;
		} elsif (/^FONTBOUNDINGBOX\s(\d+)\s(\d+)\s([-0-9]+)\s([-0-9]+)\s*$/) {
		# 1=xsize, 2=ysize, 3=xpos, 4=ypos
#			if ($bdffontsize != $2) {
#				print STDERR "Warning: font size $bdffontsize does not agree with font bounding box\n";	# Spurious message: it almost never agrees
#			}
			$fontwidth = $1;
			$bdffontsize = $2;	# For now, take the bounding box as font size
			$factor = $units/$bdffontsize;
			$factor_x = $factor * $vres / $hres;
			$font_header .= sprintf "/FontBBox [%d %d %d %d] def\n", $3*$factor_x, $4*$factor, ($3+$1)*$factor_x, ($4+$2)*$factor;
			$font_header .= sprintf "/scaleX {%4.3f mul} bind def /scaleY {%4.3f mul} bind def /gap %4.1f def\n", $factor_x, $factor, $$BDFfont{'gap'}*$units;
		} elsif (/^CHARS\s(\d+)\s*$/) {
			$font_header .= "% $1 characters in original font\n";
			$$BDFfont{'chars'} = $1;
		} elsif (/^FONT\s(.*)$/) {
			$font_header .= "% BDF font name: $1\n";
		} elsif (/^COMMENT\s(.*)$/) {
			if (not $havecomments) {
				$font_header .= "% original BDF font comments:\n";
				$havecomments = 1;
			}
			$font_header .= "%\t$1\n";
		} elsif (/^ENCODING\s(\d+)$/) {
			$n = $1;	# Character code of current char
		} elsif (/^ENDFONT/) {
			last;
		} elsif (/^SWIDTH\s(\d+)\s(\d+)\s*$/) {
			$swidthx = $1;
			$swidthy = $2;
			print STDERR "Warning: char $n has nonzero SWIDTH_Y\n" if ($swidthy != 0);
		} elsif (/^DWIDTH\s(\d+)\s(\d+)\s*$/) {
			$dwidthx = $1;
			$dwidthy = $2;
			print STDERR "Warning: char $n has nonzero DWIDTH_Y\n" if ($dwidthy != 0);
#			print STDERR "Warning: char $n has unmatching SWIDTH_X and DWIDTH_X\n" if ($dwidthx*$factor_x != $swidthx); # This should be recalculated using PIXEL_SIZE of the font which we don't care about
		} elsif (/^BBX\s(\d+)\s(\d+)\s([-0-9]+)\s([-0-9]+)\s*$/) {
			$w = $1;
			$h = $2;
			$bbx = $3;
			$bby = $4;
		} elsif (/^BITMAP/) {
			# Read the bitmap and maybe convert it to ASCII85
			$hexstring = "";
			for ($i=0; $i<$h; ++$i) {
				$hexstring .= <$input>;
				$hexstring =~ s/\n$//;
			}
			if ($$BDFfont{'ascii85'}) {	# ASCII85 encoding: b1 b2 b3 b4 -> a1 a2 a3 a4 a5 (base 85) , each char + 33, !!!!!->z, last chars: pad by 0's and output 1 more bytes than in the last tuple
				my ($a85, $r, $divisor, $pad, $i) = ("", 0, 0, 0, 0);
				$pad = int((length($hexstring)+1)/2) % 4 + 1;
				$pad = 5 if ($pad == 1);	# Number of bytes in the last pentuple
				$hexstring .= "0" x ((8-length($hexstring)%8)%8);
				for (my $i=0; $i < length($hexstring); $i+=8) {
					$r = unpack("N",pack("H*", substr($hexstring, $i, 8)));
					if ($r == 0 and ($i+8 < length($hexstring) or $pad == 5)) {
						$a85 .= "z";	# special case
					} else {
						for ($divisor=85*85*85*85; $divisor >= 1 and $pad > 0; $divisor /= 85) {
							$a85 .= pack("C", 33+int($r / $divisor));
							$r = $r % $divisor;
							--$pad unless ($i+8 < length($hexstring) or $pad == 5);
						}
					}
				}
				$hexstring = "~$a85~";
			}
			# Special processing for empty chars
			if ($w == 0 or $h == 0 or $hexstring eq "") {
				$hexstring = "00";
				$w = 1;
				$h = 1;
			}
			$$BDFfont{'chardefs'}[$n] = "$n /char$n $dwidthx [$w $h $bbx $bby] <$hexstring> B\n";
			$$BDFfont{'charwidths'}[$n] = $dwidthx + $$BDFfont{'gap'} * $bdffontsize;	# At this point @charwidths are widths in pixels
			$$BDFfont{'fontwidth'} = $fontwidth;
			$$BDFfont{'fontsize'} = $bdffontsize;
		}
	}

	# Assign all values to the BDFfont object
	$$BDFfont{'arraysize'} = $n + 1;
	$$BDFfont{'maxindex'} = $n;
	$$BDFfont{'PSheader'} = << "--E1" . $font_header;
/PS3$fontname 15 dict def
PS3$fontname begin
/FontType 3 def
/FontMatrix [.001 0 0 .001 0 0] def
/Encoding $$BDFfont{'arraysize'} array def
0 1 $$BDFfont{'maxindex'} { Encoding exch /.notdef put } for
/char_bb $$BDFfont{'arraysize'} array def
/char_width char_bb $$BDFfont{'arraysize'} array copy def
/char_bitmaps char_bb $$BDFfont{'arraysize'} array copy def
/B {
 char_bitmaps exch 5 index exch put
 char_bb exch 4 index exch put
 char_width exch 3 index exch put
 Encoding exch 2 index exch put
 pop
} bind def
/BuildChar {
 /ind exch dup 128 ge {
  fontpage 128 mul add
 } if def
 begin
  Encoding ind get /.notdef ne {
   char_width ind get scaleX gap add 0
   char_bb ind get
   dup 2 get scaleX
   exch dup 3 get scaleY
   exch dup 0 get 1 index 2 get add scaleX
   exch dup 1 get 1 index 3 get add scaleY
   exch pop
   setcachedevice
   char_bb ind get aload pop
   scaleY exch scaleX exch translate
   1 index scaleX 1 index scaleY scale
   true 2 index 0 0 4 index dup neg exch 0 exch 6 array astore
   char_bitmaps ind get 1 array astore cvx imagemask
  } if
 end
% currentdict /ind undef
} bind def
--E1

# Between header and footer we'll insert some invocations of the procedure "B" that builds glyphs

	$$BDFfont{'PSfooter'} = << "--E2";
end
/PS3font_$fontname PS3$fontname definefont pop
/F$fontname {/PS3font_$fontname findfont exch scalefont setfont } bind def
/f {/fontpage exch def} bind def 0 f
--E2

print STDERR " done.\n";

}

#
################################ txt2ps
#
sub txt2ps {
	my ($textinput, $margin, $page, $fontsize, $fontname);
	my ($pageBBx1, $pageBBx2, $pageBBy1, $pageBBy2, $page_header, $page_trailer, $total_pages, $bdffontsize, $fontwidth, @charwidths, @buffer, %curpage, $tabindents, $spaceindents);
	
	# Convenience variables
	$page = $options{'page'};
	$margin = $options{'margin'};
	$fontsize = $options{'fontsize'};
	$textinput = $options{'textinput'};
	$fontname = $BDFfont{'fontname'};
	# Compute effective bounding box for the page: first, the nominal BBox w/o margins
	($pageBBx1, $pageBBy1, $pageBBx2, $pageBBy2)
		= ("$page" eq "a4") ? (0, 0, 596, 843)
		: (("$page" eq "letter") ? (0, 0, 612, 792)
		: (($page =~ /(\d+),(\d+),(\d+),(\d+)/) ? ($1, $2, $3, $4) : (0, 0, 596, 792)));

	# Compute date
	$curpage{'date'} = gmtime;
	$PSoutput{'PSheader'} = <<"--H11";
%!PS-Adobe-2.0
%%Creator: $NAME version $VERSION, written by Serge Winitzki
%%Title: Document converted from "$options{'textfile'}"
%%Options_$NAME: "@ARGV"
%%CreationDate: $curpage{'date'} (GMT)
%%Pages: (atend)
%%BoundingBox: $pageBBx1 $pageBBy1 $pageBBx2 $pageBBy2
%%PageOrder: Ascend
%%Orientation: Portrait
--H11

	# Account for margin
	($pageBBx1, $pageBBy1, $pageBBx2, $pageBBy2) = (
		int(0.5+$pageBBx1+($pageBBx2-$pageBBx1)*$margin),
		int(0.5+$pageBBy1+($pageBBy2-$pageBBy1)*$margin),
		int(0.5+$pageBBx2-($pageBBx2-$pageBBx1)*$margin),
		int(0.5+$pageBBy2-($pageBBy2-$pageBBy1)*$margin)
	);
	$curpage{'total_width'} = $pageBBx2-$pageBBx1;
	$curpage{'total_height'} = $pageBBy2-$pageBBy1;
	# Compute lineskip and indent
	# maybe adjust lineskip a little in case we have uneven number of lines per page?
	$curpage{'ls'} = $options{'lineskip'}*$fontsize;
	#Compute real width of one indent
	$curpage{'indent'} = $options{'indent'} * $fontsize;

	# Some PS definitions
	$PSoutput{'newline'} = "n";
	$PSoutput{'show'} = "s";
	$PSoutput{'show_and_newline'} = "$PSoutput{'show'} $PSoutput{'newline'}";
	$PSoutput{'justify_and_newline'} = "e";

	$PSoutput{'PSheader'} .=  << "--H12";
%%MinBoundingBox: $pageBBx1 $pageBBy1 $pageBBx2 $pageBBy2
%%EndComments
%%BeginProlog
/TxtPSDict 20 dict def TxtPSDict begin
/x0 $pageBBx1 def /y0 $pageBBy2 def /lineskip $curpage{'ls'} def
/$PSoutput{'newline'} {x0 currentpoint exch pop lineskip sub moveto} bind def
/i {$curpage{'indent'} mul currentpoint pop add currentpoint exch pop moveto} bind def
/$PSoutput{'show'} {show} bind def /P {x0 y0 lineskip sub moveto} bind def
/$PSoutput{'justify_and_newline'} {exch 256 div exch 0 exch 32 exch widthshow $PSoutput{'newline'}} bind def
--H12

	$PSoutput{'PSprolog'} = << "--H13";
$fontsize F$fontname
end
%%EndProlog
%%BeginSetup
TxtPSDict begin
%%EndSetup
--H13

# PS things we don't need right now
#/b {bind def} bind def /M {x y moveto} b
#/h {currentpoint pop add /x exch def M} b
#/I {$indent h} b

	# The charwidths in the font are in pixels, have to get them in points
	$bdffontsize = $BDFfont{'fontsize'};
	$fontwidth = $BDFfont{'fontwidth'};
	for (my $i = 0; $i < $BDFfont{'arraysize'}; ++$i) {
		$charwidths[$i] = $BDFfont{'charwidths'}[$i] * $fontsize / $bdffontsize if (defined($BDFfont{'charwidths'}[$i]));
	}

	# Read textinput and convert it to PS

	$curpage{'pageno'} = 1;
	@buffer = ();
	&start_page(\%curpage);
	$tabindents = 0;
	$spaceindents = 0 ;
	while(<$textinput>) {
		s/[ \t]*\x0D?\n$//;	# Trim trailing spaces or tabs and trailing newline
		s/\x0D$//;	# bare DOS newlines?
		# We have really three options: either perform no wrapping, or perform wrapping and either justify or not. The combination of options "-nowrap -nojustify" means that we are keeping even double spaces between words and replacing TAB characters with some spaces, and doing no wrap.
		# If justifying, we need to insert least the width of the space character between words.
		# If we are doing no wrap, we don't need to word split and @buffer will always be empty
		# The next-line semantics is that at any time the page state is such that we can write the current line.
		if (
			($_ eq "" or /^\t+/ or /^ {4,}/ or /^\x0C/)	# previous paragraph ended if there is an empty line, an initial TAB or initial 4 or more spaces, or \x0C
			and $#buffer != -1) {	# Need to dump the buffer
			&dump_buffer(\@buffer, \%curpage, \%options, $tabindents, $spaceindents, \@charwidths);
#			$tabindents = 0;
#			$spaceindents = 0 ;
		}
		if ($_ eq "") {	# Insert lineskip
			&output($PSoutput{'newline'} . "\n");
			&next_line(\%curpage);
			next;
		} elsif (/^\x0C/) {	# Special action: start new page
			&next_page(\%curpage);
			$_ =~ s/^\x0C//;
			next if (/^\s*$/);	# If there is something other than space characters on the line, continue
		}
		# If the line starts with some TABs and then some spaces, we want to indent it that many times
		if (not $options{'wrap'}) {
			$tabindents = 0;
			$spaceindents = 0 ;
		}
		if ($_ =~ /^(\t\t*)( *)(.*)$/) {
			$tabindents = length($1);
			$spaceindents = length($2);
			$_ = $3;	# Line without initial tabs and spaces
		} elsif ($_ =~ /^(  *)(.*)$/) {	# Indent by spaces only
			$tabindents = 0;
			$spaceindents = length($1);
			$_ = $2;
		}
		if ($options{'wrap'}) {
			push(@buffer, (split(/[ \t]+/)));	 # Buffer will be emptied later
		} else {	# No wrap, so plain simple line by line output
			if ($options{'justify'}) {	# Special option combination: nojustify + nowrap means obeylines and obeyspaces. Otherwise we compress all intermediate spaces into one:
				s/[ \t]+/ /g;
			}
			# Replace TAB characters with spaces
			s/(\t\t*)/{" " x (length($1)*$options{'tab'});}/eg;
			# Compute line length
			$PSoutput{'fit'} = 0 if (&wordwidth($_, \@charwidths) + $charwidths[32] * $spaceindents + $tabindents * $curpage{'indent'} > $curpage{'total_width'});
			# Insert initial indents
			$_ = (($tabindents != 0) ? "$tabindents i " : "") . "(" . " " x $spaceindents . &escape_chars($_) . ")" . $PSoutput{'show_and_newline'} . "\n";
			
			&output($_);
			&next_line(\%curpage);
		}
	}	# End of reading $textinput
	&dump_buffer(\@buffer, \%curpage, \%options, $tabindents, $spaceindents, \@charwidths) if ($#buffer != -1);
	&finish_page(\%curpage);

	print STDERR "\nOutput $curpage{'pageno'} page" . (($curpage{'pageno'} > 1) ? "s" : "") . ".\n";
	print STDERR "Warning: some lines did not fit on pages.\n" if (defined($PSoutput{'fit'} and $PSoutput{'fit'} == 0));
	print STDERR "Warning: some characters used in text were not present in font.\n" if (defined($PSoutput{'absentchars'} and $PSoutput{'absentchars'}));
	$PSoutput{'PSfooter'} = <<"--H2";
%%Trailer
end
%%DocumentFonts: Helvetica PS3$fontname
%%Pages: $curpage{'pageno'}
%%EOF
--H2

}	# End of txt2ps subroutine

sub escape_chars {
	my ($text) = (@_);
	# Escape parentheses and other special chars within the line
	$text =~ s/([\\\(\)\%])/\\$1/g;
	$text =~ s/([\x00-\x1F\x7F])/{sprintf("\\%03o",unpack("C",$1));}/eg;
	$text;
}

sub next_page {
	my ($curpage) = (@_);
	&finish_page($curpage);
	++$$curpage{'pageno'};
	&start_page($curpage);
}

sub next_line {
	my ($curpage) = (@_);
	if (($$curpage{'y'} -= $$curpage{'ls'}) < 0) {	# Next page
		&next_page($curpage);
	}
}

sub start_page {
	my ($curpage) = (@_);
	my $pageno = $$curpage{'pageno'};
	$$curpage{'y'} = $$curpage{'total_height'} - $$curpage{'ls'};
	my $text = << "--H3";
%%Page: $pageno $pageno
P
--H3
	&output($text);
}
sub finish_page {
	my ($curpage) = (@_);
	my $pageno = $$curpage{'pageno'};
	my $text = << "--H4";
showpage
%%EndPage: $pageno $pageno
--H4
	&output($text);
	print STDERR " [$pageno]";
}

sub dump_buffer {	# Complete wrapping of the buffer, possible new line/new page, buffer must be empty and we must be on the next writeable line afterwards
	# Handle cases where the lines are justified, indented, and when words are too wide (break them forcibly across lines)
	# Problem: need explicit coordinates for justified text! Will make output much larger! Get PS current pos.? "currentpoint" -> x y
	my ($buffer, $curpage, $options, $tabindents, $spaceindents, $charwidths) = (@_);
#	print STDERR "dump_buffer called with spaceindents=$spaceindents and tabindents=$tabindents\n";
	my ($spaceleft, $line, $nspaces, $word, $length);
	$spaceleft = $$curpage{'total_width'};
	$line = "";
	# Take care of possible initial indents
	if ($tabindents != 0 or $spaceindents != 0) {
		&output("$tabindents i ") if ($tabindents != 0);
		&output("(" . " " x $spaceindents . ")" . $PSoutput{'show'} . " ") if ($spaceindents != 0);	# Just print the indent by itself
		$spaceleft -= $$charwidths[32]*$spaceindents + $tabindents * $$curpage{'indent'};
	}
	$nspaces = 0;	# Number of spaces *between words* that are present in $line

	foreach $word (@$buffer) {	# Invariant: everything before the line containing $word is already printed, and what is not yet printed is in $line. There is no trailing space in $line
#		print STDERR "processing '$word'\n";	# Debugging
		$length = &wordwidth($word . " ", $charwidths);
		if ($length > $spaceleft) {	# Need to check whether we can wrap, i.e. whether $line already has some words. If yes, we will print them and continue. If not, we'll have to break the current word (it's too wide)
			if ($line ne "") {	# Have stuff to print before this word
				$line = &escape_chars($line);
				if ($$options{'justify'} and $nspaces != 0) {
					&output(sprintf ("%d ", int($spaceleft*256/$nspaces))) if ($nspaces != 0);
					&output("(" . $line . ")" . $PSoutput{'justify_and_newline'} . "\n");
				} else {
					&output("(" . $line . ")" . $PSoutput{'show_and_newline'} . "\n");
				}
				&next_line($curpage);
				# Now take care of this word itself
				$line = "";
				$spaceleft = $$curpage{'total_width'};
			}
			#May not fit this word on one line and then we'll cut it until we can fit it.
			$length = &wordwidth($word, $charwidths);
			while ($length > $spaceleft) {
				$length = &cutword($word, $spaceleft, $charwidths);	# Find string position at which we'll cut
				&output("(" . &escape_chars(substr($word, 0, $length)) . ")" . $PSoutput{'show_and_newline'} . "\n");
				&next_line($curpage);
				$word = substr($word, $length, length($word)-$length);
				$length = &wordwidth($word, $charwidths);
				$spaceleft = $$curpage{'total_width'};
			}	# Everything up to (this piece of) the original word is printed
			$spaceleft -= $length;
			$line = $word;
			$nspaces = 0;
		} else {	# Still have some space left, don't wrap it yet
			if ($line ne "") {	# The very first word
				$line .= " ";
				++$nspaces;
			} else {
				$spaceleft += $$charwidths[32];
			}
			$spaceleft -= $length;
			$line .= $word;
		}
	}
	if ($line ne "") {	# Print the final part of the line, never justify
		&output("(" . &escape_chars($line) . ")" . $PSoutput{'show_and_newline'} . "\n");
		&next_line($curpage);
	}
	$line = "";
	@$buffer = ();
}

sub wordwidth {	# Return width of a word
	my ($word, $charwidths) = (@_);
	my ($i, $width, $index) = (0, 0, 0);
	for (; $i < length($word); ++$i) {
		$index = unpack("C",substr($word,$i,1));
		$width += $$charwidths[$index];
		$PSoutput{'charused'}[$index] = 1;
		$PSoutput{'absentchars'} = 1 if ($BDFfont{'chardefs'}[$index] eq "");
	}
	$width;
}

sub cutword {	# Return length of the longest part of the word that can fit
	my ($word, $spaceleft, $charwidths) = (@_);
	my ($i, $width, $index) = (0, 0, 0);
	for (; $i < length($word); ++$i) {
		$index = unpack("C",substr($word,$i,1));
		$width += $$charwidths[$index];
		last if ($width > $spaceleft);
	}
	$i;
}

sub output {	# Print text into PSoutput
	my ($text) = (@_);	# Check if we are in pipe mode, then print immediately to $output, and also check if headers need to be printed.
	$PSoutput{'maintext'} .= $text;
}
