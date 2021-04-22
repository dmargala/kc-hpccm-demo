# kc-hpccm-demo


## local environment setup (laptop)

Pre-reqs: conda and docker

```
conda create -n hpccm-demo python=3.8
conda activate hpccm-demo
conda install -c conda-forge hpccm
```

## image build

From top level of this repo, run:

```
NAME=cuda-ucx-openmpi-cupy
hpccm --recipe $NAME.py --format docker > Dockerfile
docker build -t $NAME -f Dockerfile .
docker image tag $NAME dmargala/$NAME
docker push dmargala/$NAME
```

On cori:

```
shifterimg pull dmargala/cuda-ucx-openmpi-cupy
```

## run test

Run on Cori GPU node:

```
module purge
module load cgpu
salloc -C gpu -N 1 -G 1 -c 10 -t 120
srun -n 2 -c 1 shifter --image=dmargala/cuda-ucx-openmpi-cupy:latest --entrypoint
```

Output:

```
0: test MPI.Comm.bcast() (python object serialization)
1: test MPI.Comm.bcast() (python object serialization)
0: [0 1 2 3 4 5 6 7 8 9]
1: [0 1 2 3 4 5 6 7 8 9]
0: test MPI.Comm.Bcast() (memory buffer)
1: test MPI.Comm.Bcast() (memory buffer)
0: [0. 1. 2. 3. 4. 5. 6. 7. 8. 9.]
1: [0. 1. 2. 3. 4. 5. 6. 7. 8. 9.]
```