#!/bin/dash
# addresses: $ and ranges

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

out=$(seq 10 40 | ./speed.pl -n ' $, $  p ')
exp=$(seq 10 40 | 2041 speed -n ' $, $  p ')
test "$out" = "$exp" || failed "test 1 failed: incorrect output: expected '$exp', got '$out'"
echo "test 1 passed"

out=$(cat speed.pl | ./speed.pl ' $,/d/ d ')
exp=$(cat speed.pl | 2041 speed ' $,/d/ d ')
test "$out" = "$exp" || failed "test 2 failed: incorrect output: expected '$exp', got '$out'"
echo "test 2 passed"

out=$(cat speed.pl | ./speed.pl -n ' 35, $ p  ')
exp=$(cat speed.pl | 2041 speed -n ' 35, $ p  ')
test "$out" = "$exp" || failed "test 3 failed: incorrect output: expected '$exp', got '$out'"
echo "test 3 passed"

# num, num
out=$(cat speed.pl | ./speed.pl ' 13,  43 d  ')
exp=$(cat speed.pl | 2041 speed ' 13,  43 d  ')
test "$out" = "$exp" || failed "test 4 failed: incorrect output: expected '$exp', got '$out'"
echo "test 4 passed"

# num, num with end < start
out=$(cat speed.pl | ./speed.pl ' 32, 1 d  ')
exp=$(cat speed.pl | 2041 speed ' 32, 1 d  ')
test "$out" = "$exp" || failed "test 5 failed: incorrect output: expected '$exp', got '$out'"
echo "test 5 passed"

# num, regex
out=$(cat speed.pl | ./speed.pl '  19,  /a/ d ')
exp=$(cat speed.pl | 2041 speed '  19,  /a/ d ')
test "$out" = "$exp" || failed "test 6 failed: incorrect output: expected '$exp', got '$out'"
echo "test 6 passed"

# regex, num
out=$(cat speed.pl | ./speed.pl '  /b/, 43 d ')
exp=$(cat speed.pl | 2041 speed '  /b/, 43 d ')
test "$out" = "$exp" || failed "test 7 failed: incorrect output: expected '$exp', got '$out'"
echo "test 7 passed"

# regex, regex
out=$(cat speed.pl | ./speed.pl '  /b/  , /c/ d ')
exp=$(cat speed.pl | 2041 speed '  /b/  , /c/ d ')
test "$out" = "$exp" || failed "test 8 failed: incorrect output: expected '$exp', got '$out'"
echo "test 8 passed"

out=$(echo "hello
world
!" | ./speed.pl ' 1 , /o/ d ')
exp=$(echo "hello
world
!" | 2041 speed ' 1 , /o/ d ')
test "$out" = "$exp" || failed "test 9 failed: incorrect output: expected '$exp', got '$out'"
echo "test 9 passed"

passed
