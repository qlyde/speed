#!/bin/dash
# -f command line option

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

TMP=$(mktemp cmdfile.XXXXXXXXXX)
trap 'rm -f "$TMP"' INT TERM EXIT

echo ' /.[02468]/,$ p ; /[13579]/ s_._k_ g ; $ d ; $ q ' > $TMP
echo ' /a/ d ; /a/ p ' >> $TMP
echo '/b/ spepfp g ' >> $TMP
echo '/b/ p ; 35,/print/ d ; 64 q ' >> $TMP
echo ' s0print0rmrf0 ; /print/ d ; /rmrf/ p ; /rmrf/,5 p ' >> $TMP
echo '3d' >> $TMP
echo '3,5  p' >> $TMP
echo '  /^h/ p ; p ; 2 d ; 2,4 s8.*8d8 ; $q ; 2d ; 2p ; 2q ; 1,4 p ' >> $TMP

out=$(cat speed.pl | ./speed.pl -f $TMP)
exp=$(cat speed.pl | 2041 speed -f $TMP)
test "$out" = "$exp" || failed "test 1 failed: incorrect output: expected '$exp', got '$out'"
echo "test 1 passed"

out=$(cat speed.pl | ./speed.pl -n -f $TMP)
exp=$(cat speed.pl | 2041 speed -n -f $TMP)
test "$out" = "$exp" || failed "test 2 failed: incorrect output: expected '$exp', got '$out'"
echo "test 2 passed"

passed
