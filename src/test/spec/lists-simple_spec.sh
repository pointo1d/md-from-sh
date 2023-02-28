# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - lists - simple ($SHELLSPEC_SPECFILE)"
  Parameters:matrix
    # List type
    bullet numbered var
    # List spec `type'
    explicit implicit
    # List nesting
    simple nested
  End

  Example "G-P: $1-$2-$3"
    src= md= stderr=

    for ext in sh md stderr ; do
      declare -n var=$ext

      efnm=$(find-test-file $LISTS_DIR $ext $1 $2 $3)

      if test "${efnm:-}" ; then
        var=$efnm
      fi
    done

    Skip if "Implicit bullet lists not supported!!" test $1$2 = bulletimplicit
    Skip if "Numbered lists NYI!!" test $1 = numbered
    Skip if "Var lists NYI!!" test $1 = var
    Skip if "Nested lists NYI!!" test $3 = nested
    Skip if "No source ('${sh:-}')" test ! "${sh:-}"
    Skip if 'No expectation (*.(md|stderr)' test ! "${md:-}" -a ! "${stderr:-}"

    When run script $OUT ${sh:-}
    The stdout should equal "$(<$md)"
  End
End

###### END OF FILE
