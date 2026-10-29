#!/bin/sh
# Set up a new paper from the template (run through `make init`):
#   - rename main.tex to <name>.tex and point the build files at it,
#   - choose the style in \documentclass,
#   - optionally add the shared lab bibliography as a git submodule.
set -eu
cd "$(dirname "$0")/.."

STYLES="lncs sigconf sigplan acmsmall acmlarge acmtog manuscript ieee lipics article"
BIB_REPO=${BIB_REPO:-git@github.com:ku-sldg/bib.git}
BIB_BRANCH=${BIB_BRANCH:-master}

if [ ! -f main.tex ]; then
  echo "init: main.tex not found; has the paper been set up already?" >&2
  exit 1
fi

# Portable in-place edit (BSD and GNU sed differ on -i).
edit() {
  file=$1; shift
  sed "$@" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

default=$(basename "$(pwd)")
printf 'Paper name, used for the .tex and .pdf files [%s]: ' "$default"
read -r name
name=${name:-$default}
case $name in
  ''|*[!A-Za-z0-9._-]*)
    echo "init: use only letters, digits, '.', '_' and '-'." >&2; exit 1 ;;
esac

printf 'Style (%s) [lncs]: ' "$(echo $STYLES | sed 's/ /, /g')"
read -r style
style=${style:-lncs}
case " $STYLES " in
  *" $style "*) ;;
  *) echo "init: unknown style '$style'." >&2; exit 1 ;;
esac

printf 'Add the shared bibliography %s as a submodule? [y/N]: ' "$BIB_REPO"
read -r bib

# The step most likely to fail (network, SSH keys) goes first.
case $bib in
  [yY]*)
    git submodule add -b "$BIB_BRANCH" --name bib "$BIB_REPO" bib
    edit main.tex -e 's/^\\bibliography{references}/\\bibliography{references,bib\/sldg}/'
    ;;
esac

edit main.tex -e "s/^  lncs, /  $style, /"
if [ "$name" != main ]; then
  if git ls-files --error-unmatch main.tex >/dev/null 2>&1; then
    git mv main.tex "$name.tex"
  else
    mv main.tex "$name.tex"
  fi
  edit Makefile -e "s/^MAIN     ?= main\$/MAIN     ?= $name/"
  edit .latexmkrc -e "s/'main\.tex'/'$name.tex'/"
  edit .gitignore -e "s|^/main\.pdf\$|/$name.pdf|" -e "s|^/main-\*\.pdf\$|/$name-*.pdf|" \
    -e "s|^/main-source\.tar\.gz\$|/$name-source.tar.gz|"
fi

if [ "$style" = lipics ] && [ ! -f lipics-v2021.cls ]; then
  make --no-print-directory lipics
fi

echo "Set up $name.tex in the $style style.  Run 'make' to build $name.pdf."
