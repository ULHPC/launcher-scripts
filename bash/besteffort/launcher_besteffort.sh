#! /bin/bash
################################################################################
# launcher_besteffort.sh -  Example of a generic launcher script
#    for running best effort jobs
#
# oarsub -S ./launcher_besteffort.sh
#
################################################################################



##########################
#                        #
#   The OAR  directives  #
#                        #
##########################
#
#          Set number of resources
#          1 core for 1 hour

#OAR -l core=1,walltime=01:00:00

#          Set the name of the job (up to 15 characters,
#          no blank spaces, start with alphanumeric character)

#OAR -n Besteffort

#          By default, the standard output and error streams are sent
#          to files in the current working directory with names:
#              OAR.%jobid%.stdout  <-  output stream
#              OAR.%jobid%.stderr  <-  error stream
#          where %job_id% is the job number assigned when the job is submitted.
#          Use the directives below to change the files to which the
#          standard output and error streams are sent, typically to a common file

#OAR -O Besteffort-%jobid%.log
#OAR -E Besteffort-%jobid%.log

#          Besteffort and idempotent:
#          OAR may kill the besteffort jobs if it is mandatory to schedule
#          jobs in the default queue.

#OAR -t besteffort

#	   If the job is killed, send signal SIGUSR2(11) 10s before killing the job ;
#          then, resubmit the job in an identical way.
#          Else, the job is terminated normally.

#OAR -t idempotent
#OAR --checkpoint 60
#OAR --signal 12


#####################################
#                                   #
#   The UL HPC specific directives  #
#                                   #
#####################################
if [ -f  /etc/profile ]; then
    .  /etc/profile
fi

#####################################
#
# Job settings
#
#####################################

# Unix signal sent by OAR, SIGUSR1 / 10
CHKPNT_SIGNAL=12

# exit value for job resubmission
EXIT_UNFINISHED=99

# The [serial] task to be executed
TASK="$HOME/mytask.sh 60"

##########################################
# Run the job
#

# DIRECTORY WHERE TO RUN
cd $WORK

# execute your command in background
$TASK &

# PID of the previous command
PID=$!

# If we receive the checkpoint signal, then, we kill $CMD,
# and we return EXIT_UNFINISHED, in order to resubmit the job

trap "kill $PID ; exit $EXIT_UNFINISHED" $CHKPNT_SIGNAL


# Wait for $CMD completion
wait $PID

# Return the exit value of $CMD
exit $?

