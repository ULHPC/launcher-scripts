# SLURM launcher examples

This directory contains batch scripts illustrating various features of the SLURM Workload Manager.

They are being kept in sync with UL HPC [SLURM's documentation](https://hpc.uni.lu/users/docs/slurm_launchers.html), and you can use them as basis for your own launchers (many more features exist in SLURM you may wish to take advantage of!).

Summary of what you will find:

* 1-basic: basic launchers for sequential, job array and best-effort (preemptible) execution
* 2-parallel: launchers for parallel code - shared-memory (pthreads/OpenMP) and distributed-memory (MPI) execution
* 3-checkpoint-restart: [DMTCP](https://github.com/dmtcp/dmtcp): Distributed MultiThreaded CheckPointing launchers
* 4-application-specific: launchers for specific applications (Apache Spark, MATLAB, ABAQUS, ANSYS)
* launcher.default.sh: example launcher with detailed comments

Many other (application-specific) launchers can be found within the the [UL HPC Tutorial](https://ulhpc-tutorials.readthedocs.io) pages. 
Ex: 

* Launchers for [OpenMP/MPI/Hybrid runs](https://github.com/ULHPC/tutorials/tree/devel/parallel/basics/runs)
* Launchers for [R runs](https://github.com/ULHPC/tutorials/blob/devel/maths/R/launcher.sh)
* Launchers for [Spark standalone cluster](https://github.com/ULHPC/tutorials/blob/devel/bigdata/runs/launcher.Spark.sh)

etc. 
