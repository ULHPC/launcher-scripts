#!/usr/bin/env python
"""Launcher for serial processes based on bash script
launcher_serial.sh"""

###   The OAR  directives  ###
# If oarsub is run in batch mode with -S (or --scanscript)
# the script is scanned for '#OAR' as OAR directives.
# They are:
#
#        Number of resources:
#OAR -l nodes=1,walltime=1
#        Job name (max. 15 characters, no blank spaces and
#        start with alphanumeric character):
#OAR -n SerialGNUParallel
#        Redirecting stdout and stderr
#        (OAR.%jobid%.stdout, OAR.%jobid%.stderr)
#        to the following:
#OAR -O SerialGNUParallel-out-%jobid%.log
#OAR -E SerialGNUParallel-err-%jobid%.log

from os import environ, system
from time import time, ctime
from sys import argv
import datetime

def readAvailableNodes( nodefilename ):
    """Return a dict of node names
    with their respective amount of cores."""
    # read file
    f = open( nodefilename )
    cores = f.read().split()
    f.close()
    # count unique entries (that is nodes)
    # to obtain available cores
    nodes = {}
    for node in list(set(cores)):
        nodes[node] = cores.count(node)
    # finish
    return nodes
    

if __name__ == "__main__":
    if len(argv)<3:
        print("Usage: %s task argumentfile [modules to load]" %argv[0])
        exit(1)
    task = argv[1]
    task_argumentFile = argv[2]
    modulesToLoad = argv[3:]

    # load required modules
    for module in modulesToLoad:
        system("module load %s" %module)

    # read available nodes
    nodes = readAvailableNodes( environ['OAR_NODEFILE'] )

    # print available node information
    print "Available:"
    for n in nodes.keys():
        print n,"with", nodes[n], "cores"

    coreDistribution = ""
    if len(nodes.keys()) > 1:
        # write nodes and number of cores into sshloginfile
        sshloginfilename = "/tmp/SSHloginFile.%i" %int(environ['OAR_JOBID'])
        fSSHloginfile = open( sshloginfilename, 'w' )
        for k in nodes.keys():
            fSSHloginfile.write("%i/oarsh %s\n" %(nodes[k], k))
        fSSHloginfile.close()
        coreDistribution = "--sshloginfile %s" %sshloginfilename
    else:
        coreDistribution =  "-j %i" %nodes[ nodes.keys()[0] ]

    # preparing command and running it
    command = "cat %s | parallel -u %s --colsep ' ' %s {}" %(task_argumentFile,
                                                             coreDistribution,
                                                             task)
    print ("%s - Starting gnuparallel" %ctime(time()) )
    timeStart = datetime.datetime.now()
    system( command )
    timeEnd = datetime.datetime.now()
    print ("%s - Finished" %ctime(time()) )
    timeDiff = (timeEnd - timeStart)
    print ( "Duration %f seconds." %((timeDiff.microseconds + (timeDiff.seconds
                                                               + timeDiff.days * 24. * 3600.) * 10**6)
                                     / 10**6) )

