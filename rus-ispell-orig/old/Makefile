# Makefile for Russian ispell dictionaries (version 0.99c0 and higher)

LIB=/usr/lib/ispell

dict = base.koi computer.koi geography.koi science.koi

all,koi: russian.aff.koi $(dict)
	cat russian.aff.koi | sed -e "s/^\#e//" | \
	sed -e "s/^\#koi/wordchars/" > russian.aff
	cat $(dict) | tr '\243\263' 'Åå' | sortkoi8 | uniq > russian.dict
	buildhash ./russian.dict ./russian.aff ./russian.hash

koi-yo:	russian.aff.koi $(dict)
	cat russian.aff.koi | sed -e "s/^\#y//" | \
	sed -e "s/^\#koi/wordchars/" > russian.aff
	cat $(dict) > russian.dict
	buildhash ./russian.dict ./russian.aff ./russian.hash

alt:	trans russian.aff.koi $(dict)
	cat russian.aff.koi | sed -e "s/^\#e//" | \
	./trans koi8r cp866 | sed -e "s/^\#alt/wordchars/" > russian.aff
	cat $(dict) | tr '\243\263' 'Åå' | sortkoi8 | uniq | ./trans koi8r cp866 > russian.dict
	buildhash ./russian.dict ./russian.aff ./russian.hash

alt-yo:	trans russian.aff.koi $(dict)
	cat russian.aff.koi | sed -e "s/^\#y//" | \
	./trans koi8r cp866 | sed -e "s/\#alt/wordchars/" > russian.aff
	cat $(dict) | ./trans koi8r cp866 > russian.dict
	buildhash ./russian.dict ./russian.aff ./russian.hash

iso:	trans russian.aff.koi $(dict)
	cat russian.aff.koi | sed -e "s/^\#e//" | \
	./trans koi8r iso88595 | sed -e "s/^\#iso/wordchars/" > russian.aff
	cat $(dict) | tr '\243\263' 'Åå' | sortkoi8 | uniq | ./trans koi8r iso88595 > russian.dict
	buildhash ./russian.dict ./russian.aff ./russian.hash

iso-yo:	trans russian.aff.koi $(dict)
	cat russian.aff.koi | sed -e "s/^\#y//" | \
	./trans koi8r iso88595 | sed -e "s/\#iso/wordchars/" > russian.aff
	cat $(dict) | ./trans koi8r iso88595 > russian.dict
	buildhash ./russian.dict ./russian.aff ./russian.hash

install:
	cp russian.hash russian.aff $(LIB)

check_dict: $(dict)
	for i in `cat $(dict) | sed 's,/.*$$,,' | sort | uniq -d`; do \
		grep "^$$i/\|^$$i$$" $(dict); \
	done > .temp

sort_dict: $(dict)
	for i in $(dict); do \
		cat $$i | ./trans koi8r cp866 | sort | ./trans cp866 koi8r > $$i.temp; \
		mv -f $$i.temp $$i; \
	done

clean:
	rm -f russian.dict* russian.hash russian.aff russian1.aff .temp

