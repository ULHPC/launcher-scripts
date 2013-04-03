#! /bin/bash
################################################################################
# launcher_checkpoint_restart.sh -  Example of a generic launcher script
#    for running best effort jobs with checkpointing (using BLCR)
#
# oarsub -S ./launcher_checkpoint_restart.sh
#
################################################################################



##########################
#                        #
#   The OAR  directives  #
#                        #
##########################
#
#          Set number of resources
#          1 core for 1 min

#OAR -l core=1,walltime=00:01:00

#          Set the name of the job (up to 15 characters,
#          no blank spaces, start with alphanumeric character)

#OAR -n Checkpoint

#          By default, the standard output and error streams are sent
#          to files in the current working directory with names:
#              OAR.%jobid%.stdout  <-  output stream
#              OAR.%jobid%.stderr  <-  error stream
#          where %job_id% is the job number assigned when the job is submitted.
#          Use the directives below to change the files to which the
#          standard output and error streams are sent, typically to a common file

#OAR -O CheckpointRestart-%jobid%.log
#OAR -E CheckpointRestart-%jobid%.log

#          Besteffort and idempotent:
#          OAR may kill the besteffort jobs if it is mandatory to schedule
#          jobs in the default queue.

#OAR -t besteffort

#	   If the job is killed, send signal SIGUSR1(10) 20s before killing the job ;
#          then, resubmit the job in an identical way.
#          Else, the job is terminated normally.

#OAR -t idempotent
#OAR --checkpoint 20
#OAR --signal 10


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
CHKPNT_SIGNAL=10

# exit value for job resubmission
EXIT_UNFINISHED=99

# The task will be executed in 100s
TASK="$HOME/mytask.sh 100"

# Checkpoint context file
CONTEXT="$WORK/mytask.context"

# Run the task with blcr libraries
RUN="cr_run $TASK"
# Terminate the process and save its context and all its child
CHECKPOINT="cr_checkpoint --save-all -f $CONTEXT --kill -T" # + Process ID
# Restart the process(es)
RESTART="cr_restart --no-restore-pid $CONTEXT"

##########################################
# Run the job
#

# DIRECTORY WHERE TO RUN
cd $WORK

if [ -f $CONTEXT ] ; then
  echo !!! Restart from checkpointed context !!!
  $RESTART &
else
  echo !!! Execute !!!
  $RUN &
fi

PID=$!

echo !!! PID  $PID !!!

# If we receive the checkpoint signal, then, we kill $CMD,
# and we return EXIT_UNFINISHED, in order to resubmit the job

trap "echo !!! Checkpointing !!! ; $CHECKPOINT $PID ; exit $EXIT_UNFINISHED" $CHKPNT_SIGNAL


# Wait for $CMD completion
wait $RUNPID
RET=$?

echo !!! Execution ended, with exit value $RET !!!

# Remove the context file
rm -f $CONTEXT

# Return the exit value of the cr_run command
exit $RET

