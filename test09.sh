#!/bin/dash
# comments and whitespace

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

out=$(seq 10 40 | ./speed.pl -n ' /.[02468]/ p  # THIS IS A COMMENT ; 2q ; 1p')
exp=$(seq 10 40 | 2041 speed -n ' /.[02468]/ p  # THIS IS A COMMENT ; 2q ; 1p')
test "$out" = "$exp" || failed "test 1 failed: incorrect output: expected '$exp', got '$out'"
echo "test 1 passed"

out=$(cat speed.pl | ./speed.pl -n ' /print/ p # PRINT
    /a/    d   #delete!     
  /the/     q#quit  ;   14p')
exp=$(cat speed.pl | 2041 speed -n ' /print/ p # PRINT
    /a/    d   #delete!     
  /the/     q#quit  ;   14p')
test "$out" = "$exp" || failed "test 2 failed: incorrect output: expected '$exp', got '$out'"
echo "test 2 passed"

out=$(echo "hello
world
!" | ./speed.pl -n '  /^h/ p  ;     s8[a-z]8[A-Z]8    g  ;  p  ; 2  , $   p ;  $    d ; $   q   ')
exp=$(echo "hello
world
!" | 2041 speed -n '  /^h/ p  ;     s8[a-z]8[A-Z]8    g  ;  p  ; 2  , $   p ;  $    d ; $   q   ')
test "$out" = "$exp" || failed "test 3 failed: incorrect output: expected '$exp', got '$out'"
echo "test 3 passed"

passed
