# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - section endings behaviours ($SHELLSPEC_SPECFILE)"
  Describe "a) post-section function"
    Parameters:matrix
      one multi
      pub prv
    End

    Example "G-P: end-$1-$2"
      # Attempt to find the appropriate expectation file(s)
      for ext in sh md ; do
        declare -n var=$ext
        declare dir=$EXAMPLES_DIR/end
        efnm=$(find-test-file $dir $ext end func $1 $2)

        if test "$efnm" ; then
          var=$efnm
        fi
      done

      Skip if "No source (in '$dir/*.sh')" test ! "${sh:-}"
      Skip if "No expectation (in '$dir/*.md')" test ! "${md:-}"
    
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
      declare dir=$EXAMPLES_DIR/end
      for ext in sh md ; do
        declare -n var=$ext
        efnm=$(find-test-file $dir $ext end $1)

        if test "$efnm" ; then
          var=$efnm
        fi
      done

      Skip if "No source (in '$dir/*.sh')" test ! "${sh:-}"
      Skip if "No expectation (in '$dir/*.md')" test ! "${md:-}"
    
      When run script $OUT ${sh:-}

      The stdout should equal "$(<$md)"
    End
  End
End

###### END OF FILE
