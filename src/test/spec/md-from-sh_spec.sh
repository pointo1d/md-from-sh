# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################
OUT=src/main/bin/md-from-sh.sh
EXAMPLES_DIR=${SHELLSPEC_SPECFILE%/*}/examples
FILE_DIR="$EXAMPLES_DIR/file"
LISTS_DIR="$EXAMPLES_DIR/lists"

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

Describe "$OUT - empty i.e. default/non-default, behaviours"
  Parameters:matrix
    # scope (number of sections)
#none
    none single multi all
    # Type of section entry
    empty blank multi
    #  default content generation mode
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

    # Attempt to find the appropriate expectation file(s)
    for ext in sh md stderr ; do
      declare -n var=$ext
      efnm=$(find-test-file $ext $1 $2 $3)

      if test "$efnm" ; then
        var=$efnm
      fi
    done

    test $3 = default && opts=d

    Skip if "Invalid empty file combination" test $1 = none -a $2 = 'blank'
    Skip if "Default content generation NYI" test $1 = none -a $3 = 'default'
    Skip if "Default content generation NYI" test $3 = 'default'
    Skip if "No source ('$sh')" test ! "${sh:-}"
    Skip if 'No expectation (*.(md|stderr)' test ! "${md:-}" -a ! "${stderr:-}"
  
    When run script $OUT ${opts:+-d} $sh

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
  End
End

Describe "$OUT - line behaviours"
  It "Continued lines handled properly"
    sh=$FILE_DIR/continued-sect.sh
    md=${sh/.sh/.md}

    When run script $OUT $sh
    The stdout should equal "$(<$md)"
  End

  It "Muliple paragraphs handled properly"
    sh=$FILE_DIR/multi-para-section.sh
    md=${sh/.sh/.md}

    When run script $OUT $sh
    The stdout should equal "$(<$md)"
  End
End

Describe "$OUT - simple & nested list behaviours"
End


Describe "$OUT - lists"
  Parameters:matrix
    # List type
    bullet numbered var mixed
    # List spec `type'
    explicit implicit
    # List nesting
    linear nested
  End

  Example "G-P: $1-$2-$3"
    src= md= stderr=

    find-test-file() {
#      %logger "find-test-file($1, $2, $3, $4)"
      local fnms=() dir=$1 ext=$2 ; shift 2 ; args=( ${@} )

      local dec2bin=() ; eval "dec2bin=( $(printf "{0..1}%.0s" $(seq 1 $#)) )"
      
      local i ; for i in $(seq $((${#dec2bin[@]}-1)) -1 0) ; do
        local nm=''
        local a ; for a in $(seq 0 $((${#dec2bin[$i]} - 1))) ; do
          test ${dec2bin[$i]:$a:1} = 1 && nm+=${args[$a]}
          nm+='-'
        done

        nm=$dir/${nm%-}.$ext
        test -f $nm || continue

        printf "$nm"
        break
      done
    }

#    %logger "$1 $2 $3"

    for ext in sh md stderr ; do
      declare -n var=$ext

      efnm=$(find-test-file $LISTS_DIR $ext $1 $2 $3)

#      %logger "$ext:: ${efnm:-}"
      if test "${efnm:-}" ; then
        var=$efnm
      fi
    done

    Skip if "Implicit bullet lists not supported!!" test $1$2 = bulletimplicit
    Skip if "Numbered lists NYI!!" test $1 = numbered
    Skip if "Var lists NYI!!" test $1 = var
    Skip if "Mixed lists NYI!!" test $1 = mixed
    Skip if "Nested lists NYI!!" test $3 = nested
    Skip if "No source ('${sh:-}')" test ! "${sh:-}"
    Skip if 'No expectation (*.(md|stderr)' test ! "${md:-}" -a ! "${stderr:-}"

    When run script $OUT ${sh:-}
    The stdout should equal "$(<$md)"
  End
End

Describe "$OUT - composite list behaviours"
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

###### END OF FILE
