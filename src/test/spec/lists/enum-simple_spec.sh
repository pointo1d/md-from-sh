# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - lists - enum - simple behaviours ($SHELLSPEC_SPECFILE)"
  Parameters
    explicit
    implicit
  End

  Example "G-P: enum-$1-simple"
    src= md= stderr=

    for ext in sh md stderr ; do
      declare -n var=$ext

      efnm=$(find-test-file $EXAMPLES_DIR $ext enum $1 simple)

      if test "${efnm:-}" ; then
        var=$efnm
      fi
    done

    Skip if "Implicit enum lists NYI" test $1 = implicit

    Skip if "No source (in '$EXAMPLES_DIR')" test ! "${sh:-}"
    Skip if 'No expectation (*.(md|stderr)' test ! "${md:-}" -a ! "${stderr:-}"

    When run script $OUT ${sh:-}
    The stdout should equal "$(<$md)"
  End
End

###### END OF FILE
