# vim: ai et fo+=rt sts=2  sw=2 tw=80
################################################################################

specfile-setup

Describe "$OUT - line behaviours ($SHELLSPEC_SPECFILE)"
  It "Continued lines handled properly"
    sh=$EXAMPLES_DIR/line/continued-sect.sh
    md=${sh/.sh/.md}

    When run script $OUT $sh
    The stdout should equal "$(<$md)"
  End

  It "Muliple paragraphs handled properly"
    sh=$EXAMPLES_DIR/para/multi-para-section.sh
    md=${sh/.sh/.md}

    When run script $OUT $sh
    The stdout should equal "$(<$md)"
  End
End

###### END OF FILE
