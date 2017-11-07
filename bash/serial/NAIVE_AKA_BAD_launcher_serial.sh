#! /bin/bash -l
################################################################################
# NAIVE_AKA_BAD_launcher_serial.sh -  Example of a naive aka. (very) bad launcher script for
#    running  sequential tasks.
#
# To see a better way to handle it, see launcher_serial.sh
#
# Submit this job in passive mode by
#
#   oarsub [options] -S ./NAIVE_AKA_BAD_launcher_serial.sh
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
#SBATCH -n 1                # 1 core
#SBATCH --time=0-01:00:00   # 1 hour

#          Set the name of the job (up to 15 characters,
#          no blank spaces, start with alphanumeric character)

#SBATCH -J BADSerial

#          By default, the standard output and error streams are sent
#          to the same file in the current working directory with name:
#              slurm-%j.out
#          where % is the job number assigned when the job is submitted.
#          Use the directive below to change the file to which the
#          standard output and error streams are sent

#SBATCH -o "BADSerial-%j.out"

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

#OAR -l nodes=1,core=1,walltime=1

#          Set the name of the job (up to 15 characters,
#          no blank spaces, start with alphanumeric character)

#OAR -n BADSerial

#          By default, the standard output and error streams are sent
#          to files in the current working directory with names:
#              OAR.%jobid%.stdout  <-  output stream
#              OAR.%jobid%.stderr  <-  error stream
#          where %job_id% is the job number assigned when the job is submitted.
#          Use the directives below to change the files to which the
#          standard output and error streams are sent, typically to a common file

#OAR -O BADSerial-%jobid%.log
#OAR -E BADSerial-%jobid%.log

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
[ -n "${OAR_NODEFILE}" ]       && NB_CORES_HEADNODE=$(cat ${OAR_NODEFILE} | uniq -c | head -n1 | awk '{print $1}')
[ -n "${SLURM_CPUS_ON_NODE}" ] && NB_CORES_HEADNODE=$SLURM_CPUS_ON_NODE
# Default value
: ${NB_CORES_HEADNODE:=1}

# The [serial] task to be executed i.E. your favorite
# Java/C/C++/Ruby/Perl/Python/R/whatever program to run
TASK="$HOME/mytask.sh"

# Define here a file containing the arguments to pass to the task, one line per
# expected run.
ARG_TASK_FILE=$HOME/mytask.args.example

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
    # Run in a sequence:
    #    ${TASK} 1
    #    ${TASK} 2
    #    [...]
    #    ${TASK} ${NB_TASKS}
    for i in $(seq 1 ${NB_TASKS}); do
        ${TASK} $i
    done
else
    # ============
    #  Example 2:
    # ============
    # For each line of ${ARG_TASK_FILE}, run in a sequence:
    #    ${TASK} <line1>
    #    ${TASK} <line2>
    #    [...]
    #    ${TASK} <lastline>
    while read line; do
        ${TASK} $line
    done < ${ARG_TASK_FILE}
fi

