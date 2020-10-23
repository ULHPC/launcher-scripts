#!/bin/bash -l
# Time-stamp: <Mon 2018-06-18 09:48 svarrette>
##################################################################

##########################
#                        #
#  The SLURM directives  #
#                        #
##########################
#
#          Set number of resources
#
#SBATCH -N 1
#SBATCH --ntasks-per-node=28
### -c, --cpus-per-task=<ncpus>
###     (multithreading) Request that ncpus be allocated per process
#SBATCH -c 1
#
#SBATCH --time=0-01:00:00   # 1 hour
#
#          Set the name of the job
###SBATCH -J NAME

#          Passive jobs specifications
#SBATCH --partition=batch
#SBATCH --qos normal

### General SLURM Parameters
echo "SLURM_JOBID  = ${SLURM_JOBID}"
echo "SLURM_JOB_NODELIST = ${SLURM_JOB_NODELIST}"
echo "SLURM_NNODES = ${SLURM_NNODES}"
echo "SLURM_NTASKS = ${SLURM_NTASKS}"
echo "SLURMTMPDIR  = ${SLURMTMPDIR}"
echo "Submission directory = ${SLURM_SUBMIT_DIR}"

### Guess the run directory
# - either the script directory upon interactive jobs
# - OR the submission directory upon passive/batch jobs
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -n "${SLURM_SUBMIT_DIR}" ]; then
    [[ "${SCRIPTDIR}" == *"slurmd"* ]] && RUNDIR=${SLURM_SUBMIT_DIR} || RUNDIR=${SCRIPTDIR}
else
    RUNDIR=${SCRIPTDIR}
fi

### Prepare log file



### Toolbox function
print_error_and_exit() { echo "***ERROR*** $*"; exit 1; }

############################################
################# Let's go #################
############################################

# Use the RESIF build modules
if [ -f  /etc/profile ]; then
   .  /etc/profile
fi

# Load the {intel | foss} toolchain and whatever module(s) you need
module purge
module load toolchain/intel

# Directory holding your built applications
APPDIR="$HOME"
# The task to be executed i.E. your favorite Java/C/C++/Ruby/Perl/Python/R/whatever program
# to be invoked in parallel
TASK="${APPDIR}/app.exe"

# The command to run
CMD="${TASK}"
### General MPI Case:
# CMD="srun -n $SLURM_NTASKS ${TASK}"
### OpenMPI case if you wish to specialize the MCA parameters
#CMD="mpirun -np $SLURM_NTASKS --mca btl openib,self,sm ${TASK}"

### Prepare logfile
LOGFILE="${RUNDIR}/$(date +%Y-%m-%d)_$(basename ${TASK})_${SLURM_JOBID}.log"

cat > ${LOGFILE} <<EOF
# Task ${TASK} run # MPI @ $(date) by:
#      ${CMD}
#
# SLURM_JOBID        $SLURM_JOBID
# SLURM_JOB_NODELIST $SLURM_JOB_NODELIST
# SLURM_NNODES       $SLURM_NNODES
# SLURM_NTASKS       $SLURM_NTASKS
# SLURM_SUBMIT_DIR   $SLURM_SUBMIT_DIR
### Starting timestamp: $(date +%s)
EOF

# Run the command
${CMD} |& tee -a ${LOGFILE}

cat >> ${LOGFILE} <<EOF
### Ending timestamp:     $(date +%s)
EOF
