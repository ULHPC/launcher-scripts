#!/usr/bin/env python
"""Launcher for serial processes based on bash script
launcher_serial.sh

Run with oarsub -S './@file'
"""

###   The OAR  directives  ###
# If oarsub is run in batch mode with -S (or --scanscript)
# the script is scanned for '#OAR' as OAR directives. 
# They are:
#
#        Number of resources:
#OAR -l nodes=2,walltime=1
#        Job name (max. 15 characters, no blank spaces and
#        start with alphanumeric character):
#OAR -n SerialGNUParallel
#        Redirecting stdout and stderr
#        (OAR.%jobid%.stdout, OAR.%jobid%.stderr)
#        to the following:
#OAR -O SerialGNUParallel-%jobid%.log
#OAR -E SerialGNUParallel-%jobid%.log

from os import environ, system
from time import time, ctime

localpath = "%s/testing" %environ['HOME']
task = "%s/testprocess.py" %localpath
task_argumentFile = "%s/argumentlist.dat" %localpath
modulesToLoad = []


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
        fSSHloginfile = open( "/tmp/SSHloginFile.%i" %int(environ['OAR_JOBID']),
                              'w' )
        for k in nodes.keys():
            fSSHloginfile.write("%i/oarsh %s\n" %(nodes[k], k))
        fSSHloginfile.close()
        coreDistribution = "--sshloginfile %s" %sshloginfilename
    else:
        coreDistribution =  "-j %i" %nodes[ nodes.keys()[0] ]


    command = "cat %s | parallel -u %s --colsep ' ' %s {}" %(task_argumentFile,
                                                             coreDistribution,
                                                             task)
    print ("Starting gnuparallel now %s" %ctime(time()) )
    system( command )
    print ("Finishing %s" %ctime(time()) )
