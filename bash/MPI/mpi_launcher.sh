#! /bin/bash
################################################################################
# mpi_launcher.sh -  Example of a launcher script for MPI
################################################################################

##########################
#                        #
#   The OAR  directives  #
#                        #
##########################
#
#          Set number of resources
#

#OAR -l nodes=2/core=1

#          Set the name of the job (up to 15 characters,
#          no blank spaces, start with alphanumeric character)

#OAR -n JOBNAME

#          By default, the standard output and error streams are sent
#          to files in the current working directory with names:
#              OAR.%jobid%.stdout  <-  output stream
#              OAR.%jobid%.stderr  <-  error stream
#          where %job_id% is the job number assigned when the job is submitted.
#          Use the directives below to change the files to which the
#          standard output and error streams are sent, typically to a common file

#OAR -O JOBNAME-%jobid%.log
#OAR -E JOBNAME-%jobid%.log

#####################################
#                                   #
#   The UL HPC specific directives  #
#                                   #
#####################################

if [ -f  /etc/profile ]; then
    .  /etc/profile
fi

#####################################
#                                   #
#   The launcher global variables   #
#                                   #
#####################################
VERSION=0.1
COMMAND=`basename $0`
COMMAND_LINE="${COMMAND} $@"
VERBOSE=""
DEBUG=""
SIMULATION=""

#####################################
#                                   #
#   The launcher local variables    #
#                                   #
#####################################
STARTDIR="$(pwd)"
SCRIPTFILENAME=$(basename $0)
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Where the output files are produced
DATADIR_RELATIVEPATH="run/${SCRIPTFILENAME}/`date +%Y-%m-%d`"
if [ -n "${SCRATCH}" ]; then 
    [ "${SCRATCH}" != "/tmp" ] && DATADIR="${SCRATCH}/${DATADIR_RELATIVEPATH}" || DATADIR="${WORK}/${DATADIR_RELATIVEPATH}"
else 
    DATADIR="${SCRIPTDIR}/run/`date +%Y-%m-%d`"
fi 
# Delay between each run
DELAY=10

### User customization handling
# Custom file where you can overload the default variables set for MPI
CUSTOM_CONF="${SCRIPTDIR}/`basename ${SCRIPTFILENAME} .sh`.default.conf"
# Hook file loaded BEFORE the mpirun command
CUSTOM_HOOK_BEFORE="${SCRIPTDIR}/`basename ${SCRIPTFILENAME} .sh`.hook.before"
# Hook file loaded AFTER the mpirun command
CUSTOM_HOOK_AFTER="${SCRIPTDIR}/`basename ${SCRIPTFILENAME} .sh`.hook.after"

##################################
#                                #
#   The launcher MPI settings    #
#                                #
##################################
# MPI module suite (available: OpenMPI, MVAPICH2, ictce)
MPI_MODULE_SUITE=OpenMPI
[ -f "${OAR_NODEFILE}" ] && MPI_NP=`wc -l ${OAR_NODEFILE} | cut -d " " -f 1` || MPI_NP=1
[ -f "${OAR_NODEFILE}" ] && MPI_HOSTFILE="${OAR_NODEFILE}"                   || MPI_HOSTFILE=
MPI_NPERNODE=
MPI_PROG_BASEDIR=${SCRIPTDIR}
MPI_PROG=
MPI_PROG_ARG=

########################################
#                                      #
#   Script procedures (do not modify   #
#   unless you know what you're doing) #
#                                      #
########################################
print_version() {
    cat <<EOF
This is $COMMAND version "$VERSION".
Copyright (c) 2013 UL HPC sysadmin team.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
EOF
}
print_help() {
    cat <<EOF
NAME
    $COMMAND -- Example of a MPI launcher script for the UL HPC platform

SYNOPSIS
    $COMMAND [-V | -h]
    $COMMAND [--debug] [-v] [-n]
    $COMMAND [--mpirun PATH] [--name NAME] [-np N] [-npernode N] [-hostfile FILE] [--delay N] 

DESCRIPTION
    $COMMAND runs MPI programs on the UL HPC platform. You can easily customize
    it by creating a local file ${CUSTOM_CONF} containg the following variables: 

    * MPI_MODULE_SUITE: the MPI suite to use (Default: 'OpenMPI')
    * MPI_PROG : the MPI program to execute 

OPTIONS
    --debug
        Debug mode. Causes $COMMAND to print debugging messages.
    -h --help
        Display a help screen and quit.
    -n --dry-run
        Simulation mode.
    -v --verbose
        Verbose mode.
    -V --version
        Display the version number then quit.
    --name NAME
        Set the job name
    -npernode N
    -np N
    -hostfile FILE
        MPI specific commands
    --mpirun
       Absolute path to the used mpirun command
    --delay
       Delay between consecutive runs (${DELAY}s by default)

AUTHOR
    UL HPC sysadmin team <hpc-sysadmins@uni.lu>
    Web page: http://hpc.uni.lu

REPORTING BUGS
    Please report bugs on [Github](https://github.com/ULHPC/launcher-scripts/issues)

COPYRIGHT
    This is free software; see the source for copying conditions.  There is
    NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR
    PURPOSE.

SEE ALSO
    Other launcher scripts are available on [GitHub](https://github.com/ULHPC/launcher-scripts)
EOF
}
info() {
    [ -z "$1" ] && print_error_and_exit "[$FUNCNAME] missing text argument"
    echo "$1"
}
debug()   { [ -n "$DEBUG"   ] && info "[DEBUG] $*"; }
verbose() { [ -n "$VERBOSE" ] && info "$*"; }
error()   { info "*** ERROR *** $*"; }
warning() { info "/!\ WARNING: $*" ; }
print_error_and_exit() { error $*; exit 1; }

#####
# execute a local command
# usage: execute command
###
execute() {
    [ $# -eq 0 ] && print_error_and_exit "[$FUNCNAME] missing command argument"
    debug "[$FUNCNAME] $*"
    [ -n "${SIMULATION}" ] && echo "(simulation) $*" || eval $*
    local exit_status=$?
    debug "[$FUNCNAME] exit status: $exit_status"
    return $exit_status
}

###
# Perform the run and set the logfile
##
do_it() {
    for prog in ${MPI_PROG[*]}; do
        fullprogname=${MPI_PROG_BASEDIR}/${prog}
        if [ ! -x "${fullprogname}" ]; then
            error "Unable to find the MPI program ${fullprogname}"
            break
        fi
        echo "=> performing MPI run ${prog} @ `date`"
        date_prefix=`date +%Hh%Mm%S`
        if [ -z "${NAME}" ]; then
            logfile="${DATADIR}/${OAR_JOBID}_results_${prog}_${date_prefix}.log"
        else
            logfile="${DATADIR}/${OAR_JOBID}_${NAME}_${prog}_${date_prefix}.log"
        fi
        MPI_CMD="${MPIRUN}"
        [ -n "${MPI_HOSTFILE}" ] && MPI_CMD="${MPI_CMD} -hostfile ${MPI_HOSTFILE}"
        [ -n "${MPI_NPERNODE}" ] && MPI_CMD="${MPI_CMD} -npernode ${MPI_NPERNODE}"
        MPI_CMD="${MPI_CMD} -np ${MPI_NP} ${MPI_PROG_BASEDIR}/${prog}"
        [ -n "${MPI_PROG_ARG}" ] && MPI_CMD="${MPI_CMD} ${MPI_PROG_ARG}"
        echo "=> preparing the logfile ${logfile}"
        cat > ${logfile} <<EOF
# ${logfile}
# MPI Run ${prog}
#
# Initial command: ${COMMAND_LINE}
#
# Generated @ `date` by:
#   ${MPI_CMD}
### Starting timestamp: `date +%s`
EOF
        verbose "executing ${MPI_CMD}"
        execute "${MPI_CMD} | tee -a ${logfile}"
        echo "### Ending timestamp:     `date +%s`" >> ${logfile}
        verbose "sleeping ${DELAY}s"
        sleep $DELAY
    done
}

##########################################
#                                        #
#   YOUR OWN DEFAULT SETTINGS            #
#   (TO BE ADAPTED)                      #
#   Eventually simply overload these     #
#   setting in mpi_launcher.default.conf #
##########################################
if [ -f "${CUSTOM_CONF}" ]; then 
    info "overwriting default configuration"
    . ${CUSTOM_CONF}
fi

# MPI_PROG_BASEDIR="$HOME/stow/osu-micro-benchmarks-3.8/libexec/osu-micro-benchmarks/mpi/one-sided"
# # List (bash array) of MPI programs (relative to ${MPI_PROG_BASEDIR}) to be run
# MPI_PROG=(osu_get_latency osu_get_bw)

#TODO: args
#MPI_ARGS=(arg1 arg2)




################################################################################
################################################################################
################################################################################
# The script core starts here

# Check for options
while [ $# -ge 1 ]; do
    case $1 in
        -h | --help)    print_help;        exit 0;;
        -V | --version) print_version;     exit 0;;
        --debug)         DEBUG="--debug";
            VERBOSE="--verbose";;
        -v | --verbose)  VERBOSE="--verbose";;
        -n | --dry-run)  SIMULATION="--dry-run";;
        --name)        shift; NAME=$1;;
        -npernode)     shift; MPI_NPERNODE=$1;;
        -np)           shift; MPI_NP=$1;;
        -hostfile)     shift; MPI_HOSTFILE=$1;;
        --mpirun)      shift; MPIRUN=$1;;
        --delay)       shift; DELAY=$1;;
    esac
    shift
done

[ -z "${MPI_MODULE_SUITE}" ] && print_error_and_exit "An MPI module suite have to be selected"
module load ${MPI_MODULE_SUITE}


# Local MPI commands
MPIRUN=`which mpirun`
[ -z "${MPIRUN}" ] && print_error_and_exit "unable to find the mpirun command"

[ -z "${MPI_PROG}" ] && print_error_and_exit "Could not find any MPI program to execute: you shall define MPI_PROG"

# Resources allocated
verbose "==== `wc -l $OAR_NODEFILE | cut -d " " -f 1` allocated resources used for the execution of ${MPI_PROG} ==="
[ -n "${VERBOSE}" ] && cat $OAR_NODEFILE

if [ ! -d ${DATADIR} ]; then
    echo "=> creating ${DATADIR}"
    execute "mkdir -p ${DATADIR}"
fi

# Move to the directory
execute "cd ${DATADIR}"

if [ -f "${CUSTOM_HOOK_BEFORE}" ]; then
    echo "=> Executing before hook ${CUSTOM_HOOK_BEFORE}"
    . ${CUSTOM_HOOK_BEFORE}
fi

# Just do what you're supposed to do 
do_it

if [ -f "${CUSTOM_HOOK_AFTER}" ]; then
    echo "=> Executing after hook ${CUSTOM_HOOK_AFTER}"
    . ${CUSTOM_HOOK_AFTER}
fi
