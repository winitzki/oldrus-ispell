# Makefile for Russian ispell dictionary
# Changes by Serge Winitzki for old Russian orthography. 2001-2002.

# Usage:
# "make", "make dict" - compile dictionary with default options (no Yo)
# "make help" - print supported targets and variables
# "make CP1251=1" - compile dictionary in modified CP1251 encoding
# "make YO=1" - compile with the letter Yo
# "make YOYE=1" - compile with the letter Yo aliased to Ye
# "make NOFITA=1" - replace Fita with F
# "make NOER=1" - omit trailing Er
# "make IZHITSA=1" - require Izhitsa spellings (default is to make it optional)
# "make LOWMEM=1" - for targets "dist", "dict" and "unpack", use much less memory (but slower)
# "make install" - install in /usr/lib/ispell
# "make sort" - sort dictionaries (in place)
# "make unpack" - unpack and patch rus-ispell to oldrus-ispell
# "make clean" - remove temporary files
# "make dist" - prepare distribution
# "make hugelist" - make a big file listing all word forms
# "make hugesplit" - make a list of words split into small files for the online converter
# "make hugelistA.koi" - make a special dictionary for text_new2old.pl
# "make check_dup" - print a list of duplicates to the file "check_dup" (i.e. identical words that have different flags)
# "make check_redundant" - print a list of redundant forms to file "check_redundant" (i.e. words w/o flags that are already generated by other words with flags)
# "make new-rus" - generate a new orthography dictionary in directory "new-rus"; run "make" in that directory to build
# "make new-rus" - find words missing from the new orthography dictionary in directory "new-rus" but present in the original rus-ispell
# "make deb" - make binary Debian package "irussian-old"
# "make text_n2o.exe" - update the "text_n2o.exe" DOS package
# "make distcheck" - check that the distribution tar.gz file unpacks correctly

# Package name and current version
NAME = oldrus-ispell
VERSION = 0.99f7p16

# the variable $(ARCH) is only used to make a Debian package.
#ARCH = `uname -m`	# Not sure how to deal with i586->i386 - please replace if you need it!
ARCH = i386

# some more names for Debian
# note that this will be replaced by irussian-new when doing "make new-rus"
DEBNAME = irussian-old
DEBIANPACKAGE = $(DEBNAME)_$(VERSION)-1_$(ARCH).deb

# Installation directory
LIB=/usr/lib/ispell

# This directory must contain the original rus-ispell distribution (or make a symlink)
ORIGDIR = ./rus-ispell-orig
# presense of this file means that we are unpacked
UNPACKED = .unpacked

# temporary dir name
DISTDIR = ./$(NAME)-$(VERSION)

# name of the large dictionary
BASEDICT = base.koi
# names of dictionaries in rus-ispell
OLDDICTS = abbrev.koi computer.koi for_name.koi geography.koi science.koi rare.koi
# names of dictionaries not in rus-ispell
NEWDICTS = church.koi names.koi counted.koi

DICTS = $(BASEDICT) $(OLDDICTS) $(NEWDICTS)
ORIGDICTS = $(ORIGDIR)/$(BASEDICT) $(ORIGDIR)/computer.koi $(ORIGDIR)/geography.koi $(ORIGDIR)/science.koi $(ORIGDIR)/rare.koi

# doc files
READMES = README.en README.ru README.affix.ru README.unpack CHANGELOG.en CHANGELOG.ru TODO htmluni.pl.README
SORTFILE = ./sortkoi8c
SORT = sh $(SORTFILE)
# do not use slowsort
# SLOWSORT = perl sortkoi8c.pl -with-yer
KOI8C2CP1251FILE = ./koi8c2cp1251.sh
KOI8C2CP1251 = sh $(KOI8C2CP1251FILE)
AFF = oldrussian.aff.koi
FINALAFF = oldrussian.aff
FINALDICT = finaldict.koi
OLD2NEW = old2new.sh
# directory for the generated new-rus package
NRIDIR = new-rus

# scripts
PROGS = affixize applyflags.pl $(KOI8C2CP1251FILE) mkflags.pl check_LQR.pl check_dup.pl check_redundant.sh lookupflags.pl rmflagsCD.pl dict-diff.pl dict-diff-lowmem.pl dict-diff.sh dict-patch.sh esq excludelines.pl make-orpatch.sh make-orunpack.sh mkcounted.pl mergeflags.pl mkhugeidx.pl $(OLD2NEW) rus_old2new.pl rus_new2old.pl showaffix $(SORTFILE) sortkoi8c.pl text_new2old.pl update-dicts.sh updateflags.pl htmluni.pl insert-words.pl

# other files necessary at build time
OTHERFILES = Makefile $(PROGS) redundant.koi dup.koi $(READMES) counted.idx
OTHERDIRS = DEBIAN

TMPDICT = dict.koi
FINALHASH = oldrussian.hash

DISTROFILE = $(NAME)-$(VERSION).tar.gz
# Dictionary index file for hugesplit
DICTIND = oldrus_index.txt

# various options
# these variables indicate the affix patterns to be retained, e.g. #y or #e patterns
# we need two variables since maybe both will be retained
PATT=undefined
PATT2=undefined

# Support for Yo spellings
ifdef YO
PATT=y
YO2E=
else
PATT=e
YO2E=| tr '\243\263' '\305\345'
endif

# Support for both Yo and Ye spellings
ifdef YOYE
PATT=e
PATT2=y
YO2E=| perl -pe 'if (/[��]/) {$$line=$$_; $$line =~ tr/��/��/; print $$line;}'
endif

# Optionally remove support for FITA spellings
ifdef NOFITA
FITA2F=| tr '\254\274' '\306\346'
else
FITA2F=
endif

# Optionally include mandatory requirement to use IZHITSA spellings
ifdef IZHITSA
IZH=
else
# Default is to allow but not require IZHITSA spellings
IZH=| perl -pe 'if (/[��]/) {$$line=$$_; $$line =~ tr/��/��/; print $$line;}'
endif

# Optionally compile dictionary in modified CP1251 encoding
ifdef CP1251
ENC=1251
RECODE=| $(KOI8C2CP1251)
else
ENC=koi
RECODE=
endif

# Compress dictionary by adding flag C
MKFLAGS=| perl mkflags.pl CD
# Optionally remove trailing YER from dictionary and affix file
# Remove trailing YER from affix file and/or dictionary
ADDYERSCRIPT=| perl -e 'while(<>){s/([^�Ţ�ɦ����������岳����������])([ \t.,\/\#])/\1�\2/g;s/([^�Ţ�ɦ�����������岳鶱���������])$$/$$1�/;print;}'
RMYERSCRIPT=| perl -e 'while(<>){s/[��]([ \t.,\/\#�ɦ������鶱����])/$$1/g;s/[��]$$//;print;}'
# Clean up some affix rules corrupted after removing YER
CLNYERAFF=| perl -e 'while(<>){s/-,//;s/,\t/,-/;print unless (/^\s*$$/);}'
# Remove comments from affix file
RMAFFCOMM=| sed -e 's/\#.*$$//'
# Remove old orthography affix rules and replace words
RMOLDRUS=| sed -e 's/�/�/;y/������/������/;s/^\#o.*$$//;s/^\#r.*$$//;s/���/���/;s/�����/�����/;s/��� /��� /;s/���$$/���$$/;s/��/��/;'

# Optionally remove trailing YER
YERPATT=noer
ifdef NOER
ERPATT=$(YERPATT)
REMYER=$(RMYERSCRIPT)
else
ERPATT=r
REMYER=
endif

# Comments "#o" indicate rules in affix file specific for old orthography
USEOLD=o

# Flag to use less memory
ifdef LOWMEM
LOWMEMFLAG=-lowmem
else
LOWMEMFLAG=
endif

help:
	@echo
	@echo "This is the Make script for package '$(NAME)-$(VERSION)' on $(ARCH)"
	@echo "Usage: make [option] ... target ..."
	@echo "Targets: unpack dict install dist deb check_dict sort clean update"
	@echo "  check_dup check_redundant distcheck new-rus check_new-rus hugelist"
	@echo "Options: YO=1 YOYE=1 IZHITSA=1 NOFITA=1 NOER=1 CP1251=1 LOWMEM=1"
	@echo
	@echo "Example: 'make YOYE=1 CP1251=1 dict dict.ez2 hugelist'"
	@echo

dict:	$(FINALHASH) Makefile

# $(DICTS) and $(ORIGDIR)/* are primary files, all others are generated

unpack:	$(UNPACKED)

# "counted words": generated dictionary
counted.koi: mkcounted.pl counted.idx
	@perl mkcounted.pl -old -dict=counted.idx | $(SORT) | uniq > $@

$(FINALHASH):	$(FINALDICT)
	@echo -n "Building dictionary hash..."
	@buildhash -s ./$(FINALDICT) ./$(FINALAFF) ./$(FINALHASH)
	@echo " done."

ifdef LOWMEM
$(FINALDICT):	$(TMPDICT) $(FINALAFF)
	@echo "Not optimizing the dictionary..."
	@cp $(TMPDICT) $(FINALDICT)
else
$(FINALDICT):	$(TMPDICT) $(FINALAFF) check_redundant
	@echo "Optimizing dictionary..."
	@perl ./excludelines.pl check_redundant < $(TMPDICT) $(MKFLAGS) | $(SORT) > $(FINALDICT)
endif

# Note: do not $(RECODE) here!
check_redundant:	$(TMPDICT) $(FINALAFF)
	@echo "Generating list of redundant words..."
	@sh ./check_redundant.sh $(TMPDICT) $(FINALAFF) | $(SORT) | uniq > check_redundant
	@echo "The list of redundant words is in the file 'check_redundant'."

$(TMPDICT):	$(DICTS)
	@echo -n "Preparing wordlist..."
	@cat $(DICTS) $(IZH) $(YO2E) $(FITA2F) $(REMYER) $(RECODE) | $(SORT) > $(TMPDICT)
	@echo " done."

# Make oldrussian.aff from oldrussian.aff.koi by replacing Yo and Yer (if needed), and removing comments. Fita is not explicitly mentioned in the affix file.
# Note: careful handling of replacement strings with empty parts, i.e. ",-" and "-,"
$(FINALAFF):	$(AFF)
	@echo -n "Preparing affix file..."
	@sed -e "s/^\#$(USEOLD)//;s/^\#$(ENC)/wordchars/;s/^\#$(PATT)//;s/^\#$(PATT2)//;s/^\#$(ERPATT)//;" $< $(REMYER) $(RMAFFCOMM) $(CLNYERAFF) | uniq $(RECODE) > $(FINALAFF)
	@echo " done."

install:	dict
	cp $(FINALHASH) $(FINALAFF) $(LIB)

check_dict:	$(DICTS)
	for i in `cat $(DICTS) | sed 's,/.*$$,,' | sort | uniq -d`; do \
		grep "^$$i/\|^$$i$$" $(DICTS); \
	done > .temp

# Sort all dictionaries
sort:	.sorted
.sorted:	$(DICTS)
	for i in $(DICTS); do \
		cat $$i | $(SORT) | uniq > $$i.temp; \
		mv -f $$i.temp $$i; \
	done
	touch .sorted

clean:
	@echo "Deleting generated files."
	@rm -rf $(TMPDICT) $(TMPDICT).cnt $(TMPDICT).stat $(FINALHASH) $(FINALDICT) $(FINALDICT).cnt $(FINALDICT).stat $(FINALAFF) .temp *.tmpra $(DISTDIR) $(DISTROFILE) dict_* hugelist* check_redundant $(NRIDIR) $(DEBIANPACKAGE) dict.ez2 text_n2o.exe check_dup check_new-rus $(DICTIND) counted.koi *.flags *.esq sums.md5 VERSION-*
	@cd $(ORIGDIR); rm -rf $(BASEDICT).esq; make clean

# This target makes a patch against rus-ispell. Need to have the files $(ORIGDICTS) in $(ORIGDIR)

dist:	sort $(DISTROFILE)

$(DISTROFILE):	$(AFF) $(DICTS) $(ORIGDICTS) $(OTHERFILES)
	@echo "Preparing to make the distribution..."
	@test -r $(ORIGDIR)/$(BASEDICT).esq || \
	perl esq < $(ORIGDIR)/$(BASEDICT) > $(ORIGDIR)/$(BASEDICT).esq
	@rm -rf $(DISTDIR)
	@mkdir -p $(DISTDIR)
	@sh make-orpatch.sh $(ORIGDIR) $(DISTDIR) $(LOWMEMFLAG)
	@cp $(NEWDICTS) $(AFF) $(OTHERFILES) $(DISTDIR)
	@rm $(DISTDIR)/counted.koi
	@for dir in $(OTHERDIRS) $(ORIGDIR); do \
		cp -r "$$dir" $(DISTDIR); \
		rm -rf $(DISTDIR)/"$$dir"/CVS; \
	done
	@rm $(DISTDIR)/$(ORIGDIR)/$(BASEDICT)
	@md5sum $(DICTS) > $(DISTDIR)/sums.md5
	@cp $(DISTDIR)/*.flags $(DISTDIR)/*.esq $(DISTDIR)/sums.md5 .
	@tar -cf - $(DISTDIR) | gzip -9 > $(DISTROFILE) && \
	rm -rf $(DISTDIR)
	@echo "Created distribution file '$(DISTROFILE)'."

# This unpacks the patch distribution using existing rus-ispell files
$(UNPACKED): $(NEWDICTS)
	@echo "Patching rus-ispell files from '$(ORIGDIR)'..."
	@test -r $(ORIGDIR)/$(BASEDICT) || \
	perl esq -d < $(ORIGDIR)/$(BASEDICT).esq > $(ORIGDIR)/$(BASEDICT)
	@sh make-orunpack.sh $(ORIGDIR) $(LOWMEMFLAG)
	touch VERSION-$(VERSION)
	@chmod 755 $(PROGS)
	@touch $(UNPACKED)
	@md5sum -c sums.md5 || echo "Warning: md5 sums do not match."
	@echo "All done. Run 'make dict && make install' now (as root)"
	@echo "to compile and install the dictionaries."

distcheck: dist
	tar zxf $(DISTROFILE)
	cd $(DISTDIR); make unpack

# Make a list of all word forms
hugelist:	hugelist.koi
hugelist.koi:	dict
	cat $(FINALDICT) | ispell -e -d ./$(FINALHASH) | tr " " "\n" | $(SORT) | uniq > hugelist.koi

# Prepare lists for text_new2old.pl. Forms -�� of adjectives are marked by A
hugelistA.koi:	dict
	grep /A $(FINALDICT) | ispell -e -d ./$(FINALHASH) | tr " " "\n" | sed -e 's/\(��\)$$/\1 A/;' > hugelistA.tmp.koi
	echo >> hugelistA.tmp.koi
	grep -v /A $(FINALDICT) | ispell -e -d ./$(FINALHASH) | tr " " "\n" | cat - hugelistA.tmp.koi | $(SORT) | uniq  | tee hugelistA.koi | perl mkhugeidx.pl -length=2048 > hugelistA.idx
	rm hugelistA.tmp.koi

# Prepare list of all word forms split into pieces of 2048 lines each; index contains file names and first words in each file
# This is only used by the online orthography converter
hugesplit:	hugelist
	rm -f $(DICTIND); touch $(DICTIND)
	cat hugelist.koi | perl -e \
	'$$maxlines=2048; open(FI,">$(DICTIND)"); $$n=0; $$l=0; while(<>) { if($$l==0) { $$l=$$maxlines; ++$$n; close(F); $$fn=sprintf("dict_%03d.txt",$$n); open(F,">$$fn"); print FI "$$fn\t$$_";} print F; --$$l; } close(F); close(FI);'

# Print a list of duplicate words that have different flags
check_dup:	$(TMPDICT)
	@cat $(TMPDICT) | perl ./check_dup.pl > check_dup
	@echo "List of duplicate words is prepared in file 'check_dup'"

# Generate new orthography dictionary
new-rus:	$(DICTS) $(OLD2NEW)
	@echo "Preparing new orthography dictionary..."
	@sh $(OLD2NEW) $(NRIDIR)
	@cp $(PROGS) $(READMES) $(NRIDIR)
	@cp -r $(OTHERDIRS) $(NRIDIR)
	@cd $(NRIDIR); ln -s ../$(ORIGDIR) .; cd ..
	@sed -e 's/oldrussian/russian/' < DEBIAN/postinst > $(NRIDIR)/DEBIAN/postinst
	@sed -e 's/oldrussian/russian/' < DEBIAN/prerm > $(NRIDIR)/DEBIAN/prerm
	@cp DEBIAN/control.new-rus $(NRIDIR)/DEBIAN/control
	@cp DEBIAN/README.Debian.new-rus $(NRIDIR)/DEBIAN/README.Debian
	@sed -e 's/FINALAFF = oldrussian.aff/FINALAFF = russian.aff/; s/= oldrussian.hash/= russian.hash/; s/irussian-old/irussian-new/; s/mkcounted.pl -old/mkcounted.pl -new/;' < Makefile > $(NRIDIR)/Makefile
	@echo "This dictionary is for new orthography as generated from $(NAME)-$(VERSION)" > $(NRIDIR)/README
	@touch $(NRIDIR)/$(UNPACKED)
	@echo "New orthography dictionary prepared in directory '$(NRIDIR)'"

# Find words from rus-ispell that are not in new-rus dictionary
check_new-rus:	$(DICTS) $(OLD2NEW) new-rus
	cd $(ORIGDIR); rm -f russian.dict.koi; make YO=1 russian.dict.koi
	cd $(NRIDIR); rm -f dict.koi; make YO=1 dict
	sed -e 's,/.*$$,,' < $(ORIGDIR)/russian.dict.koi | (cd $(NRIDIR); ispell -W 0 -l -d ./russian.hash ) | ./sortkoi8c | uniq > check_new-rus
	@echo "List of missing words is in file check_new-rus"

deb:	$(DEBIANPACKAGE)

$(DEBIANPACKAGE):	dict
	@rm -rf $(DISTDIR)
	@mkdir -p $(DISTDIR)/DEBIAN $(DISTDIR)/usr/lib/ispell $(DISTDIR)/usr/doc/$(DEBNAME)
	@cp DEBIAN/{postinst,prerm} $(DISTDIR)/DEBIAN
	@cp DEBIAN/{README.Debian,copyright} $(READMES) $(DISTDIR)/usr/doc/$(DEBNAME)
	@cp $(FINALHASH) $(FINALAFF) $(DISTDIR)/usr/lib/ispell/
	@sed -e "s/Version: XXX/Version: $(VERSION)-1/; s/Installed-Size: .*$$/Installed-Size: `du -s $(DISTDIR)/usr|cut -f1`/;" < DEBIAN/control > $(DISTDIR)/DEBIAN/control
	@chown -R root $(DISTDIR)/DEBIAN/control > /dev/null 2>&1 || { \
		echo "Error: you have to do 'make deb' as root, or use 'fakeroot make deb'."; \
		exit 1; \
	}
	@chown -R root $(DISTDIR)	
	@chgrp -R root $(DISTDIR)
	@dpkg-deb -b $(DISTDIR) .
	@echo Debian package $(DEBIANPACKAGE) created.
	@rm -rf $(DISTDIR)

# Targets for fr. Dimitri
dict.ez2:	hugelistA.koi
	perl esq < hugelistA.koi | bzip2 > dict.ez2

# This requires an existing text_n2o.exe archive in current directory
text_n2o.exe: dict.ez2 esq text_new2old.pl mkhugeidx.pl text_n2o_pre.exe
	rm -f tn2o.pl esq.pl
	ln -s text_new2old.pl tn2o.pl
	ln -s esq esq.pl
	ln -s mkhugeidx.pl mkidx.pl
	cp text_n2o_pre.exe text_n2o.exe
	zip -u text_n2o.exe dict.ez2 esq.pl tn2o.pl mkidx.pl htmluni.pl
	rm -f tn2o.pl esq.pl mkidx.pl

update: text_n2o.exe dist
