bash-utils
==========

# TABLE OF CONTENTS


<!-- vim-markdown-toc GitLab -->

* [DESCRIPTION](#description)
* [SYNOPSIS](#synopsis)
  * [Where...](#where)
* [NOTES](#notes)
  * [Well-Formed Comments](#well-formed-comments)
* [TO DO](#to-do)
* [AUTHOR](#author)

<!-- vim-markdown-toc -->

# DESCRIPTION
This repository contains a script, written in pure bash(1) i.e. non-builtin free, that takes a script - shell/perl/or any other script using a hash (`#`) as a comment character, and generates Markdown therefrom using pre-defined, well-formed comments (see [Well-Formedness](#well-formedness) below).


# SYNOPSIS
Assuming this repository to have been cloned to `$GENERATE_MD_ROOT`, the invocation is simply...

    . $GENERATE_MD_ROOT/bin/generate-md.sh FNAME

## Where...
- `FNAME` is either the name of an existing script file or the POSIX-standard `-` (for a file on STDIN).

# NOTES
## Well-Formed Comments
The appropriateness of comments is determined by their matching the following RE...

```
/^[[:space:]]*#[[:space:]]+.*/
```

i.e. a single comment character followed by 1, or more, space characters.

The failure of a line, especially a comment, to meet the above renders the line/comment to be of no interest - thereby concluding any previous block or section.

Over and above that, the generated document is considered to be formed of sections where each section header matches...

```
/^[[:space:]]*#[[:space:]][A-Z][-_[[:alnum:]]]+:.*/
```

Further note that the headings don't necessarily have to appear on consecutive lines

```
<Markdown Def>        ::= <Headings Block> <Functions Block> <Trailings Block>
<Headings Block>      ::= <File Name Block> <Synopsis> <Description> <Arg Def> <Ret Def>
<File Name Block>     ::= '# ' [ 'File' | 'Title' ':' ] <String>
<Arg Def>             ::= <Where Block> | <Args Block> | <Opts Block>
<Where Block>         ::= '# ' 'Where' ':' [ <Args Block> ] [ <Opts Block> ]
<Args Block>          ::= '# ' 'Args' ':' <Arg List>
<Opts Block>          ::= '# ' 'Opts' ':' <Opt List>
<Arg List>            ::= '-' ' ' <Arg Def> [ <Arg List> ]
<Arg Def>             ::= '$' <Arg Name> [ '-' <String> ]
<Opt List>            ::= '-' ' ' <Opt Def> [ <Opt List> ]
<Opt Def>             ::= '-' <AlphaNum> [ <Opt Arg> ] [ '-' <String> ]
<Ret Def>             ::= '# ' 'Returns' ':' <String>
<Functions Block>     ::= '# ' 'Functions' ':' <Func Block> [<Func Block> ...]
<Func Block>          ::= <Function> <Synopsis> <Description> <Arg Def> <Ret Def> <Notes> <To Do>
<Function>            ::= '# ' 'Function' ':' <Func Name> '()'
<Func Name>           ::= <First Char> [ <First Char> | [[:num:]] | '.' | '-' ]
<First Char>          ::= [[:alpha:]] | '_'
<Description>         ::= '# ' 'Description' ':' <String>
<Synopsis>            ::= '# ' 'Synopsis' ':' <Cmd Str> [<NewLine> <Cmd Str>]
<Cmd Str>             ::= <Cmd> [ <String> ]
<Trailings Block>     ::= <Notes> <To Do> <Author Block> <License Block>
<Notes>               ::= '# ' 'Notes' ':' <String>
<To Do>               ::= '# ' 'To Do' ':' <String>
<Author Block>        ::= '# ' 'Author` ':' <String> [ '(' <Email> ')' ]
<License Block>       ::= '# ' 'License' ':' <String>
```

The ordering of the headers as they appear in the generated Mwrkdown is also configurable, but by default, is as in the above list.

The default ordering of the headings comprises section heading groupings...

```
<Common Headings Block> <Functions Block> <Common Trailings Block>
```

# TO DO
- Automatically parse & validate CLI options.

# AUTHOR
D.C Pointon FIAP MBCS (pointo1d at gmail.com)
################################################################################
END OF FILE
