#!/bin/dash
# s - substitute command

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

out=$(seq 10 40 | ./speed.pl '  s/1./545/ ')
exp=$(seq 10 40 | 2041 speed '  s/1./545/ ')
test "$out" = "$exp" || failed "test 1 failed: incorrect output: expected '$exp', got '$out'"
echo "test 1 passed"

out=$(cat speed.pl | ./speed.pl ' /a/ s/p./no/  g ')
exp=$(cat speed.pl | 2041 speed ' /a/ s/p./no/  g ')
test "$out" = "$exp" || failed "test 2 failed: incorrect output: expected '$exp', got '$out'"
echo "test 2 passed"

out=$(echo "hello
world
!" | ./speed.pl ' /o/  s/.*//  g  ')
exp=$(echo "hello
world
!" | 2041 speed ' /o/  s/.*//  g  ')
test "$out" = "$exp" || failed "test 3 failed: incorrect output: expected '$exp', got '$out'"
echo "test 3 passed"

passed
