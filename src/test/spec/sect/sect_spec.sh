# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - sections behaviours ($SHELLSPEC_SPECFILE)"
  Describe "empty i.e. default/non-default, behaviours"
    Parameters:matrix
      # scope (number of sections)
      none single multi all
      # Type of section entry
      empty blank multi
      #  default content generation mode
      no-default default
    End

    Example "O-N: $1-$2 ($3)"
      Skip if "Invalid empty file combination" test $1 = none -a $2 = 'blank'
      Skip if "Default content generation NYI" test $1 = none -a $3 = 'default'
      Skip if "Default content generation NYI" test $3 = 'default'

      src= md= stderr=

      # Attempt to find the appropriate expectation file(s)
      for ext in sh md stderr ; do
        declare -n var=$ext
        efnm=$(find-test-file $EXAMPLES_DIR $ext $1 $2 $3)

        if test "$efnm" ; then
          var=$efnm
        fi
      done

      test $3 = default && opts=d

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

  Describe "line behaviours"
    It "Continued lines handled properly"
      sh=$EXAMPLES_DIR/continued-sect.sh
      md=${sh/.sh/.md}

      When run script $OUT $sh
      The stdout should equal "$(<$md)"
    End

    It "Muliple paragraphs handled properly"
      sh=$EXAMPLES_DIR/multi-para-section.sh
      md=${sh/.sh/.md}

      When run script $OUT $sh
      The stdout should equal "$(<$md)"
    End
  End
End

###### END OF FILE
