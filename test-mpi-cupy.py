#!/usr/bin/env python
import cupy
from mpi4py import MPI
comm = MPI.COMM_WORLD
rank = comm.rank
size = comm.size
# Test 1: bcast (Python object)
print(f"{rank}: test MPI.Comm.bcast() (python object serialization)", flush=True)
data = None
if rank == 0:
    data = cupy.arange(10)
else:
    data = None
data = comm.bcast(data, root=0)
print(f"{rank}: {data}", flush=True)
comm.barrier()
# Test 2: Bcast (memory buffer)
print(f"{rank}: test MPI.Comm.Bcast() (memory buffer)", flush=True)
if rank == 0:
    data = cupy.arange(10, dtype='f8')
else:
    data = cupy.empty(10, dtype='f8')
comm.Bcast(data, root=0)
print(f"{rank}: {data}", flush=True)