#!/usr/bin/env bash
# vim: ai et fo+=rt sts=2 sw=2 tw=80
################################################################################
# File:         md-from-sh.sh
# Synopsis:     md-from-sh [-d] [-l] [-w] [-R | Fname]
# Description:  Pure bash script to generate markdown from pre-defined,
#               well-formed comments.
# Opts:         -d  - enable default content for section(s) (as appropriate).
#               -l  - list the configured section titles c/w the ordering in
#                     which they appear in the output.
#               -w  - enable warnings.
#               -R  - generate own README.
#               -W  - enable fatal warnings (implies '-w').
# Args:         Fname - the name of the input file
# Returns:      - 0 - iff no problems
#               - 1 - 
#               - 2 - warning encountered whilst fatal warnings enabled ('-w')
# Files:        None - atm.
# To Do:        - Sections
#                 - ~Core defaults.~
#                 - Synopsis - alternative entries.
#                 - Functions
#                   - Selectable
#                     - None (default).
#                     - Public.
#                     - All i.e. (public & private).
#                 - Configurable sections
#                   - Defaults
#                     - Content.
#                     - Mandatory sections.
#                   - Ordering.
#                   - Near-BNF spec for the above (section titles & ordering).
#               - Content warnings
#                 - Missing/empty section(s)
#                   - Main body.
#                   - Functions.
#                 - Missing shebang.
#               - Lists
#                 - Simple
#                   - Linear
#                     - ~Bulleted.~
#                     - Enumerated.
#                     - Variables.
#                   - Nested
#                     - Bulleted.
#                     - Enumerated.
#                     - Variables.
#                 - Composite.
#                   - Nested
#                     - Bulleted.
#                     - Enumerated.
#                     - Variables.
#               - CLI options
#                 - Generate own README i.e. README for this script.
#                 - Content generation
#                   - Default section.
#                   - ToC section.
#                   - Synopsis.
#                 - Warnings
#                   - Enable.
#                   - Fatal.
#                 - Output filename, default - ${infile/.sh/.md}.
#               - Removal of the lookahead requirement renders the file
#                 "module" redundant - remove it.
#               - Addition of comment comments ;-).
#               - Tests
#                 - Better faacilitate modular testing
#                   - Disparate contents, lists etc. specific scripts.
#                   - Helpers e.g. src/tgt file name determination.
# Notes:
# - Owing to shell options employed internally, the following command s/b used
#   when syntax checking this and subordinate scripts:
#   ```bash -nO extglob SCRIPT```
# - Wheresoever appropriate, sections are normalized to match /[:digit:]+: .*/
# - For the purposes of this exercise i.e. doc.generator.generate, there are 2
# _types_ of lists:
#   - *explicit*  - lists where standard Markdown list prefixes are used i.e.
#                   the use of `-` (bullet) or '<n>.' (numbered). Note that a
#                   '# ' prefix can also be utilized to signify explicit
#                   numbered lists.
#   - *implicit*  - implicit lists are concerned where section contents are
#                   expected to be lists and entries therein aren't explicitly
#                   defined e.g. ```Args```, ```Opts```, ```Env Vars```
#                   sections. Note that the treatment of implicit lists is
#                   dependant on the section ...
#                   - *Opts*  - each opt in the list of opt(s) may be prefixed
#                   with any one of the following (with the attendant
#                   semantics - in each case, ```DEF``` defines the opt +
#                   optional arg as either short or long)...
#                   ```- <PRE><DEF>```  | explicit  | next opt begins with the
#                                       |           | next prefix.
#                   ```<PRE><DEF>```    | implicit  | the next opt begins with
#                                       |           | the next prefix.
#                   ```<DEF>```         | implicit  | definition ends at the
#                                       |           | end-of-line.`
# ------------------------------------------------------------------------------
# Author:       D. C. Pointon FIAP MBCS (pointo1d at gmail dot com)
# Date:         Sept 2022
################################################################################
shopt -s extglob
#shopt -os errexit xtrace
declare SHOPT="$(shopt -op xtrace)"
shopt -ou xtrace

declare \
  Fname GenDefaultContent Warnings FatalWarnings OwnREADME \
  Sections=() Indents=() HdrContentOrder=(
    'Synopsis' 'Description' 'Where' 'Opts' 'Args' 'Returns' 'Env Vars' 'Notes'
  ) \
  FuncHdrOrder=( 'Function' "${HdrContentOrder[@]}" ) \
  ContentOrder=(
    'File' "${HdrContentOrder[@]}" 'Functions' 'Doc Links' 'Files'
    'To Do' 'Author' 'Date' 'Copyright' 'License'
  )

  declare -A Content=() Para=( [type]= [content]= ) \
    Sect=( [title]= [lineno]= [content]= ) \
    SectDefaults=( 
      ['File']='${Fname##*/}'
      ['Title']='${Fname##*/}'
      ['Synopsis']='\`\`\`${Fname##*/}\`\`\`'
      ['Author']='${LOGNAME:-${USERNAME:?"No user name"}}'
      ['Date']='$(date +"%A %b %d %Y")'
    )

# Initialize the variables as 1st part of dynamic section definition.
declare sect ; for sect in "${ContentOrder[@]}" ; do
  case "$sect" in
    *\|*) # Alternatives, split 'em and load 'em separately
          declare alts=() ; IFS='|' read -ra alts <<< "$sect"
          for sect in "${alts[@]}" ; do
            sect="${sect## }"
            Sections+=( "${sect%% }" )
          done
          ;;
    *)    sect="${sect## }"
          Sections+=( "${sect%% }" )
          ;;
  esac
done

eval $SHOPT

anti-infinite-loop() {
  case ${INFINITE_COUNT:-n} in
    n)  INFINITE_COUNT_VAL=${1:?'No infinite count'}
        INFINITE_COUNT=$INFINITE_COUNT_VAL
        ;;
    0)  report.fatal "Infinite count ($INFINITE_COUNT_VAL) reached" ;;
    *)  : $((INFINITE_COUNT-=1)) ;;
  esac
}

# ------------------------------------------------------------------------------
# Description:  Routine to report the given string to STDERR.
# Synopsis:     report._2-stderr STR
# Opts:         None.
# Args:         STR - the string to report on STDERR
# ------------------------------------------------------------------------------
report._2-stderr() { builtin echo -e "$*" >&2 ; }

# ------------------------------------------------------------------------------
# Description:  Routine to report the given string to STDERR as a fatal
#               message, followed by a non-zero exit.
# Synopsis:     report.fatal [RC] STR
# Opts:         None.
# Args:         RC  - optional exit code, default - 1
#               STR - the string to report on STDERR
# ------------------------------------------------------------------------------
report.fatal() {
  local rc ; case $1 in +([0-9])) rc=$1 ; shift ;; esac

  report._2-stderr "FATAL - $* !!!"

  exit ${rc:-1}
}

# ------------------------------------------------------------------------------
# Description:  Routine to report the given string to STDERR as a warning
#               message
# Synopsis:     report._warn STR
# Opts:         None.
# Args:         STR - the string to report on STDERR
# ------------------------------------------------------------------------------
report.warn() {
  report._2-stderr "WARNING - $*"

  return

  : ${Warnings:-n}:${FatalWarnings:-n}
  case ${Warnings:-n}:${FatalWarnings:-n} in
    n:n)  return ;;
    *:n)  report._2-stderr "WARNING - $*" ;;
    *)    report.fatal 2 "$* (fatal warnings enabled)" ;;
  esac
}

# ------------------------------------------------------------------------------
# Description:
# ------------------------------------------------------------------------------
report.info() { builtin echo -e "INFO - $*" ; }

# ------------------------------------------------------------------------------
# Description:
# ------------------------------------------------------------------------------
line.parser.warn() {
  local lineno=${Sect[lineno]} ; case $1 in
    +([0-9])) lineno=$1
              shift
              ;;
  esac

  report.warn "$1 - line $lineno ${2:+($2)}"
}

. ${BASH_SOURCE%%/bin/*}/lib/file.sh

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
#
# Line handler related routines
#
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Description:  Routine to determine, validate and dispatch the appropriate
#               handler for the current line.
# Env Vars:     
# ------------------------------------------------------------------------------
line.parser.get-type() {
  local shopt="$(shopt -po xtrace)"
  set +o xtrace

  local OPTARG OPTIND opt content="$@" no_prefix ret
  while getopts 'n' opt ; do
    case $opt in
      n)  no_prefix=t ;;
    esac
  done

  shift $((OPTIND - 1))

  case "$content" in
    '#'|\
    '#'+(-)|\
    '# '+(-)|\
    '#'+(#)|\
    '# '+(#))   ret=ignore ;;
    '#'+( ))    ret=para-blank ;;
    _*'()'*|\
    *._*'()'*)  ret=func-defn-prv
                ret=ignore
                ;;
    *'()'*)     ret=func-defn-pub
                ret=ignore
                ;;
    *)          content="${content### }"
                case "${content## }" in
                  [A-Z]+([- A-Za-z]):*) ret=sect-header ;;
                  *( )-*)               ret=para-list-entry-bullet ;;
                  *( )+([0-9).*)        ret=para-list-entry-enum ;;
                  *)                    : ${Sect[title]:-n}
                                        case ${Sect[title]:-n} in
                                          n)  ret=ignore ;;
                                          *)  ret=para-append ;;
                                        esac
                                        ;;
                esac
                ;;
  esac

  eval $shopt

  printf "${ret:-}"
}

# ------------------------------------------------------------------------------
# Description:  Routine to determine, validate and dispatch the appropriate
#               handler for the current line.
# Env Vars:     
# ------------------------------------------------------------------------------
line.parser.dispatch.dispatch-it() {
#  set +o xtrace
  
  local handler=$1 ; shift

  case "${handler:=$(line.parser.get-type "$@")}" in
    *.*)  : ;;
    *)    handler=line.parser.$handler ;;
  esac

  case "n$(type -t $handler)" in
    n)  report.fatal \
          "Line handler not found: '$handler' - line $(file.line.number)::\n" \
          "  '$(file.line.content)'"
        ;;
  esac

  eval $SHOPT

  : DISPATCHING $handler "$@"
  $handler "$@"
}

line.parser.sect-header() {
  local line="${1%%*( )}"

  line.parser.dispatch -h doc.builder.sect.end
  line.parser.dispatch -h doc.builder.sect.begin "$line"
}

# ------------------------------------------------------------------------------
# Description:  Routine to determine, validate and dispatch the appropriate
#               handler for the current line.
# Env Vars:     
# ------------------------------------------------------------------------------
line.parser.dispatch() {
  # ----------------------------------------------------------------------------
  # Description:  Local routine to determine, validate, report and dispatch the
  #               appropriate handler for the current line.
  # Env Vars:     
  # ----------------------------------------------------------------------------
  dispatch-it() {
    set +o xtrace
  
    local handler=$1 ; shift

    case "${handler:=$(line.parser.get-type "$@")}" in
      *.*)  : ;;
      *)    handler=line.parser.$handler ;;
    esac

    case "n$(type -t $handler)" in
      n)  report.fatal \
            "Handler not found: '$handler' - line $(file.line.number)::\n" \
            "  '$(file.line.content)'"
          ;;
    esac

    eval $SHOPT

    : DISPATCHING $handler "$@"
    $handler "$@"
  }

  set +o xtrace

  local OPTARG OPTIND opt handler
  while getopts 'h:' opt ; do
    case $opt in
      h)  handler=$OPTARG ;;
    esac
  done

  shift $((OPTIND - 1))

  local line="${1:-}" ; line="${line### }"

  : ${handler:=$(line.parser.get-type "$@")}

  case ${handler##line.parser.} in
    sect-header)    dispatch-it $handler "${line%%*( )}" ;;
    func-defn-prv)  dispatch-it doc.builder.block.abort ;;
    func-defn-pub)  dispatch-it doc.builder.block.end ;;
    para-blank)     dispatch-it doc.builder.para.end
                    dispatch-it line.parser.$handler
                    ;;
    *)              dispatch-it $handler "${line%%*( )}"
                    ;;
  esac

  eval $SHOPT
}

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
#
# Doc generation routines
#
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Description:  Routine to close out the currently open paragraph - iff theres
#               one currently open.
# Env Vars:     $Sect, $Para 
# ------------------------------------------------------------------------------
doc.builder.para.end() {
  # End the current paragraph with the obligatory newline ... iff there's alread
  # some content in the section
  : $(declare -p Sect)
  case "e${Para[content]//[:space:]}" in
    e)  : ;;
    *)  doc.builder.sect.append "${Para[content]}\n" ;;
  esac

  : $(declare -p Sect)
  
  # Reset the indent record
  Indents=()

  # Finally, reset the paragraph accumulator
  Para=( [content]= [type]= )
}

# ------------------------------------------------------------------------------
# Description:  Dummy handler - provisioned solely to accept ignored
#               lines i.e. prevent them (ignored lines) from terminating the
#               script.
# Env Vars:     None. 
# ------------------------------------------------------------------------------
doc.builder.para.append() {
  local OPTARG OPTIND opt no_prepend
  while getopts 'n' opt ; do
    case $opt in
      n)  no_prepend=t ;;
    esac
  done

  shift $((OPTIND - 1))

  case ${no_prepend:-n} in
    n)  Para[content]+="
"
        ;;
  esac

  Para[content]+="$@"
}

# ------------------------------------------------------------------------------
# Description:  
# ------------------------------------------------------------------------------
doc.builder.sect.begin() {
  local content="$*" title="${*%%:*}"

  # Extract & validate the section header
  local name ; case "${Sections[@]}" in
    "$title "*|\
    *"$title"*|\
    *" $title")  name="$sect" ;;
  esac

  case "${name:-n}" in
    n)  line.parser.warn "Unrecognised section title: $title"
        return
        ;;
  esac

  # As it's a new section, initialise the section & paragraph records
  Sect=( [title]="$title" [lineno]=$(file.line.number) [content]= )

  # Process the remaining line with the title replaced with it's equiv in
  # spaces
  local spaces="$title:" ; spaces="${spaces//[:A-Za-z]/ }" ; : ${#spaces}
  line.parser.dispatch "${content/$title:/${spaces/# /#}}"

  : $(declare -p Sect)
}

# ------------------------------------------------------------------------------
# Description:  Routine to close out the currently open section - iff theres
#               one currently open.
# Synopsis:     parser.sect.close
# Args:         None.
# Env Vars:     $Content, $Sect
# ------------------------------------------------------------------------------
doc.builder.sect.end() {
  # Ensure the open paragraph, if any, is closed out
  line.parser.dispatch -h doc.builder.para.end

  case ${Sect[title]:+y} in
    y)  # Ensure an open paragraph is appended to the section body - by
        # simulating an end-of-paragraph situation
##        line.parser.para-blank
        
        # Now do the section body itself - note that the section body is
        # prefixed by the line number on which the header was detected
        Content[${Sect[title]}]="${Sect[lineno]} ${Sect[content]}"
        : $(declare -p Content)
        ;;
  esac

  Sect=( [title]= [lineno]= [content]= )
}

# ------------------------------------------------------------------------------
# Description:  Routine to close out the currently open paragraph - iff theres
#               one currently open.
# Env Vars:     $Sect, $Para 
# ------------------------------------------------------------------------------
doc.builder.sect.append() {
  local content="${1:-}" no_spaces="${1//[[:space:]]/}"

  : ${#Sect[content]}:${#no_spaces}
  case ${#Sect[content]}:${#no_spaces} in
    0:0)  : ;;
    0:*)  Sect[content]="${@:-}" ;;
    *)    Sect[content]+="${@:-}" ;;
  esac
}

# ------------------------------------------------------------------------------
# Description:  Routine to close out the currently open paragraph - iff theres
#               one currently open.
# Env Vars:     $Sect, $Para 
# ------------------------------------------------------------------------------
doc.builder.block.end() {
  line.parser.dispatch -h doc.builder.sect.end
}

# ------------------------------------------------------------------------------
# Description:  Routine to close out the currently open paragraph - iff theres
#               one currently open.
# Env Vars:     $Sect, $Para 
# ------------------------------------------------------------------------------
doc.builder.block.append() {
  line.parser.dispatch -h line.parser.sect-append
}

# ------------------------------------------------------------------------------
# Description:  
# Env Vars:     $Para, $Sect, $Content
# ------------------------------------------------------------------------------
line.parser.eof() {
  # Close out the currently open block (if any)
  line.parser.dispatch -h doc.builder.block.end
}

# ------------------------------------------------------------------------------
# Description:  Routine to process a plain i.e. non-list, paragraph line.
# Env Vars:     $Para 
# ------------------------------------------------------------------------------
line.parser.list-entry.continue() {
  line.parser.dispatch -h line.parser.para-plain
}

# ------------------------------------------------------------------------------
# Description:  Routine to process a list paragraph entry
# Env Vars:     $Para 
# ------------------------------------------------------------------------------
line.parser.list-entry() {
  # Determine the indent level of the current line
  local indent="${1##+( )}" ; indent=$((${#1} - ${#indent}))

  # Now determine if it's at variance to the indent level of the current list
  case ${#Indents[@]} in
    0)  # There's no list as yet,so start it
        Indents=( $indent )
        ;;
    *)  # There is a list, so now determine if the current entry indentation is
        # the same as/different to the existing list
        case $((${Indents[0]} - indent)) in
          0)  # Continuation of the existing list i.e. no change
              :
              ;;
          -*) # New nested list, so push it onto the indent record
              Indents=( $indent ${Indents[@]} )
              ;;
          *)  # Reversion ... to a previous level, so attempt to find it in the
              # previous levels
              case "${Indents[@]}" in
                *" $indent"|\
                *" $indent "*)  # It's on there, so now clear the indent stack
                                # down to the current level
                                local i
                                for ((i ; i < ${#Indents[@]} ; i++)); do
                                  case ${Indents[$i]} in
                                    $indent)  # Found it
                                              break
                                              ;;
                                    *)        # Not found, so remove it
                                              Indents=( ${Indents[@]:1} )
                                              ;;
                                  esac
                                done
                                ;;
                *)              report.fatal \
                                  "Previous list indent level $indent not found"
                                ;;
              esac
              ;;
        esac
        ;;
  esac

  # Append a newline if there's an entry already present
  case ${Para[content]:-n} in
    n)  ;;
    *)  doc.builder.para.append -n "
"
        ;;
  esac

  : ${#Indents[@]}
  local indent ; case ${#Indents[@]} in
    1)  indent='' ;;
    *)  : ${#Indents[@]}, $(( ${#Indents[@]} * 2))
        indent="$(printf "%*.0s" $(( ${#Indents[@]} * 2)))"
        ;;
  esac

  doc.builder.para.append -n -- "${indent:-}${1##+( )}"
}

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
#
# Line handler routines
#
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Description:  Routine to process a plain i.e. non-list, paragraph line.
# Env Vars:     $Para 
# ------------------------------------------------------------------------------
line.parser.para-blank() {
  : $(declare -p Sect)
#  case ${#Sect[content]} in
#    0)  : ;;
#    y)  line.parser.dispatch -h doc.builder.sect.append "
#"
#        ;;
#  esac
  line.parser.dispatch -h doc.builder.sect.append "
"
}

# ------------------------------------------------------------------------------
# Description:  Routine to process a plain i.e. non-list, paragraph line.
# Env Vars:     $Para 
# ------------------------------------------------------------------------------
line.parser.para-append() {
  : "'${1:-}'"
  local content="${1##*( )}" ; content="${content%%*( )}"
  : "'${content:-}'"

  case "${Sect[title]:-n}" in n) return ;; esac

  case c${content//[[:space:]]} in c) return ;; esac

  : "'${Para[content]:+}'"
  Para[content]+="${Para[content]:+ }${content%%*( )}"
  : "'${Para[content]:+}'"
}

# ------------------------------------------------------------------------------
# Description:  Routine to process a bullet list paragraph entry
# Env Vars:     $Para 
# ------------------------------------------------------------------------------
line.parser.para-list-entry-bullet() {
  local content="$1" ; content="${content%%*( )}"
  
  line.parser.list-entry "${content### }"
}

line.parser.para-list-entry-bullet-append() { line.parser.append -n "$1" ; }

# ------------------------------------------------------------------------------
# Description:  Routine to process a bullet list paragraph entry
# Env Vars:     $Para 
# ------------------------------------------------------------------------------
line.parser.para-list-entry-enum-alt() {
  local content="$1" ; content="${content%%*( )}"
  content="${content###.+( )}"
  
  line.parser.list-entry "${content### }"
}

line.parser.para-list-entry-enum-alt() { line.parser.append -n "$1" ; }

# ------------------------------------------------------------------------------
# Description:  Routine to process a bullet list paragraph entry
# Env Vars:     $Para 
# ------------------------------------------------------------------------------
line.parser.para-list-entry-enum() {
  local content="$1" ; content="${content%%*( )}"
  content="${content##+([0-9]).+( )}"
  
  line.parser.list-entry "${content### }"
}

line.parser.para-list-entry-enum() { line.parser.append -n "$1" ; }

# ------------------------------------------------------------------------------
# Description:  Routine to process a bullet list paragraph entry
# Env Vars:     $Para 
# ------------------------------------------------------------------------------
line.parser.para-list-entry-var() {
  local content="$1" ; content="${content%%*( )}"
  
  line.parser.list-entry "${content### }"
}

line.parser.para-list-entry-var() { line.parser.append -n "$1" ; }

# ------------------------------------------------------------------------------
# Description:  Dummy handler - provisioned solely to accept ignored
#               lines i.e. prevent them (ignored lines) from terminating the
#               script.
# Env Vars:     None. 
# ------------------------------------------------------------------------------
line.parser.ignore() {
  # Line is to be ignored, but close out any open section
  case "${Sect[title]:+y}" in y) doc.builder.sect.end ;; esac
}

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Doc generator routines
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Description:  Local function to generate the default content for the given
#               section - if it has has one.
# Synopsis:     section._validate-header STR
# Opts:         None.
# Args:         $1  - the posited section name (to be validated).
# Vars:         None.
# Returns:      $1 on STDOUT iff valid, nothing/empty string otherwise.
# ------------------------------------------------------------------------------
doc.generator.generate-sect.default() {
  local sect=$"1"

  case ${SectDefaults[$sect]:-n} in
    n)  printf "# $sect\n\nNone." ;;
    *)  eval printf "# $sect\n\n$content" ;;
  esac
}

# ------------------------------------------------------------------------------
# Description:  Routine to generate the markdown for the given section ...
#               having first extracted the line number - which is always the
#               first token on the content.
# ------------------------------------------------------------------------------
doc.generator.generate-sect() {
  # Get the section name (from the args) and also the current content
  local sect="${1:?'No sect name'}" content= lineno= no_spaces

  case "${!Content[*]}" in
    "$sect"*|\
    *"$sect"*|\
    *"$sect")   # Sect's used, so determine the lineno & content
                content="${Content["$sect"]:-}"
                lineno="${content%% *}"
                content="${content##$lineno }"
                no_spaces="${content//[[:space:]]}"
                ;;
    *)          # Sect not used
                return
                ;;
  esac

  : "${#no_spaces}"
  case "${#no_spaces}" in
    0)  # It's an empty section, so report it iff default content generation
        # isn't enabled - start by defining the core message
        local msg ; case ${GenDefaultContent:-n} in
          n)  # Empty, default not enabled, so update the warning message
              msg='defaults not enabled'

              # ... and delete the "section
              unset Content["$sect"]
              ;;
          *)  # Otherwise, generate the default content for the section
              content="${SectDefaults[${sect:-$sect:-n}]:-"None."}"
              eval content="$content"

              # Update the `records'
              #Content[$sect]="$content"

              # ... and extend the warning message
              msg='default used'
              ;;
        esac

        line.parser.warn $lineno "Empty section: '$sect'" "$msg"
        ;;
  esac

  case "${#content}" in 0) return ;; esac

  case "$sect" in
   File)  printf "# $content" ;;
   *)     printf "# $1\n\n$content" ;;
  esac

  # Now the post-section marker (horiz line)
  printf "\n---\n\n"
}

# ------------------------------------------------------------------------------
# Description:  Routine to generate the entirety of the doc.generator.
# Synopsis:     doc.generator.generate
# Opts:        None.
# Args:
# Return:       
# Env Vars:     $Content
# ------------------------------------------------------------------------------
doc.generator.generate() {
  : $(declare -p Content)
  local sect ; for sect in "${Sections[@]}" ; do
    doc.generator.generate-sect "$sect"
  done

  : ${!Content[@]}
  local mt="${Content[*]}" ; mt="${mt//[[:space:]]}" ; : ${#mt}
  case "${#mt}" in
    0)  report.warn "Empty markdown"
        return
        ;;
    *)  printf "END OF FILE\n" ;;
  esac
}

################################################################################
################################################################################
########
########                          MAIN BODY
########
################################################################################
################################################################################

declare OPTARG OPTIND opt
while getopts 'dlwW' opt ; do
  case $opt in
    d)  #H# Enable default content, default - disabled
        GenDefaultContent=t
        ;;
    l)  #H# List configured section names/titles
        report.info "\
The 'standard' headings are (in order of generation)...
"
        declare sect ; while read -r sect ; do
          builtin echo "    $sect"
        done < <(printf "%s\n" "${ContentOrder[@]}")

        builtin echo -e "
Note that aliases/alternatives are indicated using the pipe ('|') symbol
"

        exit 0
        ;;
    w)  #H# Enable warnings, default - disabled
        Warnings=t
        ;;
    R)  #H# Generate README for this file
        OwnREADME=t
        ;;
    W)  #H# Enable fatal warnings (implies '-w'), default - disabled
        FatalWarnings=t
        ;;
  esac
done

shift $((OPTIND - 1))

declare Fname ; case "${OwnREADME:-n}" in
  n)  Fname="${1:-'-'}" ;;
  *)  Fname=$0 ;;
esac

# Read the given/default file
file.load "$Fname"

case $(file.is-empty ; echo $?) in 0) file.report.warn.empty-file ;; esac

eval $SHOPT

# Read & parse the whole file
while file.read-line ; do
  declare lineno=$(file.line.number) content="$(file.line.content)"
  :
  : "LINE BEGIN - $lineno: '$content'"
  :

  : $(declare -p Para)

  line.parser.dispatch "$content"

  : $(declare -p Para)

  :
  : "LINE END - $lineno: '$content'"
  :
done

line.parser.dispatch -h eof

# Before finally generating the/any markdown
doc.generator.generate

exit $?

#### END OF FILE
