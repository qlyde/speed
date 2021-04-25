#!/bin/dash
# multiple commands
# non / delimiters in substitute regexes

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

out=$(seq 10 40 | ./speed.pl -n ' /.[02468]/,$ p ; /[13579]/ s_._k_ g ; $ d ; $ q ')
exp=$(seq 10 40 | 2041 speed -n ' /.[02468]/,$ p ; /[13579]/ s_._k_ g ; $ d ; $ q ')
test "$out" = "$exp" || failed "test 1 failed: incorrect output: expected '$exp', got '$out'"
echo "test 1 passed"

out=$(cat speed.pl | ./speed.pl ' /a/ d ; /a/ p 
/b/ spepfp g 
/b/ p ; 35,/print/ d ; 64 q ')
exp=$(cat speed.pl | 2041 speed ' /a/ d ; /a/ p 
/b/ spepfp g 
/b/ p ; 35,/print/ d ; 64 q ')
test "$out" = "$exp" || failed "test 2 failed: incorrect output: expected '$exp', got '$out'"
echo "test 2 passed"

out=$(cat speed.pl | ./speed.pl ' s0print0rmrf0 ; /print/ d ; /rmrf/ p ; /rmrf/,5 p ')
exp=$(cat speed.pl | 2041 speed ' s0print0rmrf0 ; /print/ d ; /rmrf/ p ; /rmrf/,5 p ')
test "$out" = "$exp" || failed "test 3 failed: incorrect output: expected '$exp', got '$out'"
echo "test 3 passed"

out=$(cat speed.pl | ./speed.pl '3d
3,5  p')
exp=$(cat speed.pl | 2041 speed '3d
3,5  p')
test "$out" = "$exp" || failed "test 4 failed: incorrect output: expected '$exp', got '$out'"
echo "test 4 passed"

out=$(echo "hello
world
!" | ./speed.pl -n '  /^h/ p ; p ; 2 d ; 2,4 s8.*8d8g ; $q ; 2d ; 2p ; 2q ; 1,4 p ')
exp=$(echo "hello
world
!" | 2041 speed -n '  /^h/ p ; p ; 2 d ; 2,4 s8.*8d8g ; $q ; 2d ; 2p ; 2q ; 1,4 p ')
test "$out" = "$exp" || failed "test 5 failed: incorrect output: expected '$exp', got '$out'"
echo "test 5 passed"

passed
