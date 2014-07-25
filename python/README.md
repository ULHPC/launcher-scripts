# Python version of launcher scripts

I wrote these scripts for the following reasons: To understand the
process of job submissiona and to provide launch scripts in a language
that I really understand (compared to bash).

So far the script(s) have only been tested by myself.


## Launcher for many single-core processes

On the frontend, run:

    oarsub -S "pathTo/launcher_serial.py pathTo/task pathTo/argumentfile [modules to load]"

The requested resources (default: nodes=1) and walltime (default: 1h)
as well as stdout/stderr filenames are defined as OAR-directives in
the script file.

## Launcher for MPI-processes

n/a