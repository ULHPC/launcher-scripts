#!/bin/bash -l
## Single node, multi-core MATLAB launcher, using all 28 cores of an `iris` cluster node:
##  - assumes your inputfile uses MATLAB's [parpool](https://nl.mathworks.com/help/distcomp/parpool.html) feature for local parallelism
##  - here we configure `srun` to start a single instance of MATLAB and disable process pinning (task affinity), otherwise any parallel workers started from MATLAB would be pinned to the first core (thus oversubscribing it)
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J SingleNodeParallelJob
#SBATCH -N 1
#SBATCH --ntasks-per-node=28
#SBATCH -c 1
#SBATCH --time=0-01:00:00
#SBATCH -p batch
#SBATCH --qos=qos-batch

module load base/MATLAB
srun -n 1 --cpu_bind=no matlab -nodisplay -nosplash < /path/to/your/inputfile > /path/to/your/outputfile
