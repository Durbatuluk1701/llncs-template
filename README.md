# Paper template: one source, many publisher styles

A LaTeX paper template that builds the same source as a Springer LNCS, ACM
(any `acmart` format), IEEE, LIPIcs or plain article paper.  Retargeting a
paper is a one-word change:

```latex
\documentclass[sigplan, anonymous, review]{venue}
```

`venue.cls` is a thin wrapper around the publishers' own classes.  You write
the title, authors, abstract, keywords, funding and acknowledgments once; it
turns them into each publisher's commands, picks the right bibliography style,
and gives every style the same theorem environments, anonymization and line
numbering.

## Quick start

1. Create a repository from this template and clone it.
2. Run `make init`.  It asks for the paper's name (for the `.tex`/`.pdf`
   files), the style, and whether to add the shared lab bibliography.
3. Edit the front matter and text in `<name>.tex`, then run `make`.

Replace this README with a description of the paper.

## Styles

| Option | Publisher | Class | BibTeX style |
| --- | --- | --- | --- |
| `lncs` | Springer LNCS | `llncs` (included) | `splncs04nat` (included) |
| `sigconf`, `sigplan`, `acmsmall`, `acmlarge`, `acmtog`, `manuscript`, `acmengage`, `acmcp` | ACM, that format | `acmart` | `ACM-Reference-Format` |
| `acm` | ACM, acmart's default format | `acmart` | `ACM-Reference-Format` |
| `ieee` | IEEE conference | `IEEEtran` | `IEEEtranN` |
| `lipics` | Dagstuhl LIPIcs | `lipics-v2021` (`make lipics`) | `plainurl` |
| `article` | Preprints, reports | `article` | `plainnat` |

`make STYLE=sigplan` builds `main-sigplan.pdf` without touching the source,
and `make styles` builds every style side by side.

## Options

| Option | Effect |
| --- | --- |
| `anonymous` | Double-blind: hides authors, funding, acknowledgments and `\anon{...}` text (also in the PDF metadata and running heads). |
| `review` | Line numbers. |
| `final` | Hides `\todo` and other notes (a warning says how many). |
| `natbib=false` | Do not load natbib, e.g. to use biblatex. |

Any other option goes to the underlying class: `\documentclass[sigconf, nonacm]{venue}`,
`\documentclass[ieee, compsoc]{venue}`, `\documentclass[lncs, envcountsame]{venue}`.
On the command line: `make OPTIONS=anonymous,review` (combines with `STYLE`).

## Front matter

Put it in the preamble:

```latex
\title[Short Title for Running Heads]{Full Title}

\addaffiliation{ku}{
  department  = Institute for Information Sciences,
  institution = The University of Kansas,
  city = Lawrence, state = KS, postcode = 66045, country = USA,
}
\addauthor{First Author}{
  affiliation = ku,             % one id, or several: {ku, other}
  email       = first@ku.edu,
  orcid       = 0000-0000-0000-0000,
}
\authorrunning{F. Author et al.}
\keywords{First keyword, Second keyword}
\funding{Supported by organization X.}
\ccsdesc[500]{Theory of computation~Logic and verification}
```

and write the abstract **before** `\maketitle` (acmart requires this; for the
other styles it is moved below the title automatically):

```latex
\begin{document}
\begin{abstract} ... \end{abstract}
\maketitle
```

What each style does with it:

- **LNCS**: authors get `\inst` numbers when there is more than one
  institution, ORCIDs become `\orcidID`, and each e-mail address is listed
  under the author's first affiliation.  Funding becomes a footnote on the
  title.
- **ACM**: one `\author`/`\affiliation{\institution ... \country}` block per
  author.  acmart expects `institution`, `city` and `country` and warns when
  one is missing.
- **IEEE**: one `\IEEEauthorblockN`/`\IEEEauthorblockA` per author; keywords
  become *Index Terms*.
- **LIPIcs**: the five-argument `\author`; `\authorrunning` and `\Copyright`
  default to the author list.  `\ccsdesc` is used as well.
- **article**: classic `\author{... \and ...}` blocks.

If you leave out `\addauthor`, nothing is generated and the class's own
`\author` syntax works as usual.

## Writing for several styles

- `\IfStyleT{acm}{...}`, `\IfStyleF{...}{...}`, `\IfStyleTF{...}{...}{...}`
  take a comma-separated list of styles (`sigplan`) or families (`acm`,
  `lncs`, `ieee`, `lipics`, `article`).  Use them for publisher-only metadata
  such as ACM's `\setcopyright`/`\acmConference` block, LIPIcs's
  `\hideLIPIcs`, or Springer's required *Disclosure of Interests* (see
  `main.tex`).  `\VenueStyle` and `\VenueFamily` expand to the current names.
- These work everywhere and do nothing where a publisher has no use for them:
  `acks` environment, `\anon[<replacement>]{<text>}`, `\Description{<alt
  text>}` (figure descriptions, which ACM asks for), `\ccsdesc` and the
  `CCSXML` environment.
- The environments `theorem`, `lemma`, `corollary`, `proposition`,
  `conjecture`, `definition`, `example`, `remark` and `proof` exist in every
  style, in the publisher's look.
- Notes: `\todo{...}` and your own `\newnote{\will}{Will}{blue}` (then
  `\will{...}`) print inline and vanish with `final`.

## Bibliography

Add entries to `references.bib`; the publisher's BibTeX style is chosen for
you (a `\bibliographystyle` in the document overrides it).  natbib is loaded,
so besides `\cite` you can use `\citet` ("Hoare [3]"), `\citep` and
`\citeauthor` in every style except LIPIcs, whose required `plainurl` style
does not support it (there `\citet` falls back to `\cite` with a warning).

`splncs04nat.bst` is Springer's `splncs04.bst` with natbib-compatible labels
added; the reference list it produces is identical.  For a camera-ready
version you can switch to `\bibliographystyle{splncs04}` if you do not use
`\citet`.

**Shared lab bibliography.**  `make bib` (or answering yes in `make init`)
adds [ku-sldg/bib](https://github.com/ku-sldg/bib) as the `bib` submodule;
then use `\bibliography{references,bib/sldg}`.  `make update-bib` pulls its
latest version.  `make` fetches the submodule by itself in a fresh clone.
Set `BIB_REPO` to use a different repository.

## Make targets

| Command | Does |
| --- | --- |
| `make` | Build `main.pdf` (with latexmk). |
| `make STYLE=<style>` / `OPTIONS=<options>` | Build `main-<style>.pdf` with other options. |
| `make styles` | Build every style. |
| `make watch` | Rebuild on every change. |
| `make dist` | `main-source.tar.gz` with every local file the build used plus the `.bbl`, ready for arXiv or the publisher. |
| `make clean` / `make distclean` | Remove build files / also the PDFs. |
| `make init` | Set up a new paper (above). |
| `make bib` / `make update-bib` | Add / update the shared bibliography. |
| `make lipics` | Download the LIPIcs class, which is not in TeX Live. |

Without make, `latexmk main.tex`, an editor plugin or Overleaf builds the
style set in `\documentclass`.

## Files

| File | Purpose |
| --- | --- |
| `main.tex` | The paper; a sample showing every feature. |
| `references.bib` | Your bibliography. |
| `venue.cls` | The wrapper class. |
| `llncs.cls`, `splncs04.bst` | Springer's LNCS class and style (v2.26). |
| `splncs04nat.bst` | `splncs04` with natbib labels. |
| `lib/coq-listings.tex` | Coq highlighting for `listings` (`\begin{lstlisting}[language=Coq]`). |
| `lib/init.sh` | Used by `make init`. |

## Notes

- Needs LaTeX from June 2021 or later and latexmk; tested with TeX Live 2023.
  LIPIcs is distributed by Dagstuhl rather than TeX Live, so run
  `make lipics` before using that style.
- Some submission systems, notably ACM's TAPS for camera-ready versions,
  accept only the publisher's class.  For those, replace
  `\documentclass[...]{venue}` with the class itself and the front matter
  with the class's own commands (`venue.cls` section 4 shows the mapping).
