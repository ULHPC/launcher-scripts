#!/bin/bash -l
## Submit an array job that will create 10 jobs, for parametric executions
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J MyTestJob
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Your.Email@Address.lu
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --time=0-01:00:00
#SBATCH --array=0-9
#SBATCH -p batch
#SBATCH --qos=qos-batch

echo "== Starting run at $(date)"
echo "== Job ID: ${SLURM_JOBID}, Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "== Node list: ${SLURM_NODELIST}"
echo "== Submit dir. : ${SLURM_SUBMIT_DIR}"
# Run your application as a job step,  passing its unique array id
# (based on which varying processing can be done)
srun /path/to/your/application $SLURM_ARRAY_TASK_ID
