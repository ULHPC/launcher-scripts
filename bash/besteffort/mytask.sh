#! /bin/bash
################################################################################
# mytask.sh - Simple serial task having a constant duration (via a sleep)
#
# Usage: mytask.sh [duration]
################################################################################


DURATION=$1

# Set default values if unset
: ${DURATION:=2}  

echo "*** START $0 *** `hostname`: going to sleep for ${DURATION}s"
for i in `seq 1 $DURATION` ; do
  echo ! Time: $i
  sleep 1
done
echo "*** END $0 *** `hostname`: exiting"
