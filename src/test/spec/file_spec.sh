# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################
OUT=src/main/lib/file.sh

Describe "$OUT"
  Describe "file not found"
    It "O-N: is fatal"
      FileName=$SHELLSPEC_TMPDIR/$RANDOM

      run-it() {
        . $OUT
        file.load $FileName
      }

      When run run-it
      The status should not be success
      The stderr should equal "FATAL - File not found: '$FileName' !!!"
    End
  End

  Random=$RANDOM
  FileName=$SHELLSPEC_TMPDIR/$Random

  Describe "Empty file '$FileName'"
    . $OUT
    > $FileName

    It "G-P: file.name() returns correctly ($FileName)"
      file.load $FileName 2>/dev/null

      When call file.name
      The stdout should equal "$FileName"
    End

    It "G-P: file.length() returns correctly (0)"
      file.load $FileName 2>/dev/null

      When call file.length
      The stdout should equal 0
    End

    It "G-P: file.eof() reports true"
      file.load $FileName 2>/dev/null

      When call file.eof
      The status should be success
    End

    It "G-P: file.read-line() reports false i.e. eof"
      file.load $FileName 2>/dev/null

      When call file.read-line
      The status should not be success
    End

    It "G-P: file.is-empty() reports true"
      file.load $FileName 2>/dev/null

      When call file.is-empty
      The status should be success
    End
  End

  Describe "Simple (one line) file ($FileName)"
    . $OUT
    echo $Random > $FileName

    It "O-N: file.load $FileName warns"
      When call file.load $FileName
      The status should be success
    End

    It "G-P: file.length() returns correctly (1)"
      file.load $FileName

      When call file.length
      The stdout should equal 1
    End

    It "G-P: file.eof() reports false"
      file.load $FileName

      When call file.eof
      The status should not be success
    End

    It "G-P: file.read-line() works correctly"
      file.load $FileName

      When call file.read-line
      The status should be success
    End

    It "G-P: file.read-line() returns correctly ('$Random')"
      file.load $FileName
      file.read-line

      When call file.line.content
      The status should be success
      The stdout should equal $Random
    End

    It "G-P: file.read-line() twice returns correctly"
      run-it() {
        file.load $FileName
        file.read-line >/dev/null
        file.read-line
      }

      When call run-it
      The status should not be success
      The stdout should equal ''
    End

    It "G-P: file.is-empty() reports false"
      file.load $FileName 2>/dev/null

      When call file.is-empty
      The status should not be success
    End
  End
End

###### END OF FILE
