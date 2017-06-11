#! /bin/bash
################################################################################
# launcher_serial_ampersand.sh -  Example of a launcher script for running
# sequential tasks using the Bash & (ampersand), a builtin control operator used
# to fork processes, and the wait command.
#
# Submit this job in passive mode by
#
#   oarsub [options] -S ./launcher_serial_ampersand.sh
#
################################################################################

##########################
#                        #
#  The SLURM directives  #
#                        #
##########################
#
#          Set number of resources
#

#SBATCH -N 1                # 1 node
#SBATCH -n 28               # 28 cores·
#SBATCH --time=0-01:00:00   # 1 hour

#          Set the name of the job (up to 15 characters,
#          no blank spaces, start with alphanumeric character)

#SBATCH -J SerialAmpersand

#          By default, the standard output and error streams are sent
#          to the same file in the current working directory with name:
#              slurm-%j.out
#          where % is the job number assigned when the job is submitted.
#          Use the directive below to change the file to which the
#          standard output and error streams are sent

#SBATCH -o "SerialAmpersand-%j.out"

# Passive jobs specifications

#SBATCH -p batch
#SBATCH --qos=qos-batch

##########################
#                        #
#   The OAR  directives  #
#                        #
##########################
#
#          Set number of resources
#

#OAR -l nodes=1,walltime=1

#          Set the name of the job (up to 15 characters,
#          no blank spaces, start with alphanumeric character)

#OAR -n SerialAmpersand

#          By default, the standard output and error streams are sent
#          to files in the current working directory with names:
#              OAR.%jobid%.stdout  <-  output stream
#              OAR.%jobid%.stderr  <-  error stream
#          where %job_id% is the job number assigned when the job is submitted.
#          Use the directives below to change the files to which the
#          standard output and error streams are sent, typically to a common file

#OAR -O SerialAmpersand-%jobid%.log
#OAR -E SerialAmpersand-%jobid%.log

#####################################
#                                   #
#   The UL HPC specific directives  #
#                                   #
#####################################
if [ -f  /etc/profile ]; then
    .  /etc/profile
fi

# Modules to preload
# MODULE_TO_LOAD=(toolchain/ictce)

# Characteristics of the reservation: number of cores on the first (and normally
# only one) node
NB_CORES_HEADNODE=$(cat ${OAR_NODEFILE} | uniq -c | head -n1 | awk '{print $1}')
# Default value
: ${NB_CORES_HEADNODE:=1}

# The [serial] task to be executed i.E. your favorite
# Java/C/C++/Ruby/Perl/Python/R/whatever program to run
TASK="$HOME/mytask.sh"

# Define here a file containing the arguments to pass to the task, one line per
# expected run.
ARG_TASK_FILE=

# Total number of tasks to be executed
[ -n "${ARG_TASK_FILE}" ] && NB_TASKS=$(wc -l ${ARG_TASK_FILE}) || NB_TASKS=$(( 2*NB_CORES_HEADNODE ))

################# Let's go ###############
# Load the required modules
for m in ${MODULE_TO_LOAD[*]}; do
    module load $m
done

# DIRECTORY WHERE TO RUN
cd $WORK

if [ -z "${ARG_TASK_FILE}" ]; then
    # ============
    #  Example 1:
    # ============
    # Fork in parallel:
    #    ${TASK} 1
    #    ${TASK} 2
    #    [...]
    #    ${TASK} ${NB_TASKS}
    for i in $(seq 1 ${NB_TASKS}); do
        ${TASK} $i &
    done
else
    # ============
    #  Example 2:
    # ============
    # For each line of ${ARG_TASK_FILE}, fork in parallel:
    #    ${TASK} <line1>
    #    ${TASK} <line2>
    #    [...]
    #    ${TASK} <lastline>
    while read line; do
        ${TASK} $line &
    done < ${ARG_TASK_FILE}
fi

wait
# /!\ the wait command at the end is crucial; without it the job will terminate
#     immediately, killing the ${NB_TASKS} forked processes you just started.

