# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - opts behaviours ($SHELLSPEC_SPECFILE)"
  Parameters:matrix
    short long mixed
    explicit implicit
#implicit
  End

  Example "G-P: opts-$2-$1"
    src= md= stderr=

    for ext in sh md stderr ; do
      declare -n var=$ext

      efnm=$(find-test-file $EXAMPLES_DIR/opts $ext opts $2 $1)

      if test "${efnm:-}" ; then
        var=$efnm
      fi
    done

    Skip if "No source ('*.sh' in '$EXAMPLES_DIR')" test ! "${sh:-}"
    Skip if "No expectation ('*.(md|stderr)' in '$EXAMPLES_DIR'" \
      test ! "${md:-}" -a ! "${stderr:-}"

    When run script $OUT ${sh:-}
    The stdout should equal "$(<$md)"
  End
End

###### END OF FILE
