#!/bin/bash -l
##  Multi-node hybrid application **IntelMPI+OpenMP** launcher, using 28 threads per node on 10 nodes (280 cores)
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J HybridParallelJob
#SBATCH -N 10
#SBATCH --ntasks-per-node=1
#SBATCH -c 28
#SBATCH --time=0-01:00:00
#SBATCH -p batch
#SBATCH --qos=normal

module load toolchain/intel
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
srun -n $SLURM_NTASKS /path/to/your/parallel-hybrid-app
