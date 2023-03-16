# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - section title listing (${SHELLSPEC_SPECFILE})"
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

###### END OF FILE
