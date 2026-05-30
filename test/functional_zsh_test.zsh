#!/usr/bin/zsh

# Zsh 전용 functional.zsh 입체적 종합 테스트
# 리스트 처리, 고차함수(map, foldl, foldr), 튜플 구조화, 에러 처리, Predicates가 유기적으로 엮여서 동작하는 것을 검증합니다.

testBasicListOperations() {
  # list, drop, take, ltail, lhead, last, unlist, append, prepend 테스트
  assertEquals "3" "$(list 1 2 3 4 5 | drop 2 | lhead)"
  assertEquals "4" "$(list 1 2 3 4 5 | take 4 | last)"
  assertEquals "1 2 3" "$(list 2 3 | prepend 1 | unlist)"
  assertEquals "1 2 3 4" "$(list 1 2 3 | append 4 | unlist)"
}

testLambdaAndHigherOrderFunctions() {
  # lambda, map, foldl, foldr 테스트
  # 1. lambda 매핑 및 map 연산
  local mapped=$(list 1 2 3 | map lambda x . 'echo $(($x * 2))' | unlist)
  assertEquals "2 4 6" "$mapped"

  # 2. lambda 단축형 λ 매핑
  local mapped_short=$(list 1 2 3 | map λ x . 'echo $(($x + 10))' | unlist)
  assertEquals "11 12 13" "$mapped_short"

  # 3. foldl을 이용한 합산
  local sum_val=$(list 1 2 3 4 5 | sum)
  assertEquals "15" "$sum_val"

  # 4. foldr을 이용한 뺄셈 (foldr은 오른쪽부터 연산 수행)
  local foldr_val=$(list 1 2 3 4 5 | foldr sub 0)
  assertEquals "-2" "$foldr_val"
}

testTuplesAndBase64Tuples() {
  # tup, tupx, tupl, tupr 테스트
  local my_tup=$(tup "apple" "banana" "cherry,grape")
  assertEquals "(apple,banana,cherryu002cgrape)" "$my_tup"
  
  assertEquals "apple" "$(echo "$my_tup" | tupl)"
  assertEquals "banana" "$(echo "$my_tup" | tupx 2)"
  assertEquals "cherry,grape" "$(echo "$my_tup" | tupr)"

  # ntup (base64 인코딩 지원 튜플)
  local my_ntup=$(ntup "hello world" "zsh functional")
  assertEquals "hello world" "$(echo "$my_ntup" | ntupl)"
  assertEquals "zsh functional" "$(echo "$my_ntup" | ntupr)"
}

testMonadicMaybeAndTryCatch() {
  # maybe 모나드 및 try/catch 테스트
  # 1. maybe
  assertEquals "(Just,hello)" "$(maybe "  hello  ")"
  assertEquals "(Nothing)" "$(maybe "   ")"

  # 2. maybemap & maybevalue
  local res_val=$(maybe "hello" | maybemap lambda x . 'echo "$x world"' | maybevalue "default")
  assertEquals "hello world" "$res_val"

  local empty_res=$(maybe "" | maybemap lambda x . 'echo "$x world"' | maybevalue "fallback")
  assertEquals "fallback" "$empty_res"

  # 3. try/catch 예외 복합 검증
  # 정상 실행 케이스
  local success_run=$(echo 'echo "ok"' | try lambda cmd stat val . 'echo "$val"')
  assertEquals "ok" "$success_run"

  # 에러 발생 케이스
  local fail_run=$(echo 'non_existent_command' | try lambda cmd stat val . 'echo "failed_code:$stat"')
  assertEquals "failed_code:127" "$fail_run"
}

testPredicatesAndFiltering() {
  # predicates (isint, isempty 등) 및 filter 복합 테스트
  local filtered_ints=$(list 1 "apple" 3 "orange" 5 | filter lambda x . 'isint $x' | unlist)
  assertEquals "1 3 5" "$filtered_ints"

  local filtered_non_ints=$(list 1 "apple" 3 "orange" 5 | filter lambda x . 'not isint $x' | unlist)
  assertEquals "apple orange" "$filtered_non_ints"
}

# Zsh 전용 shunit2 로드 및 실행
. ./test/shunit2-zsh-init.zsh
