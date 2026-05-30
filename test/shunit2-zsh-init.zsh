#!/usr/bin/zsh

# Zsh에서 shunit2가 원활하게 돌 수 있도록 환경 옵션 지정
setopt shwordsplit
[ -n "${SHUNIT_PARENT}" ] || SHUNIT_PARENT=$0

oneTimeSetUp() {
  . ./src/functional.zsh
}

# shunit2 로드
. ./test/shunit2

