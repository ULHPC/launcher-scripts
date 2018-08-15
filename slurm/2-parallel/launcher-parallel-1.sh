#!/bin/bash -l
##  Single node, threaded (pthreads/OpenMP) application launcher, using all 28 cores of an `iris` cluster node:
##  - `--ntasks-per-node=1` and `-c 28` are taken into account only if using `srun` to launch your application
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J ThreadedJob
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH -c 28
#SBATCH --time=0-01:00:00
#SBATCH -p batch
#SBATCH --qos=qos-batch

export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
srun /path/to/your/threaded.app
