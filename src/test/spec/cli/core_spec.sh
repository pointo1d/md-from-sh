# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - core (${SHELLSPEC_SPECFILE})"
  Describe "section header listing from CLI"
    Describe "Basic capability"
      md="$EXAMPLES_DIR/headings-list.md"

      It 'G-P: lists configured sections, in the given order, on STDOUT'
        When run script $OUT -l
        The stdout should equal "$(<$md)"
      End
    End

    Describe "Enhanced i.e. default generator identification, capability"
      md="$EXAMPLES_DIR/headings-list-with-defaults.md"

      It 'G-P: lists configured sections with default gen capability, in the given order, on STDOUT'
        When run script $OUT -ld
        The stdout should equal "$(<$md)"
      End
    End
  End

  Describe "stdin handling"
    xDescribe "readarray(1)/mapfile(1) appear to conflict with shellspec -"

      It "B-P: throws with no file on explicit STDIN"
        When run script $OUT -
        The status should be failure
        The stderr should equal 'FATAL - No file on STDIN !!!'
      End
    End
  End

  Describe "file not found handling"
    It "B-P: throws with errant file"
      When run script $OUT not-exist
      The status should be failure
      The stderr should equal "FATAL - File not found: 'not-exist' !!!"
    End
  End
End

###### END OF FILE
