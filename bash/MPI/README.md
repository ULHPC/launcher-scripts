-*- mode: markdown; mode: auto-fill; fill-column: 80 -*-
`README.md`

Copyright (c) 2013 [Sebastien Varrette](mailto:<Sebastien.Varrette@uni.lu>) [www](http://varrette.gforge.uni.lu)

        Time-stamp: <Dim 2013-11-10 18:50 svarrette>

-------------------

# MPI launcher 

So you want to run an MPI program on the [UL HPC platform](http://hpc.uni.lu).
You'll find here an example of a launcher script that you can tweak to suit your
needs.
There are several typical MPI workflow you might want to try: 

* running a simple Helloworld MPI application
* running some of the
  [OSU benchmarks](http://mvapich.cse.ohio-state.edu/benchmarks/) to measures
  the MPI performances (bandwidth and latency) of Point-to-Point communications.
* running the [HPL](http://www.netlib.org/benchmark/hpl/) suit (High-Performance Linpack Benchmark)

Feel free to test and adapt this generic launcher. 

You might also be interested to follow the [tutorial on running HPL](https://github.com/ULHPC/tutorials/tree/devel/advanced/HPL).


## (Generic) Pre-requisite

Connect to your favorite cluster frontend (here: `chaos`)

      $> ssh chaos-cluster

Reserve interactively two full nodes, ideally belonging to the same enclosure: 

     (access-chaos)$> oarsub -I -l enclosure=1/nodes=2,walltime=8
     ADMISSION RULE] Modify resource description with type constraints
     OAR_JOB_ID=435525
     Interactive mode : waiting...
     Starting...
     
     Connect to OAR job 435525 via the node s-cluster1-6
     
     (s-cluster1-6)$> cat $OAR_NODEFILE | uniq
     s-cluster1-6
     s-cluster1-7
     
     (s-cluster1-6)$> cat $OAR_NODEFILE | wc -l
     32

So in the above example, I reserved a total of 32 cores on 2 distinct nodes (`s-cluster1-6` and `s-cluster1-6`)

Now you can clone the repository 

     $> mkdir -p ~/git/ULHPC
     $> cd ~/git/ULHPC
     $> git clone git://github.com/ULHPC/launcher-scripts.git

Prepare your working directory

     $> mkdir -p $WORK/tutorials/MPI
     $> cd $WORK/tutorials
     $> ln -s ~/git/ULHPC/launcher-scripts/examples/include .
     
     
## MPI helloworld

As you cloned the repository, you'll find everything ready to test the MPI
helloword example in `~/git/ULHPC/launcher-scripts/examples/MPI/helloworld`.


     $> cd $WORK/tutorials/MPI
     $> rsync -avzu ~/git/ULHPC/launcher-scripts/examples/MPI/helloworld .     
     $> cd helloword
     
Now you can check everything work (in interactive mode), for instance with the
[OpenMPI](http://www.open-mpi.org/) suite:     
     
     $> module load OpenMPI
     $> make
     $> mpirun -hostfile $OAR_NODEFILE ./mpi_hello_and_sleep
     [node 0]: Total Number of processes : 32
     [node 0]: Input n = 2
     [node 1]: Helloword! I'll now sleep for 2s
     [node 2]: Helloword! I'll now sleep for 2s
     [...]
     [node 0]: Elapsed time: 2.000160 s

You might want to test the other MPI suites supported on the cluster. 
For [MVAPICH2](http://mvapich.cse.ohio-state.edu/overview/mvapich2/):

     $> make clean
     $> module purge
     $> module load MVAPICH2
     $> make 
     $> mpirun -hostfile $OAR_NODEFILE ./mpi_hello_and_sleep
     [Node 0] Total Number of processes : 32
     [Node 0] Input n = 1
     [Node 0] [Node 1] Helloword! I'll now sleep for 4s
     [Node 2] Helloword! I'll now sleep for 4s
     [Node 3] Helloword! I'll now sleep for 4s
     [...]
     Helloword! I'll now sleep for 1s
     [node 0]: Elapsed time: 1.000727 s

For the
[Intel Cluster Toolkit Compiler Edition (`ictce` for short)](http://software.intel.com/en-us/articles/intel-cluster-studio-xe-2012-tutorial):

     $> make clean
     $> module purge
     $> module load ictce
     $> make 
     $> mpirun -hostfile $OAR_NODEFILE ./mpi_hello_and_sleep
     [node 0]: Total Number of processes : 32
     [node 0]: Input n = 4
     [node 0]: [node 1]: Helloword! I'll now sleep for 4s
     [node 2]: Helloword! I'll now sleep for 4s
     [node 3]: Helloword! I'll now sleep for 4s
     [...]
     [node 30]: Helloword! I'll now sleep for 4s
     [node 31]: Helloword! I'll now sleep for 4s
     Helloword! I'll now sleep for 4s
     [node 0]: Elapsed time: 4.000185 s

Now that the interactive run succeed, it's time to embedded the command into a
launcher. 
You can obviously add the correct `mpirun` command into a `bash` script (or
`python`/`ruby`/whatever). 
You can also use the proposed generic MPI launcher :

    $> ln -s /home/users/svarrette/git/ULHPC/launcher-scripts/bash/MPI/mpi_launcher.sh .

Simply create a configuration file `mpi_launcher.default.conf` containing (at least) the
definition of the 

    $> vim mpi_launcher.default.conf
    [...]
    $> cat mpi_launcher.default.conf
    MPI_PROG=mpi_hello_and_sleep
    MPI_PROG_ARG=3
    $> ./mpi_launcher.sh
    /mpi_launcher.sh
    overwriting default configuration
    => performing MPI run mpi_hello_and_sleep @ Tue Apr  2 16:45:47 CEST 2013
    => preparing the logfile /tmp//run/mpi_launcher.sh/2013-04-02/435561_results_mpi_hello_and_sleep_16h45m47.log
    [node 0]: Total Number of processes : 32
    [node 1]: Helloword! I'll now sleep for 3s
    [node 2]: Helloword! I'll now sleep for 3s
    [...]
    [node 25]: Helloword! I'll now sleep for 3s
    [node 0]: Elapsed time: 3.000222 s
    
You can also exit your reservation to re-run it in passive mode: 

    $> exit 
    $> oarsub -l enclosure=1/nodes=2,walltime=8 $WORK/tutorials/MPI/helloworld/mpi_launcher.sh
 
