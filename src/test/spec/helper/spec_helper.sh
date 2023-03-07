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

##find-test-file() {
##  local fnms=() dir=$1 ext=$2 ; shift 2 ; args=( ${@} )
##
##  local dec2bin=() ; eval "dec2bin=( $(printf "{0..1}%.0s" $(seq 1 $#)) )"
##
##  local i ; for i in $(seq $((${#dec2bin[@]}-1)) -1 0) ; do
##    local nm=''
##    local a ; for a in $(seq 0 $((${#dec2bin[$i]} - 1))) ; do
##      test ${dec2bin[$i]:$a:1} = 1 && nm+=${args[$a]}
##      nm+='-'
##    done
##
##    nm=$dir/${nm%-}.$ext
##    test -f $nm || continue
##
##    printf "$nm"
##    break
##  done
##}

find-test-file() {
  local dnm=${1:-$SHELLSPEC_SPECFILE%/*} ; shift
  local fnms=(
    "$2-$3-$4"
    "$2-$3-"
    "$2--$4"
    "$2--"
    "-$3-$4"
    "--$4"
    "-$3-"
    "--"
  )

  for fnm in ${fnms[@]} ; do
    fnm=$dnm/$fnm.$1
    test -f $fnm || continue

    printf "%s" $fnm
    touch $fnm
    break
  done
}

#### END OF FILE
