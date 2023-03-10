# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - section endings behaviours ($SHELLSPEC_SPECFILE)"
  Describe "empty i.e. default/non-default, behaviours"
    Parameters
      func
      ignore
      sect
    End

    Example "G-P: end-$1"
      # Attempt to find the appropriate expectation file(s)
      for ext in sh md ; do
        declare -n var=$ext
        efnm=$(find-test-file $EXAMPLES_DIR $ext end $1)

        if test "$efnm" ; then
          var=$efnm
        fi
      done

      Skip if "No source ('$sh')" test ! "${sh:-}"
      Skip if 'No expectation (*.(md)' test ! "${md:-}"
    
      When run script $OUT $sh

      The stdout should equal "$(<$md)"
    End
  End
End

###### END OF FILE
