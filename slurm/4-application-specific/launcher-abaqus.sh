#!/bin/bash -l
## Launcher starting ABAQUS in distributed mode on 2 complete `iris` nodes
## Valentin Plugaru <Valentin.Plugaru@uni.lu>
#SBATCH -J AbaqusTest
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=28
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH -p batch
#SBATCH --qos normal
#SBATCH -o %x-%j.log

### Load latest available ABAQUS
module load cae/ABAQUS

### Configure environment variables, need to unset SLURM's Global Task ID for ABAQUS's PlatformMPI to work
unset SLURM_GTIDS

### Create ABAQUS environment file for current job, you can set/add your own options (Python syntax)
env_file=abaqus_v6.env

cat << EOF > ${env_file}
#verbose = 3
#ask_delete = OFF
mp_file_system = (SHARED, LOCAL)
EOF

node_list=$(scontrol show hostname ${SLURM_NODELIST} | sort -u)

mp_host_list="["
for host in ${node_list}; do
    mp_host_list="${mp_host_list}['$host', ${SLURM_CPUS_ON_NODE}],"
done

mp_host_list=$(echo ${mp_host_list} | sed -e "s/,$/]/")

echo "mp_host_list=${mp_host_list}"  >> ${env_file}

### Set input file and job (file prefix) name here
job_name=${SLURM_JOB_NAME}
input_file=your_input_file.inp

### ABAQUS parallel execution
abaqus job=${job_name} input=${input_file} cpus=${SLURM_NTASKS} standard_parallel=all mp_mode=mpi interactive
