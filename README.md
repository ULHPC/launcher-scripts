-*- mode: markdown; mode: auto-fill; fill-column: 80 -*-
`README` -- [HPC @ UL](http://hpc.uni.lu)

        Time-stamp: <Mer 2013-04-03 17:35 svarrette>

-------------------

# UL HPC Launcher scripts

## Synopsis

This repository holds a set of launcher scripts to be used on the
[UL HPC](https://hpc.uni.lu) platform. 
They are provided for users of the infrastructure to make their life easier (and
hopefully more efficient) on the following typical workflows: 

* Embarrassingly parallel run for repetitive and/or multi-parametric jobs over a
  Java/C/C++/Ruby/Perl/Python/R script, corresponding (normally) to the
  following cases: 
  
 * serial (or sequential) tasks having all similar duration, run on one node
 * serial (or sequential) tasks having varying durations, run on one node
 * serial (or sequential) tasks having varying durations, run on multiple nodes

* MPI run on n processes (ex: HPL) with abstraction of the MPI stack, MPI script, option to compile the code etc.
* MPI run on n process per node (ex: OSU benchs)

We propose here two types of contributions:

* a set of `bash` scripts examples that users can use as a startup example to
adapt for their own workflow
* **NOT YET IMPLEMENTED** a more generic ruby script interfaced by a YAML
    configuration file which hold the specificity of each users.

## General considerations

The [UL HPC](https://hpc.uni.lu) platform offers parallel computing resource, so
it's important you make an *efficient* use of the computing nodes, even when
processing serial jobs. 
In particular, you should avoid to submit purely serial jobs to the OAR queue as
it would waste the computational power (11 out of 12 cores is you reserve one
node on `gaia` for instance).

## Running a bunch of serial tasks on a single node

A *bad* behaviour in this context is illustrated in
`bash/serial/NAIVE_AKA_BAD_launcher_serial.sh` where you'll recognize a pattern
you perhaps use in your own script: 

     for i in `seq 1 ${NB_TASKS}`; do  
        ${TASK} $i
     done 

If you're more familiar with UNIX, you can perhaps argue we can fork separate
processes using the bash `&` (ampersand) builtin control operator and the `wait`
command. 
This is illustrated in `bash/serial/launcher_serial_ampersand.sh` and
corresponds to the following pattern:

     for i in `seq 1 ${NB_TASKS}`; do  
        ${TASK} $i &
     done 
     wait

This approach is straightforward and is sufficient assuming (1) you don't have a
huge number of tasks to fork and (2) each tasks has the a similar duration. 
For all the other (serial) cases, an approach based on
[GNU parallel](http://www.gnu.org/software/parallel/) if more effective as it
permits to easily and efficiently  schedule batch of n tasks in parallel 
(`-j n`), where n typically stands for the number of cores of the nodes. 
This is illustrated in `bash/serial/launcher_serial.sh` and corresponds to the
following pattern: 

    seq ${NB_TASKS} | parallel -u -j 12 ${TASK} {}


Not convinced you have interest to these approaches? Take a look at the
following completion times performed on the `chaos` cluster for the task
`mytask.sh` proposed in `bash/serial/mytask.sh`: 

      +---------+---------------+--------+--------------+----------------------+-----------+
      | NB_TASK |    HOSTNAME   | #CORES |    TASK      |    APPROACH          |   TIME    |
      +---------+---------------+--------+--------------+----------------------+-----------+
      |   24    | h-cluster1-32 |   12   | sleep {1-24} | Pure serial          | 5m0.483s  |
      |   24    | h-cluster1-32 |   12   | sleep {1-24} | Ampersand + wait     | 0m24.141s |
      |   24    | h-cluster1-32 |   12   | sleep {1-24} | GNU Parallel (-j 12) | 0m36.404s |
      |   24    | h-cluster1-32 |   12   | sleep {1-24} | GNU Parallel (-j 24) | 0m24.257s |
      +---------+---------------+--------+--------------+----------------------+-----------+

The same benchmark performed for the sample argument file (see
`bash/serial/mytask.args.example`):

      +---------+---------------+--------+---------+----------------------+-----------+
      | NB_TASK |    HOSTNAME   | #CORES | TASK    |    APPROACH          |   TIME    |
      +---------+---------------+--------+---------+----------------------+-----------+
      |   30    | h-cluster1-32 |   12   | sleep 2 | Pure serial          | 1m0.374s  |
      |   30    | h-cluster1-32 |   12   | sleep 2 | Ampersand + wait     | 0m2.217s  |
      |   30    | h-cluster1-32 |   12   | sleep 2 | GNU Parallel (-j 12) | 0m6.375s  |
      |   30    | h-cluster1-32 |   12   | sleep 2 | GNU Parallel (-j 24) | 0m4.255s  |
      +---------+---------------+--------+---------+----------------------+-----------+


## GNU parallel

Resources: 

* [Official documentation](http://www.gnu.org/software/parallel/man.html),
  crappy yet useful and full of concrete examples. 
* [Wiki SciNet](http://wiki.scinethpc.ca/wiki/index.php/User_Serial)
* [Slides on GNU Parallel for Large Batches of Small Jobs](http://wiki.scinethpc.ca/wiki/images/archive/7/7b/20121114192300!Tech-talk-gnu-parallel.pdf)
* [GNU Parallel and PBS](http://web0.tc.cornell.edu/wiki/index.php?title=Gnu_Parallel)
* [GNU parallel introduction](http://www.admin-magazine.com/HPC/Articles/GNU-Parallel-Multicore-at-the-Command-Line-with-GNU-Parallel)
* [Using GNU Parallel to Package Multiple Jobs in a Single PBS Job](http://www.nas.nasa.gov/hecc/support/kb/Using-GNU-Parallel-to-Package-Multiple-Jobs-in-a-Single-PBS-Job_303.html)

## Running a bunch of serial tasks on more than a single node

If you have hundreds of serial tasks that you want to run concurrently and you
reserved more than one nodes, then the approach above, while useful, would
require tens of scripts to be submitted  in separate OAR jobs (each of them
reserving 1 full nodes). 

It is also possible to use [GNU parallel](http://www.gnu.org/software/parallel/)
in this case, using the `--sshlogin` options (altered to use the `oarsh`
connector). 
This is illustrated in the generic launcher proposed in `



## Running MPI programs

You'll find an example of launcher script for MPI jobs in
`bash/MPI/mpi_launcher.sh`. 
Examples of usage are proposed in `examples/MPI/` 


# Contributing to this repository 

## Pre-requisites

### Git

You should become familiar (if not yet) with Git. Consider these resources:

* [Git book](http://book.git-scm.com/index.html)
* [Github:help](http://help.github.com/mac-set-up-git/)
* [Git reference](http://gitref.org/)

### git-flow

The Git branching model for this repository follows the guidelines of [gitflow](http://nvie.com/posts/a-successful-git-branching-model/).
In particular, the central repo (on `github.com`) holds two main branches with an infinite lifetime:

* `production`: the *production-ready* benchmark data 
* `devel`: the main branch where the latest developments interviene. This is
  the *default* branch you get when you clone the repo.

### Local repository setup

This repository is hosted on out [GitHub](https://github.com/ULHPC/launcher-scripts).
Once cloned, initiate the potential git submodules etc. by running: 

    $> cd launcher-scripts
    $> make setup


