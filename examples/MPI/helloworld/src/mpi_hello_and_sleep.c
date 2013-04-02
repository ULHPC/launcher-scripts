/**
 * @file   mpi_hello_and_sleep.c
 * @author Sebastien Varrette <Sebastien.Varrette@uni.lu>
 * Time-stamp: <Dim 2013-03-31 12:36 svarrette>
 *
 * Copyright (c) 2012 Sebastien Varrette <Sebastien.Varrette@uni.lu>
 *               http://varrette.gforge.uni.lu
 *
 * @version 0.1
 *
 * @brief  A simple template for an MPI program that print and hello and wait
 * for n seconds. The elapsed time of the program is also computed.  
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>     /* for printf */
#include <stdlib.h>    /* for exit  */
#include <stdarg.h>    /* for va_{list,args... */
#include <unistd.h>    /* for sleep */
#include <mpi.h>

int id = 0; // MPI id for the current process (set global to be used in xprintf)

/**
 * Redefinition of the printf to include the buffer flushing
 */
void xprintf(char *format, ...) {
    va_list args;
    va_start(args, format);
    printf("[Node %i] ", id);
    vprintf(format, args);
    fflush(stdout);
}

int main(int argc, char *argv[]) {
    int p; // MPI specific: number of processors
    unsigned int n      = 0;
    double elapsed_time = 0.0;

    MPI_Init(&argc,&argv);
    MPI_Comm_size(MPI_COMM_WORLD,&p);
    MPI_Comm_rank(MPI_COMM_WORLD,&id);

    if (id == 0) {
        xprintf("Total Number of processes : %i\n",p);
        xprintf("Input n = ");
        scanf("%u", &n);
    }
    MPI_Barrier(MPI_COMM_WORLD);
    elapsed_time = -MPI_Wtime();
    // send n to the other processes
    MPI_Bcast((void *)&n, 1, MPI_UNSIGNED, 0, MPI_COMM_WORLD);
    
    // Now do your job
    xprintf("Helloword! I'll now sleep for %us\n", n);
    sleep(n);
    // at the end, compute elapsed time
    elapsed_time += MPI_Wtime();
    if (id == 0)
        xprintf("Elapsed time: %2f s\n", elapsed_time);
    MPI_Finalize();
    return 0;
}
