# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - distributed section behaviours ($SHELLSPEC_SPECFILE)"
  Describe "a) post-section function"
    Parameters
      default
      append
      overwr
    End

    Example "G-P: dist-$1"
      # Attempt to find the appropriate expectation file(s)
      for ext in sh md ; do
        declare dir=$EXAMPLES_DIR/dist
        declare -n var=$ext
        efnm=$(find-test-file $dir $ext sect $1)

        if test "$efnm" ; then
          var=$efnm
        fi
      done

      Skip if "No source (in '$dir/*.sh')" test ! "${sh:-}"
      Skip if "No expectation (in '$dir/$*.md')" test ! "${md:-}"
      Skip if "Distributed section append NYI!!!" test $1 = append
      
      declare opt='' ; if test $1 = append ; then opt='-S' ; fi

      When run script $OUT ${opt:-} ${sh:-}

      The stdout should equal "$(<$md)"
    End
  End
End

###### END OF FILE
