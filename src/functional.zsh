#!/usr/bin/zsh

# Zsh 전용 functional.zsh 라이브러리
# Zsh의 특성(1-based indexing, Word Splitting 비활성화 등)을 고려하여 작성되었습니다.

# Zsh 호환성을 위해 SH_WORD_SPLIT 옵션을 로컬에서 적절히 활용하거나, zsh 기본 배열/문자열 조작을 활용합니다.

drop() {
  command tail -n +$(($1 + 1))
}

take() {
  command head -n ${1}
}

ltail() {
  drop 1
}

lhead() {
  take 1
}

last() {
  command tail -n 1
}

list() {
  for i in "$@"; do
    echo "$i"
  done
}

unlist() {
  cat - | xargs
}

append() {
  cat -
  list "$@"
}

prepend() {
  list "$@"
  cat -
}

lambda() {
  lam() {
    local arg
    while [[ $# -gt 0 ]]; do
      arg="$1"
      shift
      if [[ $arg = '.' ]]; then
        echo "$@"
        return
      else
        echo "read $arg;"
      fi
    done
  }

  eval $(lam "$@")
}

λ() {
  lambda "$@"
}

map() {
  if [[ $1 != "λ" ]] && [[ $1 != "lambda" ]]; then
    local has_dollar=$(list $@ | grep -F '$' | wc -l)
    if [[ $has_dollar -ne 0 ]]; then
      # Zsh에서 $를 $a로 치환하는 sed
      args=$(echo $@ | sed -e 's/\$/\$a/g')
      map λ a . $args
    else
      map λ a . "$@"' $a'
    fi
  else
    local x
    while read x; do
      echo "$x" | "$@"
    done
  fi
}

foldl() {
  local f="$@"
  local acc
  local elem
  read -r acc
  while read -r elem; do
    acc="$({ echo "$acc"; echo "$elem"; } | (eval "$f") )"
  done
  echo "$acc"
}

foldr() {
  local f="$@"
  local zero
  read -r zero
  foldrr() {
    local elem
    local acc
    if read -r elem; then
      acc=$(foldrr)
    else
      echo "$zero" && return
    fi
    acc="$({ echo "$elem"; echo "$acc"; } | (eval "$f") )"
    echo "$acc"
  }
  foldrr
}

scanl() {
  local f="$@"
  local acc
  read -r acc
  echo "$acc"
  while read -r elem; do
    acc="$({ echo "$acc"; echo "$elem"; } | (eval "$f") )"
    echo "$acc"
  done
}

mul() {
  local a=$1
  local b=$2
  [[ -z $a ]] && read -r a
  [[ -z $b ]] && read -r b
  # Zsh: a 또는 b가 누락되거나 empty인 경우 0 처리
  a=${a:-0}
  b=${b:-0}
  echo $(($a * $b))
}

plus() {
  local a=$1
  local b=$2
  [[ -z $a ]] && read -r a
  [[ -z $b ]] && read -r b
  a=${a:-0}
  b=${b:-0}
  echo $(($a + $b))
}

sub() {
  local a=$1
  local b=$2
  [[ -z $a ]] && read -r a
  [[ -z $b ]] && read -r b
  a=${a:-0}
  b=${b:-0}
  echo $(($a - $b))
}

div() {
  local a=$1
  local b=$2
  [[ -z $a ]] && read -r a
  [[ -z $b ]] && read -r b
  a=${a:-0}
  b=${b:-0}
  echo $(($a / $b))
}

mod() {
  local a=$1
  local b=$2
  [[ -z $a ]] && read -r a
  [[ -z $b ]] && read -r b
  a=${a:-0}
  b=${b:-0}
  echo $(($a % $b))
}

sum() {
  foldl "lambda a b . 'echo \$((\$a + \$b))'"
}

product() {
  foldl "lambda a b . 'echo \$(mul \$a \$b)'"
}

factorial() {
  seq 1 $1 | product
}

splitc() {
  # Zsh에서 문자를 한 줄씩 나누는 가장 간단하고 빠른 방법
  cat - | perl -pe 's/(.)/\1\n/g' | grep -v '^$'
}

join() {
  local delim=$1
  local pref=$2
  local suff=$3
  echo -n "$pref"
  local first=1
  local line
  while read line; do
    if [[ $first -eq 1 ]]; then
      echo -n "$line"
      first=0
    else
      echo -n "$delim$line"
    fi
  done
  echo "$suff"
}

revers() {
  foldl lambda a b . 'append $b $a'
}

revers_str() {
  cat - | splitc | revers | join "" "" ""
}

catch() {
  local f="$@"
  local cmd=$(cat -)
  # stderr와 exit status를 함께 캡처하기 위해 eval 사용
  local val
  val=$(eval "$cmd" 2>&1)
  local stat=$?
  # Zsh 전용: stdout으로 튜플 및 결과를 올바르게 구조화하여 전달
  $f < <(list "$cmd" $stat "$val")
}

try() {
  local f="$@"
  catch lambda cmd stat val . "[[ \$stat -eq 0 ]] && echo \"\$val\" || { $f < <(list \$stat); }"
}

ret() {
  echo "$@"
}

filter() {
  local x
  while read x; do
    ret=$(echo "$x" | "$@")
    if [[ "$ret" = "true" ]]; then
      echo "$x"
    fi
  done
}

pass() {
  echo -n ""
}

dropw() {
  local x
  while read x && [[ "$(echo "$x" | "$@")" = "true" ]]; do
    pass
  done
  [[ -n $x ]] && { echo "$x"; cat -; }
}

peek() {
  local x
  while read x; do
    if [[ $# -eq 0 ]]; then
      echo "$x" >&2
    else
      echo "$x" | "$@" >&2
    fi
    echo "$x"
  done
}

stripl() {
  local arg=$1
  local line
  while read line; do
    echo "${line#$arg}"
  done
}

stripr() {
  local arg=$1
  local line
  while read line; do
    echo "${line%$arg}"
  done
}

strip() {
  local arg=$1
  if [[ -z "$arg" ]]; then
    # Zsh의 트리밍
    local line
    while read line; do
      # 양 끝 공백 제거
      line="${line##[[:space:]]#}"
      line="${line%%[[:space:]]#}"
      echo "$line"
    done
  else
    stripl "$arg" | stripr "$arg"
  fi
}

buff() {
  local cnt=-1
  for x in $@; do
    [[ $x = '.' ]] && break
    cnt=$(plus $cnt 1)
  done
  local args=()
  local i=$cnt
  local arg
  while read arg; do
    args+=("$arg")
    if [[ ${#args[@]} -eq $cnt ]]; then
      list "${args[@]}" | "$@"
      args=()
    fi
  done
  [[ ${#args[@]} -gt 0 ]] && list "${args[@]}" | "$@"
}

tup() {
  if [[ $# -eq 0 ]]; then
    local arg
    read arg
    tup "$arg"
  else
    list "$@" | map lambda x . 'echo "${x//,/u002c}"' | join , '(' ')'
  fi
}

tupx() {
  if [[ $# -eq 1 ]]; then
    local arg
    read arg
    tupx "$1" "$arg"
  else
    local n=$1
    shift
    local clean_str=$(echo "$@" | stripl '(' | stripr ')')
    if [[ "$n" = "1-" ]]; then
      echo "$clean_str" | tr ',' '\n' | map lambda x . 'echo "${x//u002c/,}"'
    else
      echo "$clean_str" | cut -d',' -f${n} | map lambda x . 'echo "${x//u002c/,}"'
    fi
  fi
}

tupl() {
  tupx 1 "$@"
}

tupr() {
  tupx 1- "$@" | last
}

ntup() {
  if [[ $# -eq 0 ]]; then
    local arg
    read arg
    ntup "$arg"
  else
    # macOS/zsh 호환 base64 인코딩
    list "$@" | map lambda x . 'echo -n "$x" | base64' | join , '(' ')'
  fi
}

ntupx() {
  # macOS base64 디코딩 대응 래퍼
  b64dec() {
    local val
    read val
    if echo -n "$val" | base64 -D 2>/dev/null; then
      return 0
    else
      echo -n "$val" | base64 -d 2>/dev/null
    fi
  }

  if [[ $# -eq 1 ]]; then
    local arg
    read arg
    ntupx "$1" "$arg"
  else
    local n=$1
    shift
    local clean_str=$(echo "$@" | stripl '(' | stripr ')')
    if [[ "$n" = "1-" ]]; then
      echo "$clean_str" | tr ',' '\n' | map lambda x . 'echo "$x" | b64dec; echo'
    else
      echo "$clean_str" | cut -d',' -f${n} | map lambda x . 'echo "$x" | b64dec; echo'
    fi
  fi
}

ntupl() {
  ntupx 1 "$@"
}

ntupr() {
  ntupx 1- "$@" | last
}

lzip() {
  local list_str="$*"
  # Zsh 안전 분할
  local -a zip_items
  local old_ifs="$IFS"
  IFS=$' \t\n'
  zip_items=($list_str)
  IFS="$old_ifs"

  local x
  while read x; do
    local y="${zip_items[1]}"
    tup "$x" "$y"
    # shift element
    zip_items=("${zip_items[@]:1}")
  done
}

curry() {
  exportfun=$1; shift
  fun=$1; shift
  params=$*
  # Zsh 문법으로 함수 정의 작성
  cmd="function $exportfun() {
      local more_params=(\"\$@\");
      $fun $params \"\${more_params[@]}\";
  }"
  eval "$cmd"
}

with_trampoline() {
  local f=$1; shift
  local args=$@
  while [[ $f != 'None' ]]; do
    ret=$($f $args)
    f=$(tupl $ret)
    args=$(echo $ret | tupx 2- | tr '\n' ' ' | xargs)
  done
  echo $args
}

res() {
  local value=$1
  tup "None" $value
}

call() {
  local f=$1; shift
  local args=$@
  tup $f $args
}

maybe() {
  if [[ $# -eq 0 ]]; then
    local arg
    read arg
    maybe "$arg"
  else
    local x="$*"
    local value=$(echo "$x" | strip)
    if [[ -z "$value" ]]; then
      tup Nothing
    else
      tup Just "$value"
    fi
  fi
}

maybemap() {
  local x
  read x
  if [[ $(tupl "$x") = "Nothing" ]]; then
    echo "$x"
  else
    local y=$(tupr "$x")
    local r=$(echo "$y" | map "$@")
    maybe "$r"
  fi
}

maybevalue() {
  local default="$*"
  local x
  read x
  if [[ $(tupl "$x") = "Nothing" ]]; then
    echo "$default"
  else
    echo $(tupr "$x")
  fi
}

not() {
  # Zsh 호환 실행 및 반환값 처리
  local r
  r=$(eval "$@" 2>/dev/null)
  if [[ "$r" = "true" ]]; then
    ret false
  else
    ret true
  fi
}

isint() {
  [[ "$1" =~ ^-?[0-9]+$ ]] && ret true || ret false
}

isempty() {
  [[ -z "$1" ]] && ret true || ret false
}

isfile() {
  [[ -f "$1" ]] && ret true || ret false
}

isnonzerofile() {
  [[ -s "$1" ]] && ret true || ret false
}

isreadable() {
  [[ -r "$1" ]] && ret true || ret false
}

iswritable() {
  [[ -w "$1" ]] && ret true || ret false
}

isdir() {
  [[ -d "$1" ]] && ret true || ret false
}
