# Python version of launcher scripts

## Launcher for many single-core processes

On frontend run:

    oarsub -S "pathTo/launcher_serial.py pathTo/task pathTo/argumentfile [modules to load]"

The requested resources (default: nodes=1) and walltime (default: 1h)
as well as stdout/stderr filenames are defined as OAR-directives in
script file.

## Launcher for MPI-processes

n/a