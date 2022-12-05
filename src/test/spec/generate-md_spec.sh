# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################
OUT=src/main/bin/generate-md.sh
EXAMPLES_DIR=${SHELLSPEC_SPECFILE%/*}/examples
FILE_DIR="$EXAMPLES_DIR/file"

Describe "$OUT - list heading command"
  md="$EXAMPLES_DIR/headings-list.md"

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

Describe "$OUT - empty behaviours"
  Parameters:matrix
    # scope (number of sections)
    none single multi all
    # Type of section entry
    empty blank multi
    #  default enabled setting
    no-default default
  End

  Example "O-N: $1-$2 ($3)"
    src= md= stderr=

    find-test-file() {
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
        fnm=$FILE_DIR/$fnm.$1
        test -f $fnm || continue

        printf "%s" $fnm
        touch $fnm
        break
      done
    }

    %logger "$1 $2 $3"
    # Attempt to find the appropriate expectation file(s)
    for ext in sh md stderr ; do
      declare -n var=$ext
      efnm=$(find-test-file $ext $1 $2 $3)

      %logger "$ext:: ${efnm:-}"
      if test "$efnm" ; then
        var=$efnm
      fi
    done

    test $3 = default && opts=d

    Skip if "Invalid empty file combination" test $1 = none -a $2 = 'blank'
    Skip if "Default content generation NYI" test $1 = none -a $3 = 'default'
    Skip if "No source ('$sh')" test ! "${sh:-}"
    Skip if 'No expectation (*.(md|stderr)' test ! "${md:-}" -a ! "${stderr:-}"
  
    When run script $OUT ${opts:+-d} $sh

    if test $1 = none -a $2 != 'multi' -a $3 = 'no-default'  ; then
      The status should not be success
    fi

    if test "${md:-}" != '' ; then
      sed "
          /%AUTHOR%/s,%AUTHOR%,${LOGNAME:-${AUTHORNAME:?"No user name"}},
          /%DATE%/s,%DATE%,$(date +"%A %b %d %Y"),
          /%FNAME%/s,%FNAME%,${sh##*/},
        " $md > $SHELLSPEC_TMPDIR/exp.md

      touch $md
      md=$SHELLSPEC_TMPDIR/exp.md

      The stdout should equal "$(<$md)"
    fi

    if test "${stderr:-}" != '' ; then
      touch $stderr
      The stderr should equal "$(<$stderr)"
    fi

    %logger ':: '
  End
End

Describe "$OUT - lists"
  Parameters:matrix
    # List type
    bullet number
    # List spec `type'
    implicit explicit
  End

End

#Describe "$OUT - Description/narrative"
#  Parameters
#    one-line-same-line
#    one-line-line-after
#    multi-line
#    multi-para
#  End
#
#  Example "G-P: $1"
#    src="$EXAMPLES_DIR/narrative/$1.sh"
#    md="$EXAMPLES_DIR/narrative/$1.md"
#    stderr="$EXAMPLES_DIR/narrative/$1.stderr"
#
#    Skip if "NYI" test ! -f $src # -a ! -f $md -a ! -f $stderr
#  
#    When run script $OUT $src
#    if test -f $md ; then
#      The stdout should equal "$(<$md)"
#    fi
#    
#    if test -f $stderr ; then
#      The stderr should equal "$(<$stderr)"
#    fi
#  End
#End
#
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
