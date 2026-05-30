# 소개

이 라이브러리는 Bash 및 Zsh 쉘 환경에서 람다 표현식, 맵(Map), 필터(Filter), 폴드(Fold) 등 함수형 프로그래밍의 핵심 개념을 파이프라인 구조와 결합하여 간단하게 사용할 수 있도록 구현된 도구 세트입니다.

---

# 퀵 스타트

### Bash (fun.sh)

```bash
#!/bin/bash
. <(test -e src/fun.sh || curl -Ls https://raw.githubusercontent.com/andrwj/functional-bash/master/src/fun.sh > fun.sh; cat src/fun.sh)

seq 1 4 | sum
```

### Zsh (functional.zsh)

```zsh
#!/bin/zsh
# Zsh 환경에 최적화된 포팅 버전
. ./src/functional.zsh

list 1 2 3 4 | sum
```

---

# Bash와 Zsh 버전의 차이점 및 유의사항

기본적인 사용법(함수 명칭, 파이프라인 조작법)은 두 버전이 완전히 동일하나, 쉘 실행 엔진의 내부적 차이로 인해 몇 가지 유의해야 할 사항이 있습니다.

1. **읽기 전용 쉘 예약 변수 충돌 (`status`)**
   - Zsh 환경에서 `status`는 쉘 자체에서 관리하는 특별한 **읽기 전용(readonly)** 변수입니다.
   - 따라서 `try` 나 `catch` 내부의 람다 매개변수로 `status` 변수명을 직접 사용할 경우 Zsh에서 오류가 발생합니다. Zsh에서는 `status` 대신 **`stat`** 변수명을 사용해야 합니다.
     - **Bash**: `echo 'expr 2 / 0' | try λ status . 'echo $status'`
     - **Zsh**: `echo 'expr 2 / 0' | try λ stat . 'echo $stat'`
2. **`try`/`catch` 반환 구조 차이**
   - **Bash 버전**: 실행 성공 시 결과물을 `tup` 형태로 추가 래핑하여 출력합니다.
   - **Zsh 버전**: 실행 성공 시 원본 출력 텍스트 그대로 반환하도록 출력 처리가 최적화되었습니다.
3. **단어 분할(Word Splitting) 옵션**
   - Zsh는 변수 확장 시 기본적으로 단어 분할을 처리하지 않습니다. Zsh 기반 테스트 구동을 위해서는 내부적으로 `setopt shwordsplit` 처리가 포함된 셋업을 활용해야 합니다.

---

# 제공 함수 목록

| List Ops                            | Higher-Order & Map    | Math Ops                    | Data & Tuples         | Predicates             | Monad & Control     |
| :---------------------------------- | :-------------------- | :-------------------------- | :-------------------- | :--------------------- | :------------------ |
| **list** / **unlist**               | **lambda** / **λ**    | **plus** / **sub**          | **tup** / **tupx**    | **isint**              | **maybe**           |
| **take** / **drop**                 | **map**               | **mul** / **div** / **mod** | **tupl** / **tupr**   | **isempty**            | **maybemap**        |
| **lhead** / **ltail**               | **foldl** / **foldr** | **sum**                     | **ntup** / **ntupx**  | **isfile** / **isdir** | **maybevalue**      |
| **last**                            | **scanl**             | **product**                 | **ntupl** / **ntupr** | **isnonzerofile**      | **try** / **catch** |
| **append** / **prepend**            | **filter**            | **factorial**               | **lzip**              | **isreadable**         | **with_trampoline** |
| **splitc** / **join**               | **buff**              |                             |                       | **iswritable**         | **res** / **call**  |
| **revers** / **revers_str**         | **peek**              |                             |                       | **not**                | **ret** / **pass**  |
| **strip** / **stripl** / **stripr** | **curry**             |                             |                       |                        |                     |

---

## *list/unlist* (리스트 생성 및 공백 기반 해제)

```bash
$ list 1 2 3
1
2
3

$ list 1 2 3 4 5 | unlist
1 2 3 4 5
```

---

## *take/drop/ltail/lhead/last* (리스트 조작)

```bash
$ list 1 2 3 4 | drop 2
3
4

$ list 1 2 3 4 5 | lhead
1

$ list 1 2 3 4 | ltail
2
3
4

$ list 1 2 3 4 5 | last
5

$ list 1 2 3 4 5 | take 2
1
2
```

---

## *join* (리스트 조인)

```bash
$ list 1 2 3 4 5 | join ,
1,2,3,4,5

$ list 1 2 3 4 5 | join , [ ]
[1,2,3,4,5]
```

---

## *map* (매핑 연산)

```bash
$ seq 1 5 | map λ a . 'echo $((a + 5))'
6
7
8
9
10

$ list a b s d e | map λ a . 'echo $a$(echo $a | tr a-z A-Z)'
aA
bB
sS
dD
eE

$ list 1 2 3 | map echo
1
2
3

$ list 1 2 3 | map 'echo $ is a number'
1 is a number
2 is a number
3 is a number

$ list 1 2 3 4 | map 'echo \($,$\) is a point'
(1,1) is a point
(2,2) is a point
(3,3) is a point
(4,4) is a point
```

---

## *flat map* (평탄화 매핑)

```bash
$ seq 2 3 | map λ a . 'seq 1 $a' | join , [ ]
[1,2,1,2,3]

$ list a b c | map λ a . 'echo $a; echo $a | tr a-z A-z' | join , [ ]
[a,A,b,B,c,C]
```

---

## *filter* (필터링 연산)

```bash
$ seq 1 10 | filter λ a . '[[ $(mod $a 2) -eq 0 ]] && ret true || ret false'
2
4
6
8
10
```

---

## *foldl/foldr* (좌/우 폴딩 연산)

```bash
$ list a b c d | foldl λ acc el . 'echo -n $acc-$el'
a-b-c-d

# foldr은 오른쪽 요소부터 거꾸로 연산합니다.
$ list '' a b c d | foldr λ acc el .\
    'if [[ ! -z $acc ]]; then echo -n $acc-$el; else echo -n $el; fi'
d-c-b-a
```

```bash
$ seq 1 4 | foldl λ acc el . 'echo $(($acc + $el))'
10
```

```bash
$ seq 1 4 | foldl λ acc el . 'echo $(mul $(($acc + 1)) $el)'
64 # 1 + (1 + 1) * 2 + (4 + 1) * 3 + (15 + 1) * 4 = 64

$ seq 1 4 | foldr λ acc el . 'echo $(mul $(($acc + 1)) $el)'
56 # 1 + (1 + 1) * 4 + (8 + 1) * 3 + (27 + 1) * 2 = 56
```

---

## *tup/tupx/tupl/tupr* (튜플 패킹 및 항목 추출)

```bash
$ tup a 1
(a,1)

$ tup 'foo bar' 1 'one' 2
(foo bar,1,one,2)

$ tup , 1 3
(u002c,1,3)
```

```bash
$ tupl $(tup a 1)
a

$ tupr $(tup a 1)
1

$ tup , 1 3 | tupl
,

$ tup 'foo bar' 1 'one' 2 | tupl
foo bar

$ tup 'foo bar' 1 'one' 2 | tupr
2
```

```bash
$ tup 'foo bar' 1 'one' 2 | tupx 2
1

$ tup 'foo bar' 1 'one' 2 | tupx 1,3
foo bar
one

$ tup 'foo bar' 1 'one' 2 | tupx 2-4
1
one
2
```

---

## *ntup/ntupx/ntupl/ntupr* (Base64 안전 중첩 튜플)

```bash
$ ntup tuples that $(ntup safely nest)
(dHVwbGVzCg==,dGhhdAo=,KGMyRm1aV3g1Q2c9PSxibVZ6ZEFvPSkK)

echo '(dHVwbGVzCg==,dGhhdAo=,KGMyRm1aV3g1Q2c9PSxibVZ6ZEFvPSkK)' | ntupx 3 | ntupr
nest

$ ntup 'foo,bar' 1 one 1
(Zm9vLGJhcgo=,MQo=,b25lCg==,MQo=)

$ echo '(Zm9vLGJhcgo=,MQo=,b25lCg==,MQo=)' | ntupx 1
foo,bar
```

```bash
$ ntupl $(ntup 'foo bar' 1 one 2)
foo bar

$ ntupr $(ntup 'foo bar' 1 one 2)
2
```

---

## *buff* (버퍼 청크 단위 연산)

```bash
$ seq 1 10 | buff λ a b . 'echo $(($a + $b))'
3
7
11
15
19

$ seq 1 10 | buff λ a b c d e . 'echo $(($a + $b + $c + $d + $e))'
15
40
```

---

## *lzip* (두 리스트 지핑)

```bash
$ list a b c d e f | lzip $(seq 1 10)
(a,1)
(b,2)
(c,3)
(d,4)
(e,5)
(f,6)
```

```bash
$ list a b c d e f | lzip $(seq 1 10) | last | tupr
6
```

---

## *curry* (커링 함수 선언)

```bash
add2() {
    echo $(($1 + $2))
}
```

```bash
$ curry inc add2 1
```

```bash
$ inc 2
3

$ seq 1 3 | map λ a . 'inc $a'
2
3
4
```

---

## *peek* (흐름 도중 로깅 및 디버깅)

```bash
$ list 1 2 3 \
    | peek lambda a . echo 'dbg a : $a' \
    | map lambda a . 'mul $a 2' \
    | peek lambda a . echo 'dbg b : $a' \
    | sum

dbg a : 1
dbg a : 2
dbg a : 3
dbg b : 2
dbg b : 4
dbg b : 6
12
```

```bash
$ a=$(seq 1 4 | peek lambda a . echo 'dbg: $a' | sum)

dbg: 1
dbg: 2
dbg: 3
dbg: 4

$ echo $a
10
```

---

## *maybe/maybemap/maybevalue* (Maybe 모나드 연산)

```bash
$ list Hello | maybe
(Just,Hello)

$ list "   " | maybe
(Nothing)

$ list Hello | maybe | maybemap λ a . 'tr oH Oh <<<$a'
(Just,hellO)

$ list "   " | maybe | maybemap λ a . 'tr oH Oh <<<$a'
(Nothing)

$ echo bash-fun rocks | maybe | maybevalue DEFAULT
bash-fun rocks

$ echo | maybe | maybevalue DEFAULT
DEFAULT
```

---

## *not/isint/isempty* (기본 판별 프레디케이트)

```bash
$ isint 42
true

$ list blah | isint
false

$ not true
false

$ not isint 777
false

$ list 1 2 "" c d 6 | filter λ a . 'isint $a'
1
2
6

$ list 1 2 "" c d 6 | filter λ a . 'not isempty $a'
1
2
c
d
6
```

---

## *isfile/isnonzerofile/isreadable/iswritable/isdir* (시스템 상태 판별)

```bash
$ touch /tmp/foo

$ isfile /tmp/foo
true

$ not iswritable /
true

$ files="/etc/passwd /etc/sudoers /tmp /tmp/foo /no_such_file"

$ list $files | filter λ a . 'isfile $a'
/etc/passwd
/etc/sudoers
/tmp/foo

$ list $files | filter λ a . 'isdir $a'
/tmp

$ list $files | filter λ a . 'isreadable $a'
/etc/passwd
/tmp
/tmp/foo

$ list $files | filter λ a . 'iswritable $a'
/tmp
/tmp/foo

$ list $files | filter λ a . 'isnonzerofile $a'
/etc/passwd
/etc/sudoers
/tmp

$ list $files | filter λ a . 'not isfile $a'
/tmp
/no_such_file
```

---

## *try/catch* (예외 흐름 제어)

```bash
# Bash
$ echo 'expr 2 / 0' | try λ status . 'echo $status'
2

# Zsh (status 대신 stat 사용 권장)
$ echo 'expr 2 / 0' | try λ stat . 'echo $stat'
2
```

```bash
$ echo 'expr 2 / 0' \
    | LANG=en catch λ cmd stat val . 'echo cmd=$cmd,status=$stat,val=$val'
cmd=expr 2 / 0,status=2,val=expr: division by zero
```

---

## *scanl* (중간 과정 리스트 반환 폴딩)

```bash
$ seq 1 5 | scanl lambda acc el . 'echo $(($acc + $el))'
1
3
6
10
15

$ seq 1 5 | scanl lambda a b . 'echo $(($a + $b))' | last
15
```

---

## *with_trampoline/res/call* (꼬리 재귀 및 트램펄린 최적화)

```bash
factorial() {
    fact_iter() {
        local product=$1
        local counter=$2
        local max_count=$3
        if [[ $counter -gt $max_count ]]; then
            res $product
        else
            call fact_iter $(echo $counter\*$product | bc) $(($counter + 1)) $max_count
        fi
    }

    with_trampoline fact_iter 1 1 $1
}
```

```bash
$ time factorial 30 | fold -w 70
265252859812191058636308480000000

real    0m1.854s
user    0m0.072s
sys     0m0.368s
```

---

# 예제 코드 (체이닝 파이프라인)

```bash
processNames() {

  uppercase() {
     local str=$1
     echo $(tr 'a-z' 'A-Z' <<< ${str:0:1})${str:1}
  }

  list $@ \
    | filter λ name . '[[ ${#name} -gt 1 ]] && ret true || ret false' \
    | map λ name . 'uppercase $name' \
    | foldl λ acc el . 'echo $acc,$el'

}

processNames adam monika s slawek d daniel Bartek j k
```

**출력 결과:**
```bash
Adam,Monika,Slawek,Daniel,Bartek
```

---

# 테스트 실행 방법

### Bash 테스트

```bash
cd test
./test_runner
```

### Zsh 테스트

Zsh 환경 전용 통합 검증 테스트는 아래 명령어로 실행할 수 있습니다.

```bash
# SHUNIT_PARENT를 명시적으로 전달하여 shunit2 연동
SHUNIT_PARENT=test/functional_zsh_test.zsh zsh test/functional_zsh_test.zsh
```

---

# 리소스
* [영감 제공 포스트](https://quasimal.com/posts/2012-05-21-funsh.html)
* [Medium - Functional Programming in Bash](https://medium.com/@joydeepubuntu/functional-programming-in-bash-145b6db336b7)
* [Original fun.sh 라이브러리](http://ssledz.github.io/presentations/bash-fun.html#/)
