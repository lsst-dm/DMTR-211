DOCTYPE = DMTR
DOCNUMBER = 211
DOCNAME = $(DOCTYPE)-$(DOCNUMBER)
JOBNAME = $(DOCNAME)
TEX = $(filter-out $(wildcard *acronyms.tex) , $(wildcard *.tex))

export TEXMFHOME ?= lsst-texmf/texmf

# Version information extracted from git.
GITVERSION := $(shell git log -1 --date=short --pretty=%h)
GITDATE := $(shell git log -1 --date=short --pretty=%ad)
GITSTATUS := $(shell git status --porcelain)
ifneq "$(GITSTATUS)" ""
	GITDIRTY = -dirty
endif
# extra information
ISDRAFT := $(shell cat $(DOCTYPE)-$(DOCNUMBER).tex |grep 'lsstdraft')
ifeq ($(ISDRAFT),"")
	# I am building a tag version of the document
	REF = $(shell git tag | grep ^v | sort -r)
else
	# I am building a branch or master version of the document
	REF = $(shell git rev-parse --abbrev-ref HEAD )
endif
# Travis is detaching to the HEAD of the branch,
ifeq ("$(REF)","HEAD")
	GITREF = $(shell git branch --contains HEAD | grep -v ^* | sed "s/ //g" )
else
	GITREF = $(REF)
endif

$(JOBNAME).pdf: $(DOCNAME).tex meta.tex acronyms.tex
	xelatex -jobname=$(JOBNAME) $(DOCNAME)
	bibtex $(DOCNAME)
	xelatex -jobname=$(JOBNAME) $(DOCNAME)
	xelatex -jobname=$(JOBNAME) $(DOCNAME)
	xelatex -jobname=$(JOBNAME) $(DOCNAME)


.FORCE:

meta.tex: Makefile .FORCE
	rm -f $@
	touch $@
	echo '% GENERATED FILE -- edit this in the Makefile' >>$@
	/bin/echo '\newcommand{\lsstDocType}{$(DOCTYPE)}' >>$@
	/bin/echo '\newcommand{\lsstDocNum}{$(DOCNUMBER)}' >>$@
	/bin/echo '\newcommand{\vcsrevision}{$(GITVERSION)$(GITDIRTY)}' >>$@
	/bin/echo '\newcommand{\vcsdate}{$(GITDATE)}' >>$@
	/bin/echo '\newcommand{\gitref}{$(GITREF)}' >>$@


#Traditional acronyms are better in this document
acronyms.tex : ${TEX} myacronyms.txt skipacronyms.txt
	echo ${TEXMFHOME}
	python3 ${TEXMFHOME}/../bin/generateAcronyms.py -t "SE"    $(TEX)

myacronyms.txt :
	touch myacronyms.txt

skipacronyms.txt :
	touch skipacronyms.txt

clean :
	rm *.pdf *.nav *.bbl *.xdv *.snm
