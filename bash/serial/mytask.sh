#! /bin/bash
################################################################################
# mytask.sh - Simple serial task having a constant duration (via a sleep)
#
# Usage: mytask.sh [duration]
################################################################################


DURATION=$1

# Det default values if unset
: ${DURATION:=2}  

echo "*** START $0 *** `hostname`: going to sleep for ${DURATION}s"
sleep ${DURATION}
echo "*** END $0 *** `hostname`: exiting"
