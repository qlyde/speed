#!/bin/dash
# p - print command

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

out=$(seq 10 40 | ./speed.pl '   p   ')
exp=$(seq 10 40 | 2041 speed '   p   ')
test "$out" = "$exp" || failed "test 1 failed: incorrect output: expected '$exp', got '$out'"
echo "test 1 passed"

out=$(cat speed.pl | ./speed.pl ' /e.*k/ p ')
exp=$(cat speed.pl | 2041 speed ' /e.*k/ p ')
test "$out" = "$exp" || failed "test 2 failed: incorrect output: expected '$exp', got '$out'"
echo "test 2 passed"

out=$(echo "hello
world
!" | ./speed.pl ' /[^!d]/  p ')
exp=$(echo "hello
world
!" | 2041 speed ' /[^!d]/  p ')
test "$out" = "$exp" || failed "test 3 failed: incorrect output: expected '$exp', got '$out'"
echo "test 3 passed"

passed
