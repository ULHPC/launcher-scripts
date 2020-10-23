#!/bin/bash -l
## Submit an array job, passing to each application execution a custom value and limit # of jobs running simultaneously to 3
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J MyTestJob
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Your.Email@Address.lu
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --time=0-01:00:00
#SBATCH --array=0-9%3
#SBATCH -p batch
#SBATCH --qos=normal

echo "== Starting run at $(date)"
echo "== Job ID: ${SLURM_JOBID}, Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "== Node list: ${SLURM_NODELIST}"
echo "== Submit dir. : ${SLURM_SUBMIT_DIR}"
# Run your application passing it a custom value.
# Careful, # of values has to match # array jobs!
VALUES=(2 3 5 7 11 13 17 19 23 29)
srun /path/to/your/application ${VALUES[$SLURM_ARRAY_TASK_ID]}
