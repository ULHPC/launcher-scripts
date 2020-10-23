#!/bin/bash -l
## Multi-node parallel application **IntelMPI** launcher, using 56 distributed cores and requesting 56 Allinea Performance Reports licenses
## - you can check using `scontrol show lic` how many total licenses are available for `forge` (Allinea Forge: DDT/MAP) and `perfreport` (Allinea Performance Reports)
## - the below launcher runs your application under the performance report tool with its default options (will generate text/html reports)
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J ProfilingJob
#SBATCH -n 56
#SBATCH -c 1
#SBATCH --time=0-01:00:00
#SBATCH -p batch
#SBATCH --qos=normal
#SBATCH -L perfreport:56

module load toolchain/intel
module load tools/AllineaReports
perf-report srun -n $SLURM_NTASKS /path/to/your/intel-toolchain-compiled-application
