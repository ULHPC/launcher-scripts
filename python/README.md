# Python version of launcher scripts

## Launcher for many single-core processes

Run 

    oarsub -S "./launcher_serial.py task argumentfile [modules to load]"

Requested resources (nodes=1) and walltime (1h) are defined as OAR-directives in file.

## Launcher for MPI-processes

n/a