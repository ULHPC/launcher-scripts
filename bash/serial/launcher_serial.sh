#! /bin/bash
################################################################################
# launcher_serial.sh -  Example of a generic launcher script using
#     [GNU Parallel](http://www.gnu.org/software/parallel/)
#
# Submit this job in passive mode by
#
#   oarsub [options] -S ./launcher_serial.sh
#
################################################################################

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

#OAR -n SerialGNUParallel

#          By default, the standard output and error streams are sent
#          to files in the current working directory with names:
#              OAR.%jobid%.stdout  <-  output stream
#              OAR.%jobid%.stderr  <-  error stream
#          where %job_id% is the job number assigned when the job is submitted.
#          Use the directives below to change the files to which the
#          standard output and error streams are sent, typically to a common file

#OAR -O SerialGNUParallel-%jobid%.log
#OAR -E SerialGNUParallel-%jobid%.log

#####################################
#                                   #
#   The UL HPC specific directives  #
#                                   #
#####################################
if [ -f  /etc/profile ]; then
    .  /etc/profile
fi

# Modules to preload
MODULE_TO_LOAD=(ictce)

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
    # use GNU parallel to perform the tasks on the node to run in
    # parallel on the ${NB_CORES_HEADNODE} cores:
    #    ${TASK} 1
    #    ${TASK} 2
    #    [...]
    #    ${TASK} ${NB_TASKS}
    seq ${NB_TASKS} | parallel -u -j ${NB_CORES_HEADNODE} ${TASK} {}
else
    # ============
    #  Example 2:
    # ============
    # use GNU parallel to perform the tasks on the node to run in
    # parallel on the ${NB_CORES_HEADNODE} cores for each line of
    # ${ARG_TASK_FILE} :
    #    ${TASK} <line1>
    #    ${TASK} <line2>
    #    [...]
    #    ${TASK} <lastline>
    cat ${ARG_TASK_FILE} | parallel -u -j ${NB_CORES_HEADNODE} --colsep ' ' ${TASK} {}
    # OR
    # parallel -u -j ${NB_CORES_HEADNODE} --colsep ' ' -a ${ARG_TASK_FILE} ${TASK} {}
fi

