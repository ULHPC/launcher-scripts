#! /bin/bash
################################################################################
# launcher_serial_similar_duration.sh -  Example of a generic launcher script 
#    for running serial tasks, each of them with similar duration
#
#   oarsub [options] -S ./launcher_serial_similar_duration.sh
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

#OAR -n Serial

#          By default, the standard output and error streams are sent
#          to files in the current working directory with names:
#              OAR.%jobid%.stdout  <-  output stream
#              OAR.%jobid%.stderr  <-  error stream
#          where %job_id% is the job number assigned when the job is submitted.
#          Use the directives below to change the files to which the
#          standard output and error streams are sent, typically to a common file

#OAR -O Serial-%jobid%.log
#OAR -E Serial-%jobid%.log

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
NB_CORES_HEADNODE=`cat ${OAR_NODEFILE} | uniq -c | head -n1 | awk '{print $1}'`
# Default value
: ${NB_CORES_HEADNODE:=1}

# The [serial] task to be executed
TASK="$HOME/mytask.sh"

################# Let's go ###############
# Load the required modules
for m in ${MODULE_TO_LOAD[*]}; do 
    echo "=> loading the module '$m'"
    module load $m
done

# DIRECTORY WHERE TO RUN 
cd $WORK

# Run the serial tasks in parallel based on the characterictics of the head node
# (normally the only one reserved): ampersand off ${NB_CORES_HEADNODE} jobs and
# wait  
for i in `seq ${NB_CORES_HEADNODE}`; do 
    ${TASK} &
done 
wait 

