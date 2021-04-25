#!/bin/dash
# -n command line option

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

out=$(seq 10 40 | ./speed.pl -n ' /.[02468]/ p ')
exp=$(seq 10 40 | 2041 speed -n ' /.[02468]/ p ')
test "$out" = "$exp" || failed "test 1 failed: incorrect output: expected '$exp', got '$out'"
echo "test 1 passed"

out=$(cat speed.pl | ./speed.pl -n ' /print/ p ')
exp=$(cat speed.pl | 2041 speed -n ' /print/ p ')
test "$out" = "$exp" || failed "test 2 failed: incorrect output: expected '$exp', got '$out'"
echo "test 2 passed"

out=$(echo "hello
world
!" | ./speed.pl -n '  /^h/ p  ')
exp=$(echo "hello
world
!" | 2041 speed -n '  /^h/ p  ')
test "$out" = "$exp" || failed "test 3 failed: incorrect output: expected '$exp', got '$out'"
echo "test 3 passed"

passed
