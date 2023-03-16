# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - distributed section behaviours ($SHELLSPEC_SPECFILE)"
  Pending "Distributed sections NYI"
  Describe "a) post-section function"
    Parameters:matrix
      one multi
      pub prv
    End

    Example "G-P: end-$1-$2"
      # Attempt to find the appropriate expectation file(s)
      for ext in sh md ; do
        declare -n var=$ext
        efnm=$(find-test-file $EXAMPLES_DIR $ext end func $1 $2)

        if test "$efnm" ; then
          var=$efnm
        fi
      done

      Skip if "No source ('*.sh')" test ! "${sh:-}"
      Skip if 'No expectation (*.md)' test ! "${md:-}"
    
      When run script $OUT ${sh:-}

      The stdout should equal "$(<$md)"
    End
  End

  Describe "b) post-section non-function"
    Parameters
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

      Skip if "No source ('*.sh')" test ! "${sh:-}"
      Skip if 'No expectation (*.md)' test ! "${md:-}"
    
      When run script $OUT ${sh:-}

      The stdout should equal "$(<$md)"
    End
  End
End

###### END OF FILE
