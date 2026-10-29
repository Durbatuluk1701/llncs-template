%% venue.cls -- one paper source, many publisher styles.
%%
%% A thin wrapper around the official publisher classes.  The target style is
%% a class option, and everything that differs between the publishers'
%% front-matter conventions goes through one small neutral interface, so
%% retargeting a paper is a one-word change:
%%
%%   \documentclass[sigplan, anonymous, review]{venue}
%%
%% Styles
%%   lncs                    Springer LNCS                       (llncs)
%%   acm                     ACM, acmart's default format         (acmart)
%%   sigconf, sigplan, acmsmall, acmlarge, acmtog, manuscript, acmengage,
%%   acmcp                   ACM, that acmart format              (acmart)
%%   ieee                    IEEE conference                     (IEEEtran)
%%   lipics                  Dagstuhl LIPIcs                     (lipics-v2021)
%%   article                 Plain article for preprints/reports (article)
%%
%% Options
%%   anonymous   hide authors, funding, acknowledgments and \anon{...} text
%%   review      number the lines
%%   final       hide \todo{...} and \newnote notes
%%   natbib=false  do not load natbib (e.g. to use biblatex instead)
%%   Any other option is passed on to the underlying class.
%%
%% A predefined \VenueOptions (e.g. from `make STYLE=sigplan`) is applied after
%% the \documentclass options, so it wins.
%%
%% Front matter (preamble)
%%   \title[<short title>]{<title>}
%%   \addaffiliation{<id>}{department=, institution=, city=, state=,
%%                         postcode=, country=}
%%   \addauthor{<name>}{affiliation=<id list>, email=, orcid=}
%%   \authorrunning{<short author list>}  \keywords{<a>, <b>, <c>}
%%   \funding{<text>}  \ccsdesc[<weight>]{<concept>}  CCSXML environment
%% In the document: abstract environment *before* \maketitle.
%% Elsewhere: acks environment, \anon[<replacement>]{<text>}, \todo{<text>},
%%   \newnote{\cmd}{<label>}{<color>}, \IfStyleTF{<styles>}{<true>}{<false>},
%%   \IfStyleT, \IfStyleF, \VenueStyle, \VenueFamily.
%%
%% See README.md for details.

\NeedsTeXFormat{LaTeX2e}[2021/06/01]
\ProvidesClass{venue}[2026/10/29 v1.0 One paper source, many publisher styles]

% ===========================================================================
% 1. Options and style selection
% ===========================================================================
\ExplSyntaxOn

\str_new:N   \g__venue_style_str
\str_new:N   \g__venue_family_str
\bool_new:N  \g__venue_anonymous_bool
\bool_new:N  \g__venue_review_bool
\bool_new:N  \g__venue_final_bool
\bool_new:N  \g__venue_natbib_bool
\bool_gset_true:N \g__venue_natbib_bool
\clist_new:N \g__venue_passthrough_clist
\bool_new:N  \l__venue_tmp_bool

\cs_new_protected:Npn \__venue_set_style:nn #1#2
{
  \str_gset:Nn \g__venue_family_str {#1}
  \str_gset:Nn \g__venue_style_str  {#2}
}

% Options we do not know go to the underlying class.
\cs_new_protected:Npn \__venue_pass_option:n #1
{
  \tl_if_blank:nTF {#1}
  { \clist_gput_right:NV \g__venue_passthrough_clist \l_keys_key_str }
  {
    \clist_gput_right:Nx \g__venue_passthrough_clist
    { \l_keys_key_str = \exp_not:n {#1} }
  }
}

\keys_define:nn { venue }
{
  lncs      .code:n      = \__venue_set_style:nn { lncs }    { lncs } ,
  acm       .code:n      = \__venue_set_style:nn { acm }     { acm } ,
  ieee      .code:n      = \__venue_set_style:nn { ieee }    { ieee } ,
  lipics    .code:n      = \__venue_set_style:nn { lipics }  { lipics } ,
  article   .code:n      = \__venue_set_style:nn { article } { article } ,
  anonymous .bool_gset:N = \g__venue_anonymous_bool ,
  review    .bool_gset:N = \g__venue_review_bool ,
  final     .bool_gset:N = \g__venue_final_bool ,
  natbib    .bool_gset:N = \g__venue_natbib_bool ,
  unknown   .code:n      = \__venue_pass_option:n {#1} ,
}
% Each acmart format is a style of its own: \documentclass[sigplan]{venue}.
\clist_map_inline:nn
{
  manuscript, acmsmall, acmlarge, acmtog, sigconf, sigplan, acmengage, acmcp
}
{ \keys_define:nn { venue } { #1 .code:n = \__venue_set_style:nn { acm } {#1} } }

\IfFormatAtLeastTF { 2022-06-01 }
{ \ProcessKeyOptions [ venue ] }
{ \RequirePackage { l3keys2e } \ProcessKeysOptions { venue } }

\cs_if_exist:NT \VenueOptions
{ \exp_args:Nno \keys_set:nn { venue } { \VenueOptions } }

\str_if_empty:NT \g__venue_family_str
{
  \msg_new:nnn { venue } { no-style }
  { No~style~option~given;~falling~back~to~`article'. }
  \msg_warning:nn { venue } { no-style }
  \__venue_set_style:nn { article } { article }
}

\cs_new:Npn \VenueStyle  { \str_use:N \g__venue_style_str }
\cs_new:Npn \VenueFamily { \str_use:N \g__venue_family_str }

% \IfStyleTF{<list>}{<true>}{<false>}: <list> may name styles (sigplan) or
% families (acm, lncs, ieee, lipics, article).
\prg_new_protected_conditional:Npnn \__venue_if_style:n #1 { T , F , TF }
{
  \bool_set_false:N \l__venue_tmp_bool
  \clist_map_inline:nn {#1}
  {
    \bool_lazy_or:nnT
    { \str_if_eq_p:ee { \g__venue_style_str }  { ##1 } }
    { \str_if_eq_p:ee { \g__venue_family_str } { ##1 } }
    { \bool_set_true:N \l__venue_tmp_bool \clist_map_break: }
  }
  \bool_if:NTF \l__venue_tmp_bool \prg_return_true: \prg_return_false:
}
\NewDocumentCommand \IfStyleTF { m +m +m } { \__venue_if_style:nTF {#1} {#2} {#3} }
\NewDocumentCommand \IfStyleT  { m +m }    { \__venue_if_style:nT  {#1} {#2} }
\NewDocumentCommand \IfStyleF  { m +m }    { \__venue_if_style:nF  {#1} {#2} }

% Work out which class to load, and with which options.
\tl_new:N    \venue@class
\clist_new:N \l__venue_class_options_clist
\exp_args:NV \str_case:nn \g__venue_family_str
{
  { lncs }
    {
      \tl_set:Nn \venue@class { llncs }
      \clist_set:Nn \l__venue_class_options_clist { runningheads }
    }
    { acm }
    {
      \tl_set:Nn \venue@class { acmart }
      \str_if_eq:VnF \g__venue_style_str { acm }
      { \clist_put_right:NV \l__venue_class_options_clist \g__venue_style_str }
      \bool_if:NT \g__venue_anonymous_bool
      { \clist_put_right:Nn \l__venue_class_options_clist { anonymous } }
      \bool_if:NT \g__venue_review_bool
      { \clist_put_right:Nn \l__venue_class_options_clist { review } }
      \bool_if:NF \g__venue_natbib_bool
      { \clist_put_right:Nn \l__venue_class_options_clist { natbib = false } }
    }
    { ieee }
    {
      \tl_set:Nn \venue@class { IEEEtran }
      \clist_set:Nn \l__venue_class_options_clist { conference }
    }
    { lipics }
    {
      \tl_set:Nn \venue@class { lipics-v2021 }
      % LIPIcs warns about cleveref unless it loads it itself.
      \clist_set:Nn \l__venue_class_options_clist { a4paper, cleveref }
      \bool_if:NT \g__venue_anonymous_bool
      { \clist_put_right:Nn \l__venue_class_options_clist { anonymous } }
      % LIPIcs loads babel, which needs a language.
      \PassOptionsToPackage { english } { babel }
      \IfFileExists { lipics-v2021.cls } { }
      {
        \msg_new:nnnn { venue } { missing-lipics }
        { The~LIPIcs~class~(lipics-v2021.cls)~is~not~installed. }
        {
          It~is~not~part~of~TeX~Live.~Run~`make~lipics'~or~download~
          lipics-v2021.cls,~lipics-logo-bw.pdf,~orcid.pdf~and~cc-by.pdf~
          from~https://github.com/dagstuhl-publishing/styles~into~the~
          paper's~directory.
        }
        \msg_critical:nn { venue } { missing-lipics }
      }
    }
    { article }
    { \tl_set:Nn \venue@class { article } }
}
\clist_concat:NNN \l__venue_class_options_clist
\l__venue_class_options_clist \g__venue_passthrough_clist
\tl_new:N \venue@classoptions
\tl_set:Nx \venue@classoptions { \clist_use:Nn \l__venue_class_options_clist { , } }

\ExplSyntaxOff

% ===========================================================================
% 2. Load the publisher class
% ===========================================================================
\expandafter\expandafter\expandafter\LoadClass
\expandafter\expandafter\expandafter[%
  \expandafter\venue@classoptions\expandafter]\expandafter{\venue@class}

% ===========================================================================
% 3. Packages and per-style setup
% ===========================================================================
% acmart and LIPIcs already load most of these (then these lines do nothing).
\IfStyleT{lncs,ieee,article}{%
  \RequirePackage[T1]{fontenc}%
  \IfStyleT{lncs,article}{\RequirePackage{lmodern}}%
  \RequirePackage{amsmath}%
  \RequirePackage{amssymb}%
  \RequirePackage{microtype}%
}
\IfStyleT{ieee,article}{\RequirePackage{amsthm}}
\IfStyleT{article}{\RequirePackage[margin=1in]{geometry}}
\RequirePackage{graphicx}
\RequirePackage{xcolor}
\ExplSyntaxOn
% natbib for \citet & co.  acmart loads it itself; LIPIcs keeps its own
% bibliography layout and the plainurl style Dagstuhl requires.
\bool_if:NT \g__venue_natbib_bool
{
  \__venue_if_style:nF { acm , lipics }
  { \RequirePackage [ numbers , sort&compress ] { natbib } }
}
% Line numbers; in two columns, on the outer side of each column.
\bool_if:NT \g__venue_review_bool
{
  \__venue_if_style:nT { lncs , article } { \RequirePackage { lineno } }
  \__venue_if_style:nT { ieee } { \RequirePackage [ switch ] { lineno } }
}
\ExplSyntaxOff
\RequirePackage{hyperref}
\IfStyleT{lncs,ieee,article}{\hypersetup{hidelinks}}
% Springer's eBook style: URLs in blue roman.
\IfStyleT{lncs}{%
  \urlstyle{rm}\renewcommand\UrlFont{\color{blue}\rmfamily}%
  \pdfstringdefDisableCommands{%
    \def\inst#1{}\def\orcidID#1{}\def\thanks#1{}\let\fnmsep\empty}}

% Bibliography look, when natbib replaces the class's own thebibliography.
\ifdefined\bibfont
  \IfStyleT{lncs}{%
    % llncs has \chapter, so natbib would start a "Bibliography" chapter.
    \renewcommand\bibsection{\section*{\refname}}%
    \renewcommand\bibfont{\small}%
    \renewcommand\bibnumfmt[1]{#1.}}
  \IfStyleT{ieee}{%
    \renewcommand\bibfont{\footnotesize}%
    \setlength\bibsep{0pt plus 0.3ex}}
\fi

% A common set of theorem-like environments: theorem, lemma, corollary,
% proposition, conjecture, definition, example, remark (and proof).  llncs and
% LIPIcs define all of them already; acmart lacks remark.
\IfStyleT{ieee,article}{%
  \theoremstyle{plain}
  \newtheorem{theorem}{Theorem}
  \newtheorem{lemma}[theorem]{Lemma}
  \newtheorem{corollary}[theorem]{Corollary}
  \newtheorem{proposition}[theorem]{Proposition}
  \newtheorem{conjecture}[theorem]{Conjecture}
  \theoremstyle{definition}
  \newtheorem{definition}[theorem]{Definition}
  \newtheorem{example}[theorem]{Example}
  \theoremstyle{remark}
  \newtheorem{remark}[theorem]{Remark}
  \theoremstyle{plain}}
\IfStyleT{acm}{%
  % acmart defines its theorems at the end of the preamble; add ours after.
  \AddToHook{begindocument/before}{%
    \@ifundefined{remark}{\@ifundefined{c@theorem}{}{%
        \theoremstyle{acmdefinition}%
        \newtheorem{remark}[theorem]{Remark}%
        \theoremstyle{acmplain}}}{}}}

% ===========================================================================
% 4. Neutral front matter
% ===========================================================================
\ExplSyntaxOn

\msg_new:nnn { venue } { unknown-affiliation }
{
  Author~`#2'~refers~to~affiliation~`#1',~which~was~never~declared~
  with~\iow_char:N\\addaffiliation.
}
\msg_new:nnn { venue } { late-abstract }
{
  The~ACM~class~only~typesets~an~abstract~that~comes~before~
  \iow_char:N\\maketitle.~Move~the~abstract~environment~up.
}
\msg_new:nnn { venue } { hidden-notes }
{ #1~note(s)~hidden~by~the~`final'~option. }
\msg_new:nnn { venue } { no-citet }
{
  \iow_char:N\\citet~needs~natbib,~which~the~LIPIcs~style~does~not~use;~
  typeset~as~\iow_char:N\\cite.~Write~the~author~names~yourself.
}

% l3msg does not expand message arguments; these variants do.
\tl_new:N \l__venue_msg_tl
\cs_new_eq:NN \__venue_msg_error:nnnn \msg_error:nnnn
\cs_generate_variant:Nn \__venue_msg_error:nnnn { nnnV }
\cs_new_eq:NN \__venue_msg_warning:nnn \msg_warning:nnn
\cs_generate_variant:Nn \__venue_msg_warning:nnn { nnV }

\tl_new:N   \g__venue_title_tl
\tl_new:N   \g__venue_short_title_tl
\tl_new:N   \g__venue_keywords_tl
\tl_new:N   \g__venue_funding_tl
\tl_new:N   \g__venue_authorrunning_tl
\tl_new:N   \g__venue_copyright_tl
\tl_new:N   \g__venue_abstract_tl
\bool_new:N \g__venue_abstract_bool
\int_new:N  \g__venue_authors_int
\prop_new:N \l__venue_fields_prop
\tl_new:N   \l__venue_tmp_tl
\tl_new:N   \l__venue_field_tl
\tl_new:N   \l__venue_name_tl
\tl_new:N   \l__venue_out_tl
\tl_new:N   \l__venue_block_tl
\seq_new:N  \l__venue_lines_seq
\seq_new:N  \l__venue_parts_seq
\seq_new:N  \l__venue_address_seq
\seq_new:N  \l__venue_statezip_seq
\seq_new:N  \l__venue_used_seq
\seq_new:N  \l__venue_names_seq
\clist_new:N \l__venue_affils_clist
\clist_new:N \l__venue_keywords_clist

% ---- Declaring authors and affiliations ---------------------------------
\clist_map_inline:nn
{ department, institution, city, state, postcode, country }
{
  \keys_define:nn { venue / affiliation }
  { #1 .code:n = \prop_put:Nnn \l__venue_fields_prop { #1 } {##1} }
}
\clist_map_inline:nn { affiliation, email, orcid }
{
  \keys_define:nn { venue / author }
  { #1 .code:n = \prop_put:Nnn \l__venue_fields_prop { #1 } {##1} }
}
\keys_define:nn { venue / author }
{ affiliations .code:n = \prop_put:Nnn \l__venue_fields_prop { affiliation } {#1} }

\NewDocumentCommand \addaffiliation { m m }
{
  \prop_clear:N \l__venue_fields_prop
  \keys_set:nn { venue / affiliation } {#2}
  \prop_gclear_new:c { g__venue_affil_ #1 _prop }
  \prop_gset_eq:cN { g__venue_affil_ #1 _prop } \l__venue_fields_prop
}
\NewDocumentCommand \addauthor { m m }
{
  \int_gincr:N \g__venue_authors_int
  \prop_clear:N \l__venue_fields_prop
  \prop_put:Nnn \l__venue_fields_prop { name } {#1}
  \keys_set:nn { venue / author } {#2}
  \prop_gclear_new:c { g__venue_author_ \int_use:N \g__venue_authors_int _prop }
  \prop_gset_eq:cN { g__venue_author_ \int_use:N \g__venue_authors_int _prop }
  \l__venue_fields_prop
}
\@onlypreamble \addaffiliation
\@onlypreamble \addauthor

% \__venue_author:nnN {<n>} {<field>} <tl>  /  \__venue_affil:nnN {<id>} ...
\cs_new_protected:Npn \__venue_author:nnN #1#2#3
{ \tl_set:Nx #3 { \prop_item:cn { g__venue_author_ #1 _prop } {#2} } }
\cs_new_protected:Npn \__venue_affil:nnN #1#2#3
{ \tl_set:Nx #3 { \prop_item:cn { g__venue_affil_ #1 _prop } {#2} } }
\cs_new_protected:Npn \__venue_author_affils:n #1
{
  \clist_set:Nx \l__venue_affils_clist
  { \prop_item:cn { g__venue_author_ #1 _prop } { affiliation } }
  \clist_map_inline:Nn \l__venue_affils_clist
  {
    \prop_if_exist:cF { g__venue_affil_ ##1 _prop }
    {
      \__venue_author:nnN {#1} { name } \l__venue_msg_tl
      \__venue_msg_error:nnnV { venue } { unknown-affiliation } {##1} \l__venue_msg_tl
      \clist_remove_all:Nn \l__venue_affils_clist {##1}
    }
  }
}
\cs_new_protected:Npn \__venue_put_field:Nnn #1#2#3
{
  \__venue_affil:nnN {#2} {#3} \l__venue_field_tl
  \tl_if_blank:VF \l__venue_field_tl { \seq_put_right:NV #1 \l__venue_field_tl }
}
% "City, State Postcode, Country"
\cs_new_protected:Npn \__venue_address:nN #1#2
{
  \seq_clear:N \l__venue_address_seq
  \seq_clear:N \l__venue_statezip_seq
  \__venue_put_field:Nnn \l__venue_address_seq  {#1} { city }
  \__venue_put_field:Nnn \l__venue_statezip_seq {#1} { state }
  \__venue_put_field:Nnn \l__venue_statezip_seq {#1} { postcode }
  \seq_if_empty:NF \l__venue_statezip_seq
  {
    \seq_put_right:Nx \l__venue_address_seq
    { \seq_use:Nn \l__venue_statezip_seq { ~ } }
  }
  \__venue_put_field:Nnn \l__venue_address_seq  {#1} { country }
  \tl_set:Nx #2 { \seq_use:Nn \l__venue_address_seq { ,~ } }
}
% Fill \l__venue_lines_seq with the non-empty lines of an affiliation:
% department, institution, address.
\cs_new_protected:Npn \__venue_affil_lines:n #1
{
  \seq_clear:N \l__venue_lines_seq
  \__venue_put_field:Nnn \l__venue_lines_seq {#1} { department }
  \__venue_put_field:Nnn \l__venue_lines_seq {#1} { institution }
  \__venue_address:nN {#1} \l__venue_tmp_tl
  \tl_if_blank:VF \l__venue_tmp_tl
  { \seq_put_right:NV \l__venue_lines_seq \l__venue_tmp_tl }
}
% \l__venue_names_seq <- all author names, in order.
\cs_new_protected:Npn \__venue_collect_names:
{
  \seq_clear:N \l__venue_names_seq
  \int_step_inline:nn { \g__venue_authors_int }
  {
    \__venue_author:nnN {##1} { name } \l__venue_name_tl
    \seq_put_right:NV \l__venue_names_seq \l__venue_name_tl
  }
}

% ---- \title[<short>]{<title>}, \keywords, \funding, \authorrunning ------
\NewCommandCopy \__venue_class_title \title
\RenewDocumentCommand \title { o m }
{
  \tl_gset:Nn \g__venue_title_tl {#2}
  \IfValueTF {#1}
  { \tl_gset:Nn \g__venue_short_title_tl {#1} }
  { \tl_gclear:N \g__venue_short_title_tl }
  \__venue_set_title:
}
\cs_new_protected:Npn \__venue_set_title:
{
  \__venue_if_style:nTF { acm }
  {
    \tl_if_empty:NTF \g__venue_short_title_tl
    { \exp_args:NV \__venue_class_title \g__venue_title_tl }
    {
      \use:x
      {
        \exp_not:N \__venue_class_title
        [ \exp_not:V \g__venue_short_title_tl ]
        { \exp_not:V \g__venue_title_tl }
      }
    }
  }
  {
    % Funding becomes a \thanks footnote on the title.
    \tl_set_eq:NN \l__venue_tmp_tl \g__venue_title_tl
    \bool_lazy_or:nnF
    { \g__venue_anonymous_bool }
    { \tl_if_empty_p:N \g__venue_funding_tl }
    {
      \__venue_if_style:nT { lncs , ieee , article }
      { \tl_put_right:Nx \l__venue_tmp_tl { \exp_not:N \thanks { \exp_not:V \g__venue_funding_tl } } }
    }
    \exp_args:NV \__venue_class_title \l__venue_tmp_tl
    \__venue_if_style:nT { lncs , lipics }
    {
      \tl_if_empty:NF \g__venue_short_title_tl
      { \exp_args:NV \titlerunning \g__venue_short_title_tl }
    }
  }
}

% As llncs typesets \keywords (it only defines it at \begin{document}).
\cs_new_protected:Npn \__venue_lncs_keywords:n #1
{
  \cs_set:Npn \and { { \textperiodcentered } ~ }
  \par \addvspace \baselineskip
  \noindent \keywordname \enspace \ignorespaces #1
}
\__venue_if_style:nT { lncs , ieee , article }
{
  \DeclareDocumentCommand \keywords { m } { \tl_gset:Nn \g__venue_keywords_tl {#1} }
  \NewDocumentCommand \funding { m } { \tl_gset:Nn \g__venue_funding_tl {#1} }
}
\__venue_if_style:nT { acm }
{ \NewDocumentCommand \funding { m } { \thanks {#1} } }

\__venue_if_style:nT { acm , ieee , article }
{ \NewDocumentCommand \authorrunning { m } { \tl_gset:Nn \g__venue_authorrunning_tl {#1} } }
\__venue_if_style:nT { lipics }
{
  \cs_new_eq:NN \__venue_lipics_authorrunning:n \authorrunning
  \cs_new_eq:NN \__venue_lipics_copyright:n \Copyright
  \RenewDocumentCommand \authorrunning { m } { \tl_gset:Nn \g__venue_authorrunning_tl {#1} }
  \RenewDocumentCommand \Copyright { m } { \tl_gset:Nn \g__venue_copyright_tl {#1} }
}

% ---- Rendering authors in each class's own syntax ------------------------
\cs_new_protected:Npn \__venue_render_lncs:
{
  % Institutes are numbered in order of first use.
  \seq_clear:N \l__venue_used_seq
  \int_step_inline:nn { \g__venue_authors_int }
  {
    \__venue_author_affils:n {##1}
    \clist_map_inline:Nn \l__venue_affils_clist
    {
      \seq_if_in:NnF \l__venue_used_seq {####1}
      { \seq_put_right:Nn \l__venue_used_seq {####1} }
    }
  }
  \tl_clear:N \l__venue_out_tl
  \int_step_inline:nn { \g__venue_authors_int }
  {
    \int_compare:nNnF {##1} = { 1 } { \tl_put_right:Nn \l__venue_out_tl { ~\and~ } }
    \__venue_author:nnN {##1} { name } \l__venue_name_tl
    \tl_put_right:NV \l__venue_out_tl \l__venue_name_tl
    \__venue_author_affils:n {##1}
    \bool_lazy_and:nnT
    { \int_compare_p:nNn { \seq_count:N \l__venue_used_seq } > { 1 } }
    { ! \clist_if_empty_p:N \l__venue_affils_clist }
    {
      \seq_clear:N \l__venue_parts_seq
      \clist_map_inline:Nn \l__venue_affils_clist
      {
        \seq_map_indexed_inline:Nn \l__venue_used_seq
        {
          \str_if_eq:nnT {####1} {########2}
          { \seq_put_right:Nn \l__venue_parts_seq {########1} }
        }
      }
      \tl_put_right:Nx \l__venue_out_tl
      { \exp_not:N \inst { \seq_use:Nn \l__venue_parts_seq { , } } }
    }
    \__venue_author:nnN {##1} { orcid } \l__venue_tmp_tl
    \tl_if_blank:VF \l__venue_tmp_tl
    { \tl_put_right:Nx \l__venue_out_tl { \exp_not:N \orcidID { \exp_not:V \l__venue_tmp_tl } } }
  }
  \exp_args:NV \author \l__venue_out_tl
  % One institute per affiliation, followed by the e-mail addresses of the
  % authors listing it first.
  \tl_clear:N \l__venue_out_tl
  \seq_map_indexed_inline:Nn \l__venue_used_seq
  {
    \int_compare:nNnF {##1} = { 1 } { \tl_put_right:Nn \l__venue_out_tl { \and } }
    \__venue_affil_lines:n {##2}
    \tl_put_right:Nx \l__venue_out_tl { \seq_use:Nn \l__venue_lines_seq { ,~ } }
    \seq_clear:N \l__venue_parts_seq
    \int_step_inline:nn { \g__venue_authors_int }
    {
      \__venue_author_affils:n {####1}
      \str_if_eq:eeT { \clist_item:Nn \l__venue_affils_clist { 1 } } {##2}
      {
        \__venue_author:nnN {####1} { email } \l__venue_tmp_tl
        \tl_if_blank:VF \l__venue_tmp_tl
        {
          \seq_put_right:Nx \l__venue_parts_seq
          { \exp_not:N \email { \exp_not:N \detokenize { \exp_not:V \l__venue_tmp_tl } } }
        }
      }
    }
    \seq_if_empty:NF \l__venue_parts_seq
    {
      \tl_put_right:Nx \l__venue_out_tl
      { \exp_not:N \\ \seq_use:Nn \l__venue_parts_seq { ,~ } }
    }
  }
  \exp_args:NV \institute \l__venue_out_tl
}

\cs_new_protected:Npn \__venue_render_acm:
{
  \int_step_inline:nn { \g__venue_authors_int }
  {
    \__venue_author:nnN {##1} { name } \l__venue_name_tl
    \exp_args:NV \author \l__venue_name_tl
    \__venue_author:nnN {##1} { orcid } \l__venue_tmp_tl
    \tl_if_blank:VF \l__venue_tmp_tl { \exp_args:NV \orcid \l__venue_tmp_tl }
    \__venue_author_affils:n {##1}
    \clist_map_inline:Nn \l__venue_affils_clist
    {
      \tl_clear:N \l__venue_block_tl
      \clist_map_inline:nn { department, institution, city, state, postcode, country }
      {
        \__venue_affil:nnN {####1} {########1} \l__venue_tmp_tl
        \tl_if_blank:VF \l__venue_tmp_tl
        {
          \tl_put_right:Nx \l__venue_block_tl
          { \exp_not:c {########1} { \exp_not:V \l__venue_tmp_tl } }
        }
      }
      \exp_args:NV \affiliation \l__venue_block_tl
    }
    \__venue_author:nnN {##1} { email } \l__venue_tmp_tl
    \tl_if_blank:VF \l__venue_tmp_tl { \exp_args:NV \email \l__venue_tmp_tl }
  }
}

\cs_new_protected:Npn \__venue_render_ieee:
{
  \tl_clear:N \l__venue_out_tl
  \bool_if:NTF \g__venue_anonymous_bool
  { \tl_set:Nn \l__venue_out_tl { \IEEEauthorblockN { Anonymous~Author(s) } } }
  {
    \int_step_inline:nn { \g__venue_authors_int }
    {
      \int_compare:nNnF {##1} = { 1 } { \tl_put_right:Nn \l__venue_out_tl { \and } }
      \__venue_author:nnN {##1} { name } \l__venue_name_tl
      \tl_put_right:Nx \l__venue_out_tl
      { \exp_not:N \IEEEauthorblockN { \exp_not:V \l__venue_name_tl } }
      \tl_clear:N \l__venue_block_tl
      \__venue_author_affils:n {##1}
      \clist_map_inline:Nn \l__venue_affils_clist
      {
        \__venue_affil:nnN {####1} { department } \l__venue_tmp_tl
        \tl_if_blank:VF \l__venue_tmp_tl
        { \tl_put_right:Nx \l__venue_block_tl { \exp_not:N \textit { \exp_not:V \l__venue_tmp_tl } \exp_not:N \\ } }
        \__venue_affil:nnN {####1} { institution } \l__venue_tmp_tl
        \tl_if_blank:VF \l__venue_tmp_tl
        { \tl_put_right:Nx \l__venue_block_tl { \exp_not:N \textit { \exp_not:V \l__venue_tmp_tl } \exp_not:N \\ } }
        \__venue_address:nN {####1} \l__venue_tmp_tl
        \tl_if_blank:VF \l__venue_tmp_tl
        { \tl_put_right:Nx \l__venue_block_tl { \exp_not:V \l__venue_tmp_tl \exp_not:N \\ } }
      }
      \__venue_author:nnN {##1} { email } \l__venue_tmp_tl
      \tl_if_blank:VF \l__venue_tmp_tl
      {
        \tl_put_right:Nx \l__venue_block_tl
        { \exp_not:N \texttt { \exp_not:N \detokenize { \exp_not:V \l__venue_tmp_tl } } }
      }
      \tl_put_right:Nx \l__venue_out_tl
      { \exp_not:N \IEEEauthorblockA { \exp_not:V \l__venue_block_tl } }
    }
  }
  \exp_args:NV \author \l__venue_out_tl
}

\cs_new_protected:Npn \__venue_render_lipics:
{
  \int_step_inline:nn { \g__venue_authors_int }
  {
    \__venue_author:nnN {##1} { name } \l__venue_name_tl
    \seq_clear:N \l__venue_parts_seq
    \__venue_author_affils:n {##1}
    \clist_map_inline:Nn \l__venue_affils_clist
    {
      \__venue_affil_lines:n {####1}
      \seq_put_right:Nx \l__venue_parts_seq { \seq_use:Nn \l__venue_lines_seq { ,~ } }
    }
    \tl_set:Nx \l__venue_block_tl { \seq_use:Nn \l__venue_parts_seq { ~\and~ } }
    \__venue_author:nnN {##1} { email } \l__venue_tmp_tl
    \__venue_author:nnN {##1} { orcid } \l__venue_out_tl
    \tl_if_blank:VF \l__venue_out_tl
    { \tl_put_left:Nx \l__venue_out_tl { https \c_colon_str //orcid.org/ } }
    \use:x
    {
      \exp_not:N \author
      { \exp_not:V \l__venue_name_tl }
      { \exp_not:V \l__venue_block_tl }
      { \exp_not:V \l__venue_tmp_tl }
      { \exp_not:V \l__venue_out_tl }
      { }
    }
  }
}

\cs_new_protected:Npn \__venue_render_article:
{
  \tl_clear:N \l__venue_out_tl
  \bool_if:NTF \g__venue_anonymous_bool
  { \tl_set:Nn \l__venue_out_tl { Anonymous~Author(s) } }
  {
    \int_step_inline:nn { \g__venue_authors_int }
    {
      \int_compare:nNnF {##1} = { 1 } { \tl_put_right:Nn \l__venue_out_tl { \and } }
      \__venue_author:nnN {##1} { name } \l__venue_name_tl
      \tl_put_right:NV \l__venue_out_tl \l__venue_name_tl
      \__venue_author_affils:n {##1}
      \clist_map_inline:Nn \l__venue_affils_clist
      {
        \__venue_affil_lines:n {####1}
        \seq_map_inline:Nn \l__venue_lines_seq
        { \tl_put_right:Nn \l__venue_out_tl { \\ ########1 } }
      }
      \__venue_author:nnN {##1} { email } \l__venue_tmp_tl
      \tl_if_blank:VF \l__venue_tmp_tl
      {
        \tl_put_right:Nx \l__venue_out_tl
        { \exp_not:N \\ \exp_not:N \texttt { \exp_not:N \detokenize { \exp_not:V \l__venue_tmp_tl } } }
      }
    }
  }
  \exp_args:NV \author \l__venue_out_tl
}

% Runs at the end of the preamble, after every \addauthor.  Without any
% \addauthor nothing happens, so the class's own \author syntax keeps working.
\AddToHook { begindocument / before } [ venue ]
{
  \int_compare:nNnF { \g__venue_authors_int } = { 0 }
    {
      \__venue_if_style:nTF { lncs }
      {
        \bool_if:NTF \g__venue_anonymous_bool
        {
          \author { Anonymous~Author(s) }
          \institute { Anonymous~Institution(s) }
        }
        { \__venue_render_lncs: }
      }
      { \use:c { __venue_render_ \str_use:N \g__venue_family_str : } }
      \__venue_collect_names:
      \__venue_if_style:nT { lipics }
      {
        \tl_if_empty:NT \g__venue_authorrunning_tl
        { \tl_gset:Nx \g__venue_authorrunning_tl { \seq_use:Nnnn \l__venue_names_seq { ~and~ } { ,~ } { ,~and~ } } }
        \tl_if_empty:NT \g__venue_copyright_tl
        { \tl_gset:Nx \g__venue_copyright_tl { \seq_use:Nnnn \l__venue_names_seq { ~and~ } { ,~ } { ,~and~ } } }
      }
      \__venue_if_style:nT { lncs , ieee , article }
      {
        \bool_if:NF \g__venue_anonymous_bool
        { \hypersetup { pdfauthor = { \seq_use:Nn \l__venue_names_seq { ,~ } } } }
    }
}
\__venue_if_style:nT { lipics }
{
  \tl_if_empty:NF \g__venue_authorrunning_tl
  { \exp_args:NV \__venue_lipics_authorrunning:n \g__venue_authorrunning_tl }
  \tl_if_empty:NF \g__venue_copyright_tl
  { \exp_args:NV \__venue_lipics_copyright:n \g__venue_copyright_tl }
}
\__venue_install_maketitle:
}

% ---- Abstract and \maketitle --------------------------------------------
% Write the abstract (and keywords) before \maketitle, as acmart requires.
% For the other classes the abstract is stored and typeset after the title.
\cs_new_protected:Npn \__venue_install_maketitle:
{
  % \let, not \NewCommandCopy: etoolbox's copy handler chokes on \par.
  \cs_set_eq:NN \__venue_class_maketitle \maketitle
  \__venue_if_style:nF { acm }
  {
    \cs_set_eq:NN \__venue_class_abstract    \abstract
    \cs_set_eq:NN \__venue_class_endabstract \endabstract
    \RenewDocumentEnvironment { abstract } { +b }
    {
      \tl_gset:Nn \g__venue_abstract_tl {##1}
      \bool_gset_true:N \g__venue_abstract_bool
    }
    { }
  }
  \RenewDocumentCommand \maketitle { }
  {
    \__venue_before_maketitle:
    \__venue_class_maketitle
    \__venue_after_maketitle:
  }
}

\cs_new_protected:Npn \__venue_before_maketitle:
{
  \__venue_if_style:nT { ieee }
  {
    \bool_lazy_or:nnF { \g__venue_anonymous_bool } { \tl_if_empty_p:N \g__venue_funding_tl }
    { \IEEEoverridecommandlockouts }
  }
  \__venue_if_style:nT { lncs , ieee , article }
  {
    \__venue_set_title:
    \exp_args:Nx \hypersetup { pdftitle = { \exp_not:V \g__venue_title_tl } }
  }
  \bool_if:NT \g__venue_anonymous_bool
  { \__venue_if_style:nT { lncs } { \authorrunning { Anonymous~Author(s) } } }
}

\cs_new_protected:Npn \__venue_after_maketitle:
{
  \__venue_if_style:nTF { acm }
  {
    \bool_lazy_or:nnF { \g__venue_anonymous_bool } { \tl_if_empty_p:N \g__venue_authorrunning_tl }
    { \cs_gset:Npx \shortauthors { \exp_not:V \g__venue_authorrunning_tl } }
    \RenewDocumentEnvironment { abstract } { +b } { \msg_error:nn { venue } { late-abstract } } { }
  }
  {
    \cs_set_eq:NN \abstract    \__venue_class_abstract
    \cs_set_eq:NN \endabstract \__venue_class_endabstract
    \bool_lazy_or:nnT { \g__venue_abstract_bool } { ! \tl_if_empty_p:N \g__venue_keywords_tl }
    { \__venue_typeset_abstract: }
  }
}

\cs_new_protected:Npn \__venue_typeset_abstract:
{
  \clist_set:NV \l__venue_keywords_clist \g__venue_keywords_tl
  \bool_if:NT \g__venue_abstract_bool
  {
    \begin { abstract }
    \tl_use:N \g__venue_abstract_tl
    \__venue_if_style:nT { lncs } { \__venue_lncs_keywords: }
    \__venue_if_style:nT { article } { \__venue_article_keywords: }
    \end { abstract }
  }
  \bool_if:NF \g__venue_abstract_bool
  {
    \__venue_if_style:nT { lncs } { \__venue_lncs_keywords: }
    \__venue_if_style:nT { article } { \__venue_article_keywords: }
  }
  \__venue_if_style:nT { ieee }
  {
    \tl_if_empty:NF \g__venue_keywords_tl
    {
      \begin { IEEEkeywords }
      \clist_use:Nn \l__venue_keywords_clist { ,~ }
      \end { IEEEkeywords }
    }
  }
}
\cs_new_protected:Npn \__venue_lncs_keywords:
{
  \tl_if_empty:NF \g__venue_keywords_tl
  {
    \exp_args:Nx \__venue_lncs_keywords:n
    { \clist_use:Nn \l__venue_keywords_clist { ~\and~ } }
  }
}
\cs_new_protected:Npn \__venue_article_keywords:
{
  \tl_if_empty:NF \g__venue_keywords_tl
  {
    \par \medskip \noindent
    \textbf { Keywords: } ~ \clist_use:Nn \l__venue_keywords_clist { ,~ }
  }
}

% ---- Things only some classes have ---------------------------------------
% Acknowledgments: hidden when anonymous (acmart's acks already behaves so).
\__venue_if_style:nF { acm }
{
  \NewDocumentEnvironment { acks } { +b }
  {
    \bool_if:NF \g__venue_anonymous_bool
    {
      \exp_args:NV \str_case:nn \g__venue_family_str
      {
        { lncs }
          {
            \cs_if_exist:NTF \credits
            { \begin { credits } \subsubsection { \ackname } #1 \end { credits } }
            { \subsubsection* { \ackname } #1 }
          }
          { ieee }    { \section* { Acknowledgment } #1 }
          { lipics }  { \section* { Acknowledgements } #1 }
          { article } { \section* { Acknowledgments } #1 }
      }
    }
  }
  { }
  \NewDocumentCommand \anon { O{ANONYMIZED} m }
  { \bool_if:NTF \g__venue_anonymous_bool {#1} {#2} }
}
% Without natbib (LIPIcs), keep \citep and \citet working.
\bool_if:NT \g__venue_natbib_bool
{
  \__venue_if_style:nT { lipics }
  {
    % natbib's [<pre>][<post>]: keep the post-note.
    \cs_new_protected:Npn \__venue_citep:nnn #1#2#3
    {
      \IfValueTF {#2} { \cite [#2] {#3} }
      { \IfValueTF {#1} { \cite [#1] {#3} } { \cite {#3} } }
    }
    \NewDocumentCommand \citep { o o m } { \__venue_citep:nnn {#1} {#2} {#3} }
    \NewDocumentCommand \citet { o o m }
    { \msg_warning:nn { venue } { no-citet } \__venue_citep:nnn {#1} {#2} {#3} }
  }
}
% Figure descriptions for screen readers; acmart asks for them.
\__venue_if_style:nF { acm }
{ \NewDocumentCommand \Description { o +m } { } }
% ACM CCS concepts are used by acmart and LIPIcs, ignored by the others.
\__venue_if_style:nF { acm , lipics }
{ \NewDocumentCommand \ccsdesc { O{} m } { } }
\cs_if_exist:NF \CCSXML
{ \NewDocumentEnvironment { CCSXML } { +b } { } { } }

% Line numbers for review.  (acmart's `review' and LIPIcs do their own.)
\bool_if:NT \g__venue_review_bool
{ \__venue_if_style:nT { lncs , ieee , article } { \AtBeginDocument { \linenumbers } } }
\bool_if:NF \g__venue_review_bool
{ \__venue_if_style:nT { lipics } { \AtBeginDocument { \nolinenumbers } } }

% ---- Notes ---------------------------------------------------------------
% \todo{...} and notes made with \newnote{\will}{Will}{blue} are inline,
% coloured and disappear with the `final' option.
\int_new:N \g__venue_notes_int
\cs_new_protected:Npn \__venue_note:nnn #1#2#3
{
  \int_gincr:N \g__venue_notes_int
  \bool_if:NTF \g__venue_final_bool
  { \unskip }
  { \textcolor {#1} { [ \tl_if_empty:nF {#2} { #2 : ~ } #3 ] } }
}
\NewDocumentCommand \newnote { m m m }
{ \cs_new_protected:Npn #1 ##1 { \__venue_note:nnn {#3} {#2} {##1} } }
\AtBeginDocument
{
  \cs_if_exist:NF \todo
  { \cs_new_protected:Npn \todo #1 { \__venue_note:nnn { red } { TODO } {#1} } }
}
\AtEndDocument
{
  \bool_if:NT \g__venue_final_bool
  {
    \int_compare:nNnT { \g__venue_notes_int } > { 0 }
      {
        \tl_set:Nx \l__venue_msg_tl { \int_use:N \g__venue_notes_int }
        \__venue_msg_warning:nnV { venue } { hidden-notes } \l__venue_msg_tl
      }
  }
}

% ===========================================================================
% 5. Bibliography style
% ===========================================================================
% The publisher's BibTeX style is selected automatically (for LNCS its
% natbib-compatible twin splncs04nat); \bibliographystyle overrides it.
\tl_new:N \g__venue_bst_tl
\tl_gset:Nx \g__venue_bst_tl
{
  \exp_args:NV \str_case:nn \g__venue_family_str
  {
    { lncs }    { splncs04nat }
      { acm }     { ACM-Reference-Format }
      { ieee }    { IEEEtranN }
      { lipics }  { plainurl }
      { article } { plainnat }
  }
}
\bool_if:NT \g__venue_natbib_bool
{
  \cs_new_eq:NN \__venue_class_bibliographystyle \bibliographystyle
  \RenewDocumentCommand \bibliographystyle { m } { \tl_gset:Nn \g__venue_bst_tl {#1} }
  \AtEndDocument { \exp_args:NV \__venue_class_bibliographystyle \g__venue_bst_tl }
}

\ExplSyntaxOff
\endinput
