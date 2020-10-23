#!/bin/bash -l
## Adapted from [the official DMTCP launchers](https://github.com/dmtcp/dmtcp/blob/master/plugin/batch-queue/job_examples/slurm_launch.job).
## Launcher that restarts an application from a DMTCP checkpoint:
##  - to be started in the same directory as the initial launch, and relies on the `dmtcp_restart_script.sh` generated at that step
## See also `launcher-checkpoint.sh`
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J MyCheckpointedJob
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Your.Email@Address.lu
#SBATCH -N 4
#SBATCH --ntasks-per-node=28
#SBATCH --mem=64GB
#SBATCH --time=0-06:00:00
#SBATCH -p batch
#SBATCH --qos=normal

#----------------------------- Set up DMTCP environment for a job ------------#

###############################################################################
# Start DMTCP coordinator on the launching node. Free TCP port is automatically
# allocated.  This function creates a dmtcp_command.$JOBID script, which serves
# as a wrapper around dmtcp_command.  The script tunes dmtcp_command for the
# exact dmtcp_coordinator (its hostname and port).  Instead of typing
# "dmtcp_command -h <coordinator hostname> -p <coordinator port> <command>",
# you just type "dmtcp_command.$JOBID <command>" and talk to the coordinator
# for JOBID job.
###############################################################################

start_coordinator()
{
    ############################################################
    # For debugging when launching a custom coordinator, uncomment
    # the following lines and provide the proper host and port for
    # the coordinator.
    ############################################################
    # export DMTCP_COORD_HOST=$h
    # export DMTCP_COORD_PORT=$p
    # return

    fname=dmtcp_command.$SLURM_JOBID
    h=`hostname`

    check_coordinator=`which dmtcp_coordinator`
    if [ -z "$check_coordinator" ]; then
        echo "No dmtcp_coordinator found. Check your DMTCP installation and PATH settings."
        exit 0
    fi

    dmtcp_coordinator --daemon --exit-on-last -p 0 --port-file $fname $@ 1>/dev/null 2>&1

    while true; do
        if [ -f "$fname" ]; then
            p=`cat $fname`
            if [ -n "$p" ]; then
                # try to communicate ? dmtcp_command -p $p l
                break
            fi
        fi
    done

    # Create a dmtcp_command wrapper for easy communication with the coordinator.
    p=`cat $fname`
    chmod +x $fname
    echo "#!/bin/bash" > $fname
    echo >> $fname
    echo "export PATH=$PATH" >> $fname
    echo "export DMTCP_COORD_HOST=$h" >> $fname
    echo "export DMTCP_COORD_PORT=$p" >> $fname
    echo "dmtcp_command \$@" >> $fname

    # Set up local environment for DMTCP
    export DMTCP_COORD_HOST=$h
    export DMTCP_COORD_PORT=$p

}

#----------------------- Some rutine steps and information output -------------------------#

###################################################################################
# Print out the SLURM job information.  Remove this if you don't need it.
###################################################################################

echo "SLURM_JOBID="$SLURM_JOBID
echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
echo "SLURM_NNODES"=$SLURM_NNODES
echo "SLURMTMPDIR="$SLURMTMPDIR
echo "working directory = "$SLURM_SUBMIT_DIR

# changedir to workdir
cd $SLURM_SUBMIT_DIR

#----------------------------------- Set up job environment ------------------#

###############################################################################
# Load all nessesary modules or export PATH/LD_LIBRARY_PATH/etc here.
###############################################################################

module load tools/DMTCP

## If you use the FOSS toolchain (GCC, OpenMPI, etc.) uncomment the line below
# module load toolchain/foss

## If you use the Intel toolchain (compilers, MKL, IntelMPI) uncomment below
# module load toolchain/intel

## Add other modules below

#------------------------------------- Launch application ---------------------#

################################################################################
# 1. Start DMTCP coordinator - for periodic checkpointing uncomment `-i` below
################################################################################

start_coordinator # -i 3600 # ... <other dmtcp coordinator options here>

################################################################################
# 2. Restart checkpointed application from DMTCP created restart script
################################################################################

/bin/bash ./dmtcp_restart_script.sh -h $DMTCP_COORD_HOST -p $DMTCP_COORD_PORT
