# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################
OUT=src/main/bin/generate-md.sh
EXAMPLES_DIR=${SHELLSPEC_SPECFILE%/*}/examples
FILE_DIR="$EXAMPLES_DIR/file"

Describe "$OUT - list heading command"
  md="$FILE_DIR/headings-list.md"

  It 'G-P: lists standard headings in the order seen in generated output'
    When run script $OUT -l
    The stdout should equal "$(<$md)"
  End
End

Describe "$OUT - stdin"
  xDescribe "readarray(1)/mapfile(1) appear to conflict with shellspec -"

    It "B-P: throws with no file on explicit STDIN"
      When run script $OUT -
      The status should be failure
      The stderr should equal 'FATAL - No file on STDIN !!!'
    End

    Data
      #|
    End

    It "B-P: throws with no file on default STDIN"
      When run script $OUT
      The status should be failure
      The stderr should equal 'FATAL - No file on STDIN !!!'
    End
  End
End

Describe "$OUT - file not found"
    It "B-P: throws with errant file"
      When run script $OUT not-exist
      The status should be failure
      The stderr should equal "FATAL - File not found: 'not-exist' !!!"
    End
End

Describe "$OUT - empty behaviours (1)"
  It 'G-P: completely empty file fatal'
    src="$FILE_DIR/empty-file.sh"
    stderr="$FILE_DIR/empty-file.stderr"

    Skip if "test NYI" test ! -f $stderr
  
    When run script $OUT $src
    The status should not be success
    The stderr should equal "$(<$stderr)"
  End
End

Describe "$OUT - empty behaviours (2)"
  Parameters:matrix
    single multi all
    empty blank multi
    no-default default
  End

  Example "O-N: $1-$2-$3"
    core="$1-$2-$3"
    src="$FILE_DIR/$core.sh"
    md="$FILE_DIR/$core.md"

    Skip if 'Default content generation NYI' test $3 = default
    stderr="$FILE_DIR/$1-$2-$3.stderr"

    if test ! -f $stderr ; then
      stderr=${stderr/-$2-/--}
    fi

    Skip if 'Default content generation NYI' test $3 = default
    Skip if 'No source' test ! -f $src
    Skip if 'No expectation (8.(md|stderr)' test ! -f $md -a ! -f $stderr
  
    case $2 in default) opts=d ;; esac

    When run script $OUT ${opts:-} $src
    if test -f $md ; then
      The stdout should equal "$(<$md)"
    fi
    if test -f $stderr ; then
      The stderr should equal "$(<$stderr)"
    fi
  End
End

#Describe "$OUT - empty behaviours (3)"
#  Parameters:matrix
#    all-empty all-empty-keyword-only
#    no-default default
#  End
#
#  Example "G-P: $1, '$2'"
#    src="$FILE_DIR/$1.sh"
#    md="$FILE_DIR/$1-$2.md"
#    stderr="$FILE_DIR/$1-$2.stderr"
#
#    Skip if "Default content generation NYI" test $2 = default
#  
#    case $2 in default) opts=d ;; esac
#
#    When run script $OUT ${opts:-} $src
#    if test -f $md ; then
#      The stdout should equal "$(<$md)"
#    fi
#    if test -f $stderr ; then
#      The stderr should equal "$(<$stderr)"
#    fi
#  End
#End

Describe "$OUT - Description/narrative"
  Parameters
    one-line-same-line
    one-line-line-after
    multi-line
    multi-para
  End

  Example "G-P: $1"
    src="$EXAMPLES_DIR/narrative/$1.sh"
    md="$EXAMPLES_DIR/narrative/$1.md"
    stderr="$EXAMPLES_DIR/narrative/$1.stderr"

    Skip if "NYI" test ! -f $src # -a ! -f $md -a ! -f $stderr
  
    When run script $OUT $src
    if test -f $md ; then
      The stdout should equal "$(<$md)"
    fi
    
    if test -f $stderr ; then
      The stderr should equal "$(<$stderr)"
    fi
  End
End

#Describe "$OUT - Explicit lists"
#  Parameters:matrix
#    bullet number mixed
#    simple nested
#  End
#
#  Example "G-P: - '$1, $2'"
#  lists_dir=$EXAMPLES_DIR/lists
#  root="$lists_dir/$1-$2"
#  src="$root.sh"
#  md="$root.md"
#  stderr="$root.stderr"
#
#  Skip if "test NYI" test ! -f $md -a ! -f $stderr
#  
#  When run script $OUT ${opts:-} $src
#    if test -f $md ; then
#      The stdout should equal "$(<$md)"
#    fi
#    if test -f $stderr ; then
#      The stderr should equal "$(<$stderr)"
#    fi
#  End
#End
#
#Describe "$OUT - Implicit lists"
#  Parameters
#    dollar
#    star
#  End
#
#  Example "G-P: - '$1'"
#  lists_dir=$EXAMPLES_DIR/lists
#  src="$lists_dir/$1.sh"
#  md="$lists_dir/$1.md"
#  stderr="$lists_dir/$1.stderr"
#
#  Skip if "NYI" test ! -f $md -a ! -f $stderr
#  
#  When run script $OUT ${opts:-} $src
#    if test -f $md ; then
#      The stdout should equal "$(<$md)"
#    fi
#    if test -f $stderr ; then
#      The stderr should equal "$(<$stderr)"
#    fi
#  End
#End
#
#Describe "$OUT - solely sections"
#  Parameters
#    only-file
#    only-title
#    only-synopsis
#    only-opts-explicit-single
#    only-opts-explicit-list
#    only-opts-implicit-single
#    only-opts-implicit-list
#    only-env-vars-explicit-single
#    only-env-vars-explicit-list
#    only-env-vars-implicit-single
#    only-env-vars-implicit-list
#    only-notes-explicit-single
#    only-notes-explicit-list
#    only-to-do-single
#    only-to-do--list
#    only-files-explicit-single
#    only-files-explicit-list
#    only-author
#    only-date
#    only-license
#    only-copyright
#  End
#
#  Example "G-P: $1"
#    src="$FILE_DIR/$1.sh"
#    md="$FILE_DIR/$1.md"
#    stderr="$FILE_DIR/$1.stderr"
#
#    Skip if "test NYI" test ! -f $md -a ! -f $stderr
#  
#    When run script $OUT $src
#    if test -f $md ; then
#      The stdout should equal "$(<$md)"
#    fi
#    if test -f $stderr ; then
#      The stderr should equal "$(<$stderr)"
#    fi
#  End
#End
#
###### END OF FILE
