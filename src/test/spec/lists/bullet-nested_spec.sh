# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - lists - bullet - nested behaviours ($SHELLSPEC_SPECFILE)"
  Example "G-P: bullet-explicit-nested"
    src= md= stderr=

    for ext in sh md stderr ; do
      declare -n var=$ext

      efnm=$(find-test-file $EXAMPLES_DIR/bullet $ext bullet explicit nested)

      if test "${efnm:-}" ; then
        var=$efnm
      fi
    done

    Skip if "No source ('${sh:-}')" test ! "${sh:-}"
    Skip if 'No expectation (*.(md|stderr)' test ! "${md:-}" -a ! "${stderr:-}"

    When run script $OUT ${sh:-}
    The stdout should equal "$(<$md)"
  End
End

###### END OF FILE
