#!/usr/bin/env bash
# vim: ai et fo+=rt sts=2 sw=2 tw=80
################################################################################
# Description:
# Files:        None - atm.
# Returns:      - 0 - iff no problems
# ------------------------------------------------------------------------------
# Author:       D. C. Pointon FIAP MBCS (pointo1d at gmail dot com)
# Date:         Aug 2023
################################################################################

declare \
  Shopt='set +o xtrace' \
  Shopt_reset="$(shopt -po xtrace)"

#case ${XTRACE:-n} in
#  *${BASH_SOURCE##*/}*) Shopt='set -o xtrace' ;;
#  *)                    Shopt='set +o xtrace' ;;
#esac

eval ${Shopt:-}

declare Fname= Ptr= File=() Line=()

file.report._toStderr() { printf "$*\n" >&2 ;}

file.report.fatal() {
  eval ${Shopt:-}

  file.report._toStderr "FATAL - $* !!!"
  exit 1

  eval ${Shopt_reset:-}
}

file.report.warn() {
  eval ${Shopt:-}

  file.report._toStderr "WARNING - $*"

  eval ${Shopt_reset:-}
}

file.report.warn.empty-file() {
  file.report.warn "Empty file: '${1:-$Fname}'" 
}

# ------------------------------------------------------------------------------
# Description:  Routine to create a new file "object".
# Synopsis:     file.new [STR]
# Args:         STR - optional name of the file to operate on, no default.
# Returns:      The file handle for the new "object" (on STDOUT).
# Env Vars:     $Fname, $File
# ------------------------------------------------------------------------------
file.new() {
  eval ${Shopt:-}

  local fh=$(od -vAn -N4 -tu4 < /dev/urandom) ; fh=${fh// }

  local attr ; for attr in ${!File[@]} ; do
    case $attr in content) sw='-a' ;; esac

    eval declare ${sw:-} _${fh}_$attr
  done

  printf "%d" $fh

  eval ${Shopt_reset:-}
}

# ------------------------------------------------------------------------------
# Description:  Helper routine - returns the length of the file in terms of the
#               number of lines.
# Takes:        None.
# Returns:      The number of lines (on STDOUT).
# ------------------------------------------------------------------------------
file.length() {
  eval ${Shopt:-}

  printf "%d" ${#File[@]}

  eval ${Shopt_reset:-}
}

# ------------------------------------------------------------------------------
# Description:  Helper routine - returns the length of the file in terms of the
#               number of lines.
# Takes:        None.
# Returns:      The number of lines (on STDOUT).
# ------------------------------------------------------------------------------
file.is-empty() {
  eval ${Shopt:-}

  local rc=$(file.length) ; case $rc in 0) : ;; *) rc=1 ;; esac

  return $rc

  eval ${Shopt_reset:-}
}

# ------------------------------------------------------------------------------
# Description:  Routine to read the given file.
# Synopsis:     file.load [STR]
# Args:         STR - optional name of the file to read, default - '-'
# Env Vars:     $Fname, $File
# ------------------------------------------------------------------------------
file.load() {
  eval ${Shopt:-}

  Fname="${1:-/dev/stdin}"

  test -f $Fname || file.report.fatal "File not found: '$Fname'"

  mapfile -t File < "$Fname" || exit 1

  : STATE-FILE READ - ${#File[@]} lines from $Fname -
  : $(declare l ; for l in "${File[@]}" ; do printf "%s\n" "$l" ; done)

  eval ${Shopt_reset:-}
}

# ------------------------------------------------------------------------------
# Description:  Routine to determine (& return) the EOF state for the current
#               file.
# Takes:        None.
# Returns:      
# ------------------------------------------------------------------------------
file.name() {
  eval ${Shopt:-}

  printf "$Fname"

  eval ${Shopt_reset:-}
}

# ------------------------------------------------------------------------------
# Description:  Routine to determine (& return) the EOF state for the current
#               file.
# Takes:        None.
# Returns:      
# ------------------------------------------------------------------------------
file.eof() {
  eval ${Shopt:-}

  : $Ptr, ${#File[@]}
  case ${Ptr:-0} in
    ${#File[@]})  return 0 ;;
    *)            return 1 ;;
  esac

  eval ${Shopt_reset:-}
}

# ------------------------------------------------------------------------------
# Description:  Helper routine - returns the line number (on STDOUT) of lines.
# Takes:        None.
# Returns:      The number of lines (on STDOUT).
# ------------------------------------------------------------------------------
file.line.number() {
  eval ${Shopt:-}

  printf "%d" $((Ptr+1))

  eval ${Shopt_reset:-}
}

# ------------------------------------------------------------------------------
# Description:  Helper routine - returns the line number (on STDOUT) of lines.
# Takes:        None.
# Returns:      The number of lines (on STDOUT).
# ------------------------------------------------------------------------------
file.line.content() {
  eval ${Shopt:-}

  printf "%s" "${Line:-}"

  eval ${Shopt_reset:-}
}

# ------------------------------------------------------------------------------
# Description:  Routine to read the given line number and classify it.
# Synopsis:     file.read-line
# Takes:        None.
# Returns:      true unless the read failed for whatsoever reason - currently
#               eof.
# Env vars:     $Content  - file content.
#               $Ptr      - current file pointer.
# ------------------------------------------------------------------------------
file.read-line() {
  eval ${Shopt:-}

  local rc=0 eof=

  case $(file.length) in
    0)  rc=1 ;;
    *)  case ${Ptr:-n} in
          n)  Ptr=0 ;;
          *)  : $((Ptr+=1)) ;;
        esac

        case $(file.eof ; echo $?) in
          0)  rc=1 ;;
          1)  Line="${File[$Ptr]}" ;;
        esac
        ;;
  esac

  eval ${Shopt_reset:-}

  return $rc
}

eval ${Shopt_reset:-}

#### END OF FILE
