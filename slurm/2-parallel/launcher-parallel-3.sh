#!/bin/bash -l
##  Multi-node parallel application **IntelMPI** launcher, using 128 distributed cores:
##  - for more information see the official SLURM [guide for IntelMPI](https://slurm.schedmd.com/mpi_guide.html#intel_mpi)
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J ParallelJob
#SBATCH -n 128
#SBATCH -c 1
#SBATCH --time=0-01:00:00
#SBATCH -p batch
#SBATCH --qos=qos-batch

module load toolchain/intel
srun -n $SLURM_NTASKS /path/to/your/intel-toolchain-compiled-application
