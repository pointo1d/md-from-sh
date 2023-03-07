# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - lists - mixed/composite behaviours ($SHELLSPEC_SPECFILE)"
  Example "G-P: "
##    src= md= stderr=
##
##    for ext in sh md stderr ; do
##      declare -n var=$ext
##
##      efnm=$(find-test-file $LISTS_DIR $ext $1 $2 nested)
##
##      if test "${efnm:-}" ; then
##        var=$efnm
##      fi
##    done

    Pending "Mixed/composite lists NYI"

    Skip if "No source ('${sh:-}')" test ! "${sh:-}"
    Skip if 'No expectation (*.(md|stderr)' test ! "${md:-}" -a ! "${stderr:-}"

    When run script $OUT ${sh:-}
    The stdout should equal "$(<$md)"
  End
End

###### END OF FILE
