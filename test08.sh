#!/bin/dash
# input files

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

CMDS=$(mktemp cmdfile.XXXXXXXXXX)
INP1=$(mktemp input.XXXXXXXXXX)
INP2=$(mktemp input.XXXXXXXXXX)
INP3=$(mktemp input.XXXXXXXXXX)
trap 'rm -f "$CMDS" "$INP1" "$INP2" "$INP3"' INT TERM EXIT

# make commands file
echo ' /.[02468]/,$ p ; /[13579]/ s_._k_ g ; $ d ; $ q ' > $CMDS
echo ' /a/ d ; /a/ p ' >> $CMDS
echo '/b/ spepfp g ' >> $CMDS
echo '/b/ p ; 35,/print/ d ; 64 q ' >> $CMDS
echo ' s0print0rmrf0 ; /print/ d ; /rmrf/ p ; /rmrf/,5 p ' >> $CMDS
echo '3d' >> $CMDS
echo '3,5  p' >> $CMDS
echo '  /^h/ p ; p ; 2 d ; 2,4 s8.*8d8 ; $q ; 2d ; 2p ; 2q ; 1,4 p ' >> $CMDS

# make input files
seq 46 300 > $INP1
echo "
hello
world
!
!" > $INP2
tac speed.pl > $INP3

out=$(./speed.pl -f $CMDS $INP1 $INP2 $INP3)
exp=$(2041 speed -f $CMDS $INP1 $INP2 $INP3)
test "$out" = "$exp" || failed "test 1 failed: incorrect output: expected '$exp', got '$out'"
echo "test 1 passed"

out=$(./speed.pl -n -f $CMDS $INP1 $INP2 $INP3)
exp=$(2041 speed -n -f $CMDS $INP1 $INP2 $INP3)
test "$out" = "$exp" || failed "test 2 failed: incorrect output: expected '$exp', got '$out'"
echo "test 2 passed"

passed
