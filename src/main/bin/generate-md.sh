#!/usr/bin/env bash
# vim: ai et fo+=rt sts=2 sw=2 tw=80
################################################################################
# Description:
# Files:        None - atm.
# Returns:      - 0 - iff no problems
#               - 1 - 
#               - 2 - warning encountered whilst fatal warning enabled ('-w')
# To Do:        - Optional default content generation.
#               - Implement fatal/non-fatal warning functionality
#               - List processing - both explicit & implicit.
#               - Facilitate near-BNF spec for content definitions (& ordering).
#               - Missing section(s) reporting.
#               - Optional ToC generation.
#               - Auto-indented lists.
#               - Configurable sections.
#               - Configurable defaults (for empty sections).
#               - Split out content related definitions to separate file(s).
#               - Parse opts and args from code i.e. auto-synopsis generation.
# Notes:
# - Wheresoever appropriate, sections are normalized to match /[:digit:]+: .*/
# - For the purposes of this exercise i.e. markdown.generate, there are 2
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
shopt -ou errexit
declare SHOPT="$(shopt -op xtrace)"
shopt -ou xtrace

declare \
  FNAME GEN_DEFAULT_CONTENT FATAL_WARNINGS PREVIOUS \
  BLOCK=() FILE=() SECTIONS=() Indent=() HdrContentOrder=(
    'Synopsis' 'Description' 'Where' 'Opts' 'Args' 'Returns' 'Env Vars' 'Notes'
  ) \
  FuncHdrOrder=( 'Function' "${HdrContentOrder[@]}" ) \
  ContentOrder=(
    'File | Title' "${HdrContentOrder[@]}" 'Functions' 'Doc Links' 'Files'
    'To Do' 'Author' 'Date' 'Copyright' 'License'
  )

declare -A CONTENT=() CURRENT=() LOOKAHEAD=() \
  SECTION=( [name]= [lineno]= [content]= ) \
  Defaults=( 
    ['File']='${FNAME##*/}'
    ['Title']='${FNAME##*/}'
    ['Author']="${LOGNAME:-${USERNAME:?'No user name'}}"
    ['Date']="$(date)"
  )

# Initialize the variables as 1st part of dynamic section definition.
declare sect ; for sect in "${ContentOrder[@]}" ; do
  case "$sect" in
    *\|*) # Alternatives, split 'em and load 'em separately
          declare alts=() ; IFS='|' read -ra alts <<< "$sect"
          for sect in "${alts[@]}" ; do
            sect="${sect## }"
            SECTIONS+=( "${sect%% }" )
          done
          ;;
    *)    sect="${sect## }"
          SECTIONS+=( "${sect%% }" )
          ;;
  esac
done

eval $SHOPT

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
  case ${FATAL_WARNINGS:-n} in
    n)  report._2-stderr "WARNING - $*" ;;
    *)  report.fatal 2 "$* (fatal warning enabled)" ;;
  esac
}

declare INFINITE_COUNT INFINITE_COUNT_VAL
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
# Description:
# ------------------------------------------------------------------------------
report.info() { builtin echo -e "INFO - $*" ; }

# ------------------------------------------------------------------------------
# Description:
# ------------------------------------------------------------------------------
parse.report.warn() {
  local lineno=${SECTION[lineno]} ; case $1 in
    +([0-9])) lineno=$1
              shift
              ;;
  esac

  report.warn "$* - line $lineno"
}

# ------------------------------------------------------------------------------
# Description:  Routine to process the given line
# Synopsis:     read-file [STR]
# Args:         STR - optional name of the file to read, default - '-'
# Env Vars:     $FNAME, $FILE
# ------------------------------------------------------------------------------
read-file() {
  case "$1" in -) FNAME="/dev/stdin" ;; *) FNAME="$1" ;; esac

  test -f $FNAME || report.fatal "File not found: '$FNAME'"

  mapfile -t FILE < "$FNAME" || exit 1

  : ${#FILE[@]}
  case ${#FILE[@]} in 0) report.fatal "Empty file: '$FNAME'" ;; esac
}

# ------------------------------------------------------------------------------
# Description:  Routine to process the given line
# Synopsis:     file.line._proc STR
# Args:         STR - the line to process
# Env Vars:     $CONTENT
# ------------------------------------------------------------------------------
line.classify() {
  shopt -ou xtrace

  local ret=ignore vnm=${1:-CURRENT}
  local -n var=$vnm

  case ${var[eof]:-n} in
    n)  local line="${var[content]}"
        case "$line" in
          _*'()'*|\
          *._*'()'*)  ret=prv-fun-proto ;;
          *'()'*)     ret=pub-fun-proto ;;
          '# '*)      line="${line### }"
                      case "$line" in
                        [A-Z]+([a-zA-z ]):*)  ret=section-header ;;
                        +( )'#'+( )*)         ret=para-list-num-alt ;;
                        +( )+([0-9]).+( )*)   ret=para-list-num ;;
                        '$ '*)                ret=para-list-var ;;
                        *( )'- '*)            ret=para-list-bullet ;;
                        *( ))                 ret=blank ;;
                        ---)                  ret=horiz-line ;;
                        +(-)|+(\#))           : ;;
                        *)                    : ${SECTION[name]:+y}
                                              case ${SECTION[name]:+y} in
                                                y)  ret=para-plain ;;
                                              esac
                                              ;;
                      esac
                      ;;
        esac
        ;;
    *)  ret=eof ;;
  esac

  eval $SHOPT
  : $ret

  # Update the classification
  eval $vnm[class]=$ret
}

# ------------------------------------------------------------------------------
# Description:  Routine to read the given line number and classify it
#               accordingly.
# Synopsis:     file.read.line -l
# Opts:         None.
# Args:         None.
# Returns:      Line, line number and classification made via $CURRENT as a
#               direct copy of $LOOKAHEAD. Unlike file.line.lookahead, the
#               cursor _is_ updated by the call.
#               Returns true unless the read failed for whatsoever reason -
#               currently eof.
# Env vars:     $FILE, $CURRENT
# Notes:        - $CURRENT is updated, as are the current & lookahead pointers.
# ------------------------------------------------------------------------------
file.read.line() {
  shopt -ou xtrace

  # Initialize iff 1st call, otherwise bump the pointers
  case ${CURRENT[ptr]:-n} in
    n)  CURRENT=( [ptr]=0 [lineno]=1 ) ;;
    *)  CURRENT=(
          [ptr]=$((CURRENT[ptr]+=1)) [lineno]=$((${CURRENT[ptr]} + 1))
        )
        ;;
  esac

  : $(declare -p CURRENT)

  # Now load & then classify the new current line
  case ${CURRENT[ptr]} in
    ${#FILE[@]})  CURRENT[eof]=t ;;
    *)            CURRENT[content]="${FILE[${CURRENT[ptr]}]}" ;;
  esac
  
  line.classify

  eval $SHOPT

  : $(declare -p CURRENT)

  #case ${CURRENT[class]} in eof) return 1 ;; *) return 0 ;; esac
}

# ------------------------------------------------------------------------------
# Description:  Local function to validate the given posited section name.
# Synopsis:     section._validate-header STR
# Opts:         None.
# Args:         $1  - the posited section name (to be validated).
# Vars:         None.
# Returns:      $1 on STDOUT iff valid, nothing/empty string otherwise.
# ------------------------------------------------------------------------------
parse.section.find-name() {
  # Get the section name
  local sect="${1:?'No sect name'}" ; shift

  case "${SECTIONS[@]}" in
    "$sect "*|\
    *"$sect"*|\
    *" $sect")  builtin echo $sect ;;
  esac
}

# ------------------------------------------------------------------------------
# Description:
# ------------------------------------------------------------------------------
markdown.section.generate() {
  local sect="${1:?'No sect name'}" content ; content="${CONTENT["$sect"]}"

  case "c${content//[[:space:]]}" in c) return ;; esac

  case "$sect" in
    File|\
    Title)        builtin echo -e "# $content" ;;
    Synopsis)     builtin echo -e "# $1\n\n    $content" ;;
    *)            builtin echo -e "# $1\n\n$content" ;;
  esac

  printf "\n---\n"
}

# ------------------------------------------------------------------------------
# Description:
# ------------------------------------------------------------------------------
markdown.generate() {
  local sect ; for sect in "${SECTIONS[@]}" ; do
    case "${CONTENT["$sect"]:-n}" in
      n)  continue ;;
      *)  markdown.section.generate "$sect" ;;
    esac
  done

  local e="${CONTENT[*]}"
  case "e${e//[[:space:]]}" in e) : ;; *) printf "\nEND OF FILE\n" ;; esac
}

# ------------------------------------------------------------------------------
# Description:
# ------------------------------------------------------------------------------
markdown.generate-default() {
  case ${GEN_DEFAULT_CONTENT:-n} in n) return ;; esac

  markdown.generate-content
}

# ------------------------------------------------------------------------------
# Description:  Helper routine to extract the section title from the section
#               header line.
# Synopsis:     parse.section.extract-header [LINE]
# Args:         $1  - optional line to parse, default - current line.
# Env Vars:     $CURRENT
# Returns:      The parsed, but unverified, title on STDOUT
# ------------------------------------------------------------------------------
parse.section.extract-header() {
  local title="${1:-${CURRENT[content]}}"
  title="${title### }"
  printf "${title/:*}"
}

# ------------------------------------------------------------------------------
# Description:  
# Env vars:     $PARA
# ------------------------------------------------------------------------------
parse.line.blank() {
  case "${PARA:-n}" in
    n)  # Empty paragraph, so nothing to do
        :
        ;;
    *)  # Non-empty paragraph, so append it (the paragraph) to the current
        # section.
        SECTION[content]+="$PARA"
        ;;
  esac

  # Finally, reset the records as appropriate
  PARA=''
}

# ------------------------------------------------------------------------------
# Description:  Routine to close out the currently open section - iff there's
#               one currently open.
# Synopsis:     parse.section.close
# Args:         None.
# Env Vars:     $CONTENT, $SECTION
# ------------------------------------------------------------------------------
parse.section.end() {
  case "${SECTION[name]:-n}" in
    n)  return ;;
    *)  # Ensure an open paragraph is appended to the section body - by
        # simulating an end-of-paragraph situation
        parse.line.blank
        
        # Now do the section body itself
        declare content="${SECTION[content]:-}"
        : "e${content//[[:space:]]}"
        case "e${content//[[:space:]]}" in
          e)  # It's an empty section, so report it iff default content
              # generation isn't enabled
              case ${GEN_DEFAULT_CONTENT:-n} in
                n)  parse.report.warn \
                      ${SECTION[lineno]} \
                      "Empty section: '${SECTION[name]}'"
                    ;;
                *)  # Generate the default content
                    ;;
              esac
              ;;
        esac

        local content="${SECTION[content]##*( )}"
        CONTENT[${SECTION[name]}]="${content%%*( )}"
        SECTION=( [name]= [lineno]= [content]= )
        ;;
  esac
}

# ------------------------------------------------------------------------------
# Description:  
# Env vars:     $PARA, $SECTION, $CONTENT
# ------------------------------------------------------------------------------
parse.line.eof() {
  # Close out the currently open section
  parse.section.end
}

# ------------------------------------------------------------------------------
# Description:  Routine to close out the currently open paragraph - iff there's
#               one currently open.
# Env vars:     $SECTION, $PARA 
# ------------------------------------------------------------------------------
parse.para.end() {
  case ${#PARA} in
    0)  : ;;
    *)  : ${#SECTION[content]}
        case ${#SECTION[content]} in
          0)  SECTION[content]="$PARA" ;;
          *)  SECTION[content]+="

$PARA" ;;
        esac
        ;;
  esac

  PARA=''
}

# ------------------------------------------------------------------------------
# Description:  Routine to process a `plain' i.e. non-list, paragraph line.
# Env vars:     $CURRENT, $PARA 
# ------------------------------------------------------------------------------
parse.line.para-plain() {
  local content="${CURRENT[content]###*( )}" ; content="${content%%*( )}"
  
  case ${#PARA} in
    0)  PARA="$content" ;;
    *)  PARA+=" $content" ;;
  esac
}

# ------------------------------------------------------------------------------
# Description:  Dummy handler - provisioned solely to accept `ignored'
#               lines i.e. prevent them (ignored lines) from terminating the
#               script.
# Env vars:     None. 
# ------------------------------------------------------------------------------
parse.line.ignore() { : ; }

# ------------------------------------------------------------------------------
# Description:  
# Env vars:     $PREVIOUS
# ------------------------------------------------------------------------------
parse.state-change() {
  local new=$1

  # Now act using the validated class - start by determing if it's a change in
  # state i.e. the "new" class differs from the previous
  : ${PREVIOUS:-n}
  case ${PREVIOUS:-n} in
    n|\
    $parser)  # 1st time or no change since last time
              ;;
    *)        # Changed since last time - determine if there's any associated
              # action
              case $PREVIOUS:$new in
                *:eof|\
                blank:section-header|\
                ignore:section-header|\
                section-header:ignore|\
                section-header:*proto*) # End of section
                                        parse.section.end
                                        ;;
                para*:blank|\
                para*:ignore|\
                para*:*proto*)          # End of paragraph
                                        parse.para.end
                                        ;;
                para-*:para-*)          # End of current list type
                                        parse.list.end $PREVIOUS
                                        ;;
              esac
              ;;
  esac

  # Save the current state for next pass
  PREVIOUS=$new
}

# ------------------------------------------------------------------------------
# Description:  
# Env vars:     $PREVIOUS, $CURRENT, $SECTION, $PARA
# ------------------------------------------------------------------------------
parse.dispatcher() {
  #shopt -ou xtrace

  local class=${1:-${CURRENT[class]}} ; local parser=parse.line.$class

  # Attempt to validate the class
  case $(type -t $parser) in
    function) : ;;
    *)        report.fatal \
              "Unexpected line class: '${CURRENT[class]}' (no handler - '$parser')\n" \
              "For line:
                    ${CURRENT[lineno]:-EOF} - '${CURRENT[content]:-EOF}'"
              ;;
  esac

  # Detect & process state change
  case ${PREVIOUS:-} in $class) : ;; *) parse.state-change $class ;; esac

  eval $SHOPT

  # Finally, dispatch the current line parser
  eval $parser
}

# ------------------------------------------------------------------------------
# Description:  
# ------------------------------------------------------------------------------
parse.line.section-header() {
  # Extract & validate the section header
  local name="$(parse.section.find-name "$(parse.section.extract-header)")"

  case "${name:-n}" in
    n)  parse.report.warn "Unrecognised section title: $name"
        return
        ;;
  esac

  # It's a valid header, so remove it, update the classification for the line &
  # dispatch the appropriate parser for processing
  # Update the current line by replacing the title prefix with its
  # equivalent in spaces
  local spaces="$name:" ; spaces="${spaces//[:A-Za-z]/ }" ; : ${#spaces}
  CURRENT[content]="${CURRENT[content]//$name:/$spaces}"

  # As it's a new section, initialise the section  & paragraph records
  SECTION=( [name]="$name" [lineno]=${CURRENT[lineno]} [content]= )
  PARA=""

  : $(declare -p SECTION)

  # Before classifying the updated current line
  line.classify

  # And finally parsing the result
  parse.dispatcher
}

################################################################################
################################################################################
########
########                          MAIN BODY
########
################################################################################
################################################################################

declare OPTARG OPTIND opt
while getopts 'dlw' opt ; do
  case $opt in
    d)  #H# Enable default content, default - disabled
        GEN_DEFAULT_CONTENT=t
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
    w)  #H# Enable fatal warnings, default - disabled
        FATAL_WARNINGS=t
        ;;
  esac
done

shift $((OPTIND - 1))

# Read the given/default file
read-file "${1:-'-'}"

eval $SHOPT

# Read & parse the whole file
while file.read.line ; do
  : $(declare -p SECTION)
  parse.dispatcher
  : $(declare -p SECTION)

  case ${CURRENT[class]:-} in eof) break ;; esac
done

# Before finally generating the/any markdown
shopt -ou xtrace
markdown.generate

exit $?

#### END OF FILE
