#!/bin/bash -l
## Request one core for 5 minutes in the batch queue and print a message
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --time=0-00:05:00
#SBATCH -p batch
#SBATCH --qos=normal

echo "Hello from the batch queue on node ${SLURM_NODELIST}"
# Your more useful application can be started below!
