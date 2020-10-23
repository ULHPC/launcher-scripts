#! /bin/bash
################################################################################
# parallel_launcher.sh -  Example of a generic launcher script using
#     [GNU Parallel](http://www.gnu.org/software/parallel/) able to run a
#     program  across reserved nodes.
#
# Submit this job in passive mode by
#
#   oarsub [options] -S ./parallel_launcher.sh
################################################################################

##########################
#                        #
#  The SLURM directives  #
#                        #
##########################
#
#          Set number of resources
#

#SBATCH -N 2                # 2 nodes
#SBATCH -n 56               # 28 cores / node·
#SBATCH --time=0-01:00:00   # 1 hour

#          Set the name of the job (up to 15 characters,
#          no blank spaces, start with alphanumeric character)

#SBATCH -J GNUParallel

#          By default, the standard output and error streams are sent
#          to the same file in the current working directory with name:
#              slurm-%j.out
#          where % is the job number assigned when the job is submitted.
#          Use the directive below to change the file to which the
#          standard output and error streams are sent

#SBATCH -o "GNUParallel-%j.out"

# Passive jobs specifications

#SBATCH -p batch
#SBATCH --qos=normal

##########################
#                        #
#   The OAR  directives  #
#                        #
##########################
#
#          Set number of resources
#

#OAR -l nodes=2

#          Set the name of the job (up to 15 characters,
#          no blank spaces, start with alphanumeric character)

#OAR -n GNUParallel

#          By default, the standard output and error streams are sent
#          to files in the current working directory with names:
#              OAR.%jobid%.stdout  <-  output stream
#              OAR.%jobid%.stderr  <-  error stream
#          where %job_id% is the job number assigned when the job is submitted.
#          Use the directives below to change the files to which the
#          standard output and error streams are sent, typically to a common file

#OAR -O GNUParallel-%jobid%.log
#OAR -E GNUParallel-%jobid%.log

#####################################
#                                   #
#   The UL HPC specific directives  #
#                                   #
#####################################
if [ -f  /etc/profile ]; then
    .  /etc/profile
fi

if [ -n "$OAR_JOBID" ] ; then
  NODEFILE=$OAR_NODEFILE
  JOBID=$OAR_JOBID
  GP_WRAPPER=gpoarsh
elif [ -n "$SLURM_JOBID" ] ; then
  NODEFILE=/tmp/slurm_nodefile_$SLURM_JOBID
  srun hostname | sort -n > $NODEFILE
  JOBID=$SLURM_JOBID
  GP_WRAPPER=gpssh
fi


# Modules to preload
# MODULE_TO_LOAD=(toolchain/intel)

# Characteristics of the reservation
NB_HOSTS=$(cat ${NODEFILE} | uniq | wc -l)

# The [serial] task to be executed i.E. your favorite
# Java/C/C++/Ruby/Perl/Python/R/whatever program to be invoked in parallel
TASK="$HOME/mytask.sh"

# Define here a file containing the arguments to pass to the task, one line per
# exected run
ARG_TASK_FILE=

# Total number of tasks to be executed
[ -n "${ARG_TASK_FILE}" ] && NB_TASKS=$(wc -l ${ARG_TASK_FILE}) || NB_TASKS=$(( 2*NB_HOSTS ))

# Number of concurrent cores that have to be used on a node to perform a single task
NB_CORE_PER_TASK=6

#####################################
#                                   #
#   The GNU parallel directives     #
#                                   #
#####################################
# File with sshlogins. The file consists of sshlogins on separate lines.
GP_SSHLOGINFILE=/tmp/gnuparallel_hostfile.${JOBID}

# Eventually drop here the options you want to pass to GNU parallel
GP_OPTS=

# Location of the GNU parallel specific wrapper around oarsh
GP_WRAPPER_FILE=/opt/apps/wrappers/${GP_WRAPPER}
[ ! -f ${GP_WRAPPER_FILE} ] && GP_WRAPPER_FILE=$(git rev-parse --show-toplevel)/wrappers/${GP_WRAPPER}
[ ! -f ${GP_WRAPPER_FILE} ] && echo "Could not find the wrapper script 'gpoarsh'!"  && exit 1

################# Let's go ###############
# Load the required modules
for m in ${MODULE_TO_LOAD[*]}; do
    module load $m
done

# DIRECTORY WHERE TO RUN
cd $WORK

# Prepare an sshloginfile for GNU parallel to define connection to remote nodes.
# 3 versions are defined here:
#    1. ${GP_SSHLOGINFILE}.core : each line correspond exactly to 1 core on a node
#    2. ${GP_SSHLOGINFILE}.node : each line correspond exactly to 1 node, thus
#       of the format
#           <#cores>/oarsh <hostname>
#    3. {GP_SSHLOGINFILE}.task : each line correspond exactly to the
#       resource of one task as defined by ${NB_CORE_PER_TASK}, thus of the format
#           <#core_per_task>/oarsh <hostname>

JOBMODULELIST="$(printf :%s ${MODULE_TO_LOAD[@]})"
cat $NODEFILE | awk -v gpw=$GP_WRAPPER_FILE -v jml=$JOBMODULELIST '{printf "%s %s %s\n", gpw, jml, $1}' > ${GP_SSHLOGINFILE}.core

cat $NODEFILE | uniq -c | awk -v gpw=$GP_WRAPPER_FILE -v jml=$JOBMODULELIST '{printf "%s/%s %s %s\n", $1, gpw, jml, $2}' > ${GP_SSHLOGINFILE}.node

cat $NODEFILE | uniq -c | while read line; do
    NB_CORE=$(echo $line  | awk '{ print $1 }')
    HOSTNAME=$(echo $line | awk '{ print $2 }')
    n=$(( NB_CORE/NB_CORE_PER_TASK ))

    # If NB_CORE is divisible by NB_CORE_PER_TASK, n remain unchanged, e.g., n = 6/6 = 1
    # Otherwise, n = NB_CORE/NB_CORE_PER_TASK + 1, e.g., n = 1/6+1 = 0+1 = 1
    # To make sure at least one ${GP_SSHLOGINFILE}.task will be created.
    k=$(( n*NB_CORE_PER_TASK ))
    if [ $k -ne ${NB_CORE} ];then
        n=$(( n+1 ))
    fi

    SSHLOGIN="$n/$GP_WRAPPER_FILE $JOBMODULELIST $HOSTNAME"
    if [ $n -gt 0 ]; then
        echo "${SSHLOGIN}" >> ${GP_SSHLOGINFILE}.task
        GP_SSHLOGIN_OPT="${GP_SSHLOGIN_OPT} --sshlogin '${SSHLOGIN}'"
    fi
done

if [ -z "${ARG_TASK_FILE}" ]; then
    # ============
    #  Example 1:
    # ============
    # use GNU parallel to perform the tasks on the reserved nodes:
    #    ${TASK} 1
    #    ${TASK} 2
    #    [...]
    #    ${TASK} ${NB_TASKS}
    seq ${NB_TASKS} | parallel --tag -u  --sshloginfile ${GP_SSHLOGINFILE}.task ${GP_OPTS} ${TASK} {}
else
    # ============
    #  Example 2:
    # ============
    # use GNU parallel to perform the tasks on the nodes to run in
    # parallel on ${NB_CORE_PER_TASK} cores for each line of
    # ${ARG_TASK_FILE} :
    #    ${TASK} <line1>
    #    ${TASK} <line2>
    #    [...]
    #    ${TASK} <lastline>
    cat ${ARG_TASK_FILE} | parallel --tag -u  --sshloginfile ${GP_SSHLOGINFILE}.task --colsep '\n' ${GP_OPTS} ${TASK} {}
fi


# Cleanup
[ -f "${GP_SSHLOGINFILE}.core" ] && rm -f ${GP_SSHLOGINFILE}.core
[ -f "${GP_SSHLOGINFILE}.node" ] && rm -f ${GP_SSHLOGINFILE}.node
[ -f "${GP_SSHLOGINFILE}.task" ] && rm -f ${GP_SSHLOGINFILE}.task
[ -n "$SLURM_JOBID"            ] && rm -f ${NODEFILE}
