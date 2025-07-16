# Makefile for Russian ispell dictionary

LIB=/usr/lib/ispell

DICT = base.koi abbrev.koi computer.koi for_name.koi geography.koi \
	science.koi # rare.koi

ifdef YO
PATT=y
else
PATT=e
YO2E=| tr '\243\263' '\305\345'
endif

koi iso alt win mac: russian.aff.koi russian.dict.koi
	sed -e "s/^\#$(PATT)//;s/^\#$@/wordchars/" $< | \
	./trans koi $@ > russian.aff
	cat russian.dict.koi | ./trans koi $@ > russian.dict
	rm russian.dict.koi
	buildhash ./russian.dict ./russian.aff ./russian.hash

install:
	cp russian.hash russian.aff $(LIB)

russian.dict.koi: $(DICT)
	cat $^ $(YO2E) | ./sortkoi8 | uniq > $@

check_dict: $(DICT)
	for i in `cat $(DICT) | sed 's,/.*$$,,' | sort | uniq -d`; do \
		grep "^$$i/\|^$$i$$" $(DICT); \
	done > .temp

sort_dict: $(DICT)
	for i in $(DICT); do \
		cat $$i | ./sortkoi8 > $$i.temp; \
		mv -f $$i.temp $$i; \
	done

clean:
	rm -f russian.dict* russian.hash russian.aff .temp
