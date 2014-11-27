#!/usr/bin/env python
from os import system, environ
from sys import argv
from time import sleep, time, ctime
from socket import gethostname

waitingtime = 2
print ("test %i %s" %(int(argv[1]), __name__))

outfilename = "out_%i.dat" %int(argv[1])

hostname=gethostname().split(".")[0]



def appendTextToFile( filename, text ):
    f=open( filename, "a" )
    f.write( text )
    f.close()


if __name__ == '__main__':
    # beginning
    text = "%s: proc %i on host %s will now wait for %i secs.\n" %(ctime(time()),
                                                                  int(argv[1]),
                                                                  hostname,
                                                                  waitingtime)
    appendTextToFile( outfilename, text )

    # waiting
    sleep( waitingtime )

    # ending
    text = "%s: proc %i on host %s has waited enough. EXITING\n" %(ctime(time()),
                                                                   int(argv[1]),
                                                                   hostname)
    appendTextToFile( outfilename, text )
