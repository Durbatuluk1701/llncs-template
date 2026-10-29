# make                     build $(MAIN).pdf in the style chosen in \documentclass
# make STYLE=sigplan       build $(MAIN)-sigplan.pdf instead (any venue.cls style)
# make OPTIONS=anonymous   add class options; combine with STYLE if you like
# make styles              build the paper in every style in $(STYLES)
# make watch               rebuild whenever a file changes
# make dist                source archive for arXiv or the publisher
# make clean / distclean   remove build files / and the PDFs
# make init                set up a new paper from this template
# make bib / update-bib    add / update the shared lab bibliography submodule
# make lipics              download the LIPIcs class (not in TeX Live)

MAIN     ?= main
STYLE    ?=
OPTIONS  ?=
LATEXMK  ?= latexmk
LATEXMK_FLAGS ?= -pdf -interaction=nonstopmode -halt-on-error -file-line-error
STYLES   ?= lncs sigconf sigplan acmsmall ieee article \
            $(if $(wildcard lipics-v2021.cls),lipics)
BIB_REPO   ?= git@github.com:ku-sldg/bib.git
BIB_BRANCH ?= master
LIPICS_URL ?= https://raw.githubusercontent.com/dagstuhl-publishing/styles/master/LIPIcs/authors
LIPICS_FILES = lipics-v2021.cls lipics-logo-bw.pdf orcid.pdf cc-by.pdf

comma := ,
empty :=
space := $(empty) $(empty)
VENUE_OPTIONS := $(subst $(space),,$(strip $(STYLE)$(if $(and $(STYLE),$(OPTIONS)),$(comma))$(OPTIONS)))
ifneq ($(VENUE_OPTIONS),)
  JOB    := $(MAIN)-$(subst =,-,$(subst $(comma),-,$(VENUE_OPTIONS)))
  PRETEX := -usepretex='\def\VenueOptions{$(VENUE_OPTIONS)}' -jobname=$(JOB)
else
  JOB    := $(MAIN)
  PRETEX :=
endif
AUX_EXTS := aux bbl blg fdb_latexmk fls log out synctex.gz toc vtc xmpi

.PHONY: all pdf watch styles dist clean distclean init bib update-bib lipics submodules

all: pdf

pdf: submodules
	$(LATEXMK) $(LATEXMK_FLAGS) $(PRETEX) $(MAIN).tex

watch: submodules
	$(LATEXMK) $(LATEXMK_FLAGS) -pvc $(PRETEX) $(MAIN).tex

styles:
	@for s in $(STYLES); do $(MAKE) --no-print-directory pdf STYLE=$$s || exit 1; done

# Everything LaTeX read from this directory (per the .fls recorder file), plus
# the .bbl, which arXiv needs instead of the .bib files.
dist: pdf
	@if [ "$(JOB)" != "$(MAIN)" ]; then \
	  echo "dist packs the style set in \\documentclass; drop STYLE/OPTIONS." >&2; exit 1; fi
	@files=$$(sed -n 's|^INPUT \(\./\)\{0,1\}\([^/].*\)|\2|p' $(MAIN).fls | sort -u | \
	  grep -E -v '^$(MAIN)\.(aux|out|toc|bbl|xmpi)$$'); \
	tar -czf $(MAIN)-source.tar.gz $$files $(MAIN).bbl && \
	echo "Wrote $(MAIN)-source.tar.gz:" && tar -tzf $(MAIN)-source.tar.gz | sed 's/^/  /'

# Covers every $(MAIN)-<style> build; only PDFs with a LaTeX .fls next to them
# count as built, so figures are never deleted.
clean:
	-$(LATEXMK) -c $(MAIN).tex
	rm -f comment.cut $(foreach e,$(AUX_EXTS),$(wildcard $(MAIN)-*.$(e)))

distclean:
	rm -f $(MAIN).pdf $(patsubst %.fls,%.pdf,$(wildcard $(MAIN)-*.fls)) $(MAIN)-source.tar.gz
	@$(MAKE) --no-print-directory clean

init:
	@BIB_REPO='$(BIB_REPO)' BIB_BRANCH='$(BIB_BRANCH)' sh lib/init.sh

# Fetch submodules a fresh clone does not have yet (no network otherwise).
submodules:
	@if [ -f .gitmodules ] && git config -f .gitmodules --get-regexp '^submodule\..*\.path$$' >/dev/null \
	   && git submodule status 2>/dev/null | grep -q '^-'; then git submodule update --init; fi

bib:
	@if [ -e bib/.git ]; then echo "bib/ already exists."; \
	else git submodule add -b $(BIB_BRANCH) --name bib $(BIB_REPO) bib; fi

update-bib:
	git submodule update --init --remote bib

# Also forget earlier (failed) runs: latexmk would not notice the new class.
lipics:
	@for f in $(LIPICS_FILES); do \
	  echo "Downloading $$f"; curl -fsSL -o $$f $(LIPICS_URL)/$$f || exit 1; done
	rm -f $(wildcard $(MAIN).fdb_latexmk $(MAIN)-*.fdb_latexmk)
