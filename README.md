-*- mode: markdown; mode: auto-fill; fill-column: 80 -*-
`README` -- [HPC @ UL](http://hpc.uni.lu)

        Time-stamp: <Mar 2013-03-12 02:20 svarrette>

-------------------

# UL HPC Launcher scripts

## Synopsis

This repository holds a set of launcher scripts to be used on the
[UL HPC](https://hpc.uni.lu) platform. 
They are provided for users of the infrastructure to make their life easier (and
hopefully more efficient) on the following typical workflows: 

* MPI run on n processes (ex: HPL) with abstraction of the MPI stack, MPI script, option to compile the code etc.
* MPI run on n process per node (ex: OSU benchs)
* Embarrassingly parallel run for multi-parametric jobs over a Java/C/C++/Ruby/Perl/Python/R script

We propose here two types of contributions:

* a set of `bash` scripts examples that users can use as a startup example to
adapt for their own workflow
* **NOT YET IMPLEMENTED** a more generic ruby script interfaced by a YAML
    configuration file which hold the specificity of each users.

## MPI launcher 

You'll find an example of launcher script for MPI jobs in
`bash/MPI/mpi_launcher.sh`. 
To use it to fit your needs, you'll probably want to edit it and adapt (at least)
the variables `MPI_PROG_BASEDIR`and `MPI_PROG` variables. 

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
