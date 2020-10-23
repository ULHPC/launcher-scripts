#!/bin/bash -l
## Multi-node parallel application **OpenMPI** launcher, using 128 distributed cores:
##  - for more information see the official SLURM [guide for OpenMPI](https://slurm.schedmd.com/mpi_guide.html#open_mpi)
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J ParallelJob
#SBATCH -n 128
#SBATCH -c 1
#SBATCH --time=0-01:00:00
#SBATCH -p batch
#SBATCH --qos=normal

module load toolchain/foss
srun -n $SLURM_NTASKS /path/to/your/foss-toolchain-compiled-application
