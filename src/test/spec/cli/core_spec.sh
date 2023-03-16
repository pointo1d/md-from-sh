# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - stdin handling (${SHELLSPEC_SPECFILE})"
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

###### END OF FILE
