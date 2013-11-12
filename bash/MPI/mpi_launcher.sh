#! /bin/bash
################################################################################
# mpi_launcher.sh -  Example of a launcher script for MPI
#
# Usage: see `mpi_launcher.sh -h` (typically feed  a file named
#   mpi_launcher.default.conf). To run a passive job via OAR:
#
#   oarsub [options] -S ./mpi_launcher.sh

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

#OAR -n MPI_JOBNAME

#          By default, the standard output and error streams are sent
#          to files in the current working directory with names:
#              OAR.%jobid%.stdout  <-  output stream
#              OAR.%jobid%.stderr  <-  error stream
#          where %job_id% is the job number assigned when the job is submitted.
#          Use the directives below to change the files to which the
#          standard output and error streams are sent, typically to a common file

#OAR -O MPI_JOBNAME-%jobid%.log
#OAR -E MPI_JOBNAME-%jobid%.log

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
DATADIR_RELATIVEPATH="runs/${SCRIPTFILENAME}/`date +%Y-%m-%d`"
if [ -n "${SCRATCH}" ]; then
    [ "${SCRATCH}" != "/tmp" ] && DATADIR="${SCRATCH}/${DATADIR_RELATIVEPATH}" || DATADIR="${WORK}/${DATADIR_RELATIVEPATH}"
else
    DATADIR="${SCRIPTDIR}/${DATADIR_RELATIVEPATH}"
fi
# Delay between each run
DELAY=1

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
# MPI stuff
MPIRUN="mpirun"
MACHINEFILE="${OAR_NODEFILE}"
MPI_NP=1
[ -f "/proc/cpuinfo" ]   && MPI_NP=`grep processor /proc/cpuinfo | wc -l`
[ -n "${OAR_NODEFILE}" ] && MPI_NP=`cat ${OAR_NODEFILE} | wc -l`
MPI_NPERNODE=

# MPI program to execute
MPI_PROG_BASEDIR=${SCRIPTDIR}
MPI_PROG=
MPI_PROGstr=""
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
    less <<EOF
NAME
    $COMMAND -- MPI launcher script for the UL HPC platform

SYNOPSIS
    $COMMAND [-V | -h]
    $COMMAND [--debug] [-v] [-n]
    $COMMAND [--mpirun PATH] [--datadir DIR] [--name NAME] [-npernode N] [-hostfile FILE] [--delay N] \
             [--basedir DIR] [--exe prog1[,prog2,...] ]

DESCRIPTION
    $COMMAND runs MPI programs on the UL HPC platform. You can easily customize
    it by creating a local file ${CUSTOM_CONF} to overload the variables set on the 
    command line, mainly:

    * MODULE_TO_LOADstr comma-separated list of modules to load
    * MPI_PROG_BASEDIR  root directory hosting the MPI programs to execute
                        Default: ${MPI_PROG_BASEDIR}  
    * MPI_PROGstr       comma-separated list of MPI programs to execute (with relative 
                        path to MPI_PROG_BASEDIR)
    * MPI_NPERNODE      what you might precise via -npernode command
    * MPIRUN            mpirun command to use 
    * MACHINEFILE       machine file (or hostfile) to use
    etc... 

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
   --module MODULE[,MODULE2...]
        Preload the module(s) prior to the run.
    -npernode N
    -np N
    -hostfile FILE
        MPI specific commands
    --mpirun
       Absolute path to the used mpirun command
    --delay
       Delay between consecutive runs (${DELAY}s by default)
    --basedir DIR
       Set the root directory of the programs to be run 
       Default: ${MPI_PROG_BASEDIR}
    --datadir DIR
       Set the root directory of the data directory that will host the outpiyt logs of the run 
       Default: ${DATADIR}
    --datadir DIR
       Set the data  directory of the programs to be run 
       Default: ${MPI_PROG_BASEDIR}
    --exe EXE[,EXE2...]
       Define the MPI programs to execute (with a relative path to BASEDIR)
    --args "ARGS"
       Define the optionnal command-line arguments to pass to the MPI programs to run

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
        command="${MPI_CMD} ./${prog}"
        [ -n "${MPI_PROG_ARG}" ] && command="$command ${MPI_PROG_ARG}"
        echo "=> preparing the logfile ${logfile}"
        cat > ${logfile} <<EOF
# ${logfile}
# MPI Run ${prog}
#
# Initial command: ${COMMAND_LINE}
#
# Generated @ `date` by:
#   $command
# (command performed in ${MPI_PROG_BASEDIR})
### Starting timestamp: `date +%s`
EOF
        debug "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
        echo "=> running '$command'"
        if [ -z "${SIMULATION}" ]; then
            cd ${MPI_PROG_BASEDIR}
            echo "   command performed in `pwd`"
            $command |& tee -a ${logfile}
            cd -
        fi
        echo "### Ending timestamp:     `date +%s`" >> ${logfile}
        echo "=> now sleeping for ${DELAY}s"
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
        --module)      shift; MODULE_TO_LOADstr="$1";;
        --delay)       shift; DELAY=$1;;
        --name)        shift; NAME=$1;;
        --mpirun)      shift; MPIRUN=$1;;
        -np)           shift; MPI_NP=$1;;
        -npernode | -perhost | --npernode | --perhost)     
            shift; MPI_NPERNODE=$1;;
        -hostfile | --hostfile | --machinefile)
            shift; MACHINEFILE=$1;;
        --basedir)     shift; MPI_PROG_BASEDIR=$1;;
        --datadir)     shift; DATADIR=$1;;
        -e | --exe | --prog)
            shift; MPI_PROGstr="$1";;
        --args)        shift; MPI_PROG_ARG="$1";;
    esac
    shift
done

# Prepare array of programs to execute and modules to load
[ -n "${MODULE_TO_LOADstr}" ] && IFS=',' read -a MODULE_TO_LOAD <<< "${MODULE_TO_LOADstr}"
[ -n "${MPI_PROGstr}" ]       && IFS=',' read -a MPI_PROG       <<< "${MPI_PROGstr}"

# Load the modules
if [ -n "${MODULE_TO_LOAD}" ]; then
    info "purging modules"
    execute "module purge"
    for mod in ${MODULE_TO_LOAD[*]}; do
        info "loading module $mod"
        execute "module load $mod"        
    done 
    execute "module list"
fi

# Prepare the MPI command
MPI_CMD="${MPIRUN} "
[[ "${MODULE_TO_LOAD}" =~ "OpenMPI" ]] && MPI_CMD="${MPI_CMD} -x LD_LIBRARY_PATH "
[[ "${MODULE_TO_LOAD}" =~ "MVAPICH" ]] && MPI_CMD="${MPI_CMD} -launcher ssh -launcher-exec /usr/bin/oarsh "
if [ -n "${MACHINEFILE}" -a -f "${MACHINEFILE}" ]; then
    MPI_NP=`cat ${MACHINEFILE} | wc -l`
    MPI_CMD="${MPI_CMD} -hostfile ${MACHINEFILE}"
else 
    [ $MPI_NP -gt 1 ] && MPI_CMD="${MPI_CMD} -np ${MPI_NP}"
fi
if [ -n "${MPI_NPERNODE}" ]; then
    [[ "${MODULE_TO_LOAD}" =~ "ictce" ]] && MPI_CMD="${MPI_CMD} -perhost ${MPI_NPERNODE}" || MPI_CMD="${MPI_CMD} -npernode ${MPI_NPERNODE}"
fi
#[ $MPI_NP -gt 1 ] && MPI_CMD="${MPI_CMD} -np ${MPI_NP}"

verbose "MPI command: '${MPI_CMD}'"

[ -z "${MPI_PROGstr}" ] && print_error_and_exit "Could not find any MPI program to execute: you shall define MPI_PROG or use --prog option"

# Resources allocated
verbose "==== ${MPI_NP} allocated resources used for the execution of ${MPI_PROGstr} ==="
[ -n "${VERBOSE}" ] && cat $OAR_NODEFILE|uniq -c

if [ ! -d ${DATADIR} ]; then
    echo "=> creating ${DATADIR}"
    execute "mkdir -p ${DATADIR}"
fi

# Move to the directory
execute "cd ${DATADIR}"

# BEFORE HOOK
if [ -f "${CUSTOM_HOOK_BEFORE}" ]; then
    echo "=> Executing before hook ${CUSTOM_HOOK_BEFORE}"
    . ${CUSTOM_HOOK_BEFORE}
fi

# Just do what you're supposed to do ;)
do_it

# AFTER HOOK
if [ -f "${CUSTOM_HOOK_AFTER}" ]; then
    echo "=> Executing after hook ${CUSTOM_HOOK_AFTER}"
    . ${CUSTOM_HOOK_AFTER}
fi
