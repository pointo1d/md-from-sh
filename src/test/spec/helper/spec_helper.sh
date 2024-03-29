# shellcheck shell=sh

# Defining variables and functions here will affect all specfiles.
# Change shell options inside a function may cause different behavior,
# so it is better to set them here.
# set -eu

# This callback function will be invoked only once before loading specfiles.
spec_helper_precheck() {
  # Available functions: info, warn, error, abort, setenv, unsetenv
  # Available variables: VERSION, SHELL_TYPE, SHELL_VERSION
  : minimum_version "0.29.0"

  case $-:"$SHELL_TYPE" in
    *H*)  echo "bash 'type' tests broken when histexpand is enabled - aborting !!!" >&2
          exit 1
          ;;
  esac
}

# This callback function will be invoked after a specfile has been loaded.
spec_helper_loaded() {
  :
}

# This callback function will be invoked after core modules has been loaded.
spec_helper_configure() {
  :
}

specfile-setup() {
#  echo "specfile-setup() - $SHELLSPEC_SPECFILE" >&2
  # Available functions: import, before_each, after_each, before_all, after_all
  : import 'support/custom_matcher'
  export OUT=src/main/bin/md-from-sh.sh \
    EXAMPLES_DIR=${SHELLSPEC_SPECFILE%/*}/examples
    BIN_DIR=$SHELLSPEC_HELPERDIR/bin
  export LIB_DIR=${BIN_DIR/bin/lib} \
    FILE_EXAMPLES_DIR="$EXAMPLES_DIR/file"
}

find-test-file() {
  local dnm=${1:-$SHELLSPEC_SPECFILE%/*} ext=$2 ; shift 2 ; local args=($@)

  local fnms=() ; 
  eval maps="($(for ((i=1;i<=${#args[@]};i++)) ; do printf "{1..0}" ; done))"

  for map in ${maps[@]} ; do
    local c= fnm= ; for ((c=0;c<${#map};c++)) ; do
      case ${map:$c:1} in 1) fnm+="${args[$c]:-}" ;; esac
      fnm+='-'
    done

    local tfnm=$dnm/${fnm%-}.$ext
    test -f $tfnm || continue

    printf "%s" $tfnm
    touch $tfnm
    break
  done
}

#### END OF FILE
