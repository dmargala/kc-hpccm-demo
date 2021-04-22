FROM nvcr.io/nvidia/cuda:11.0-devel-ubuntu18.04

# GNU compiler
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        g++ \
        gcc \
        gfortran && \
    rm -rf /var/lib/apt/lists/*

# GDRCOPY version 2.1
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        make \
        wget && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://github.com/NVIDIA/gdrcopy/archive/v2.1.tar.gz && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/v2.1.tar.gz -C /var/tmp -z && \
    cd /var/tmp/gdrcopy-2.1 && \
    mkdir -p /usr/local/gdrcopy/include /usr/local/gdrcopy/lib64 && \
    make PREFIX=/usr/local/gdrcopy lib lib_install && \
    echo "/usr/local/gdrcopy/lib64" >> /etc/ld.so.conf.d/hpccm.conf && ldconfig && \
    rm -rf /var/tmp/gdrcopy-2.1 /var/tmp/v2.1.tar.gz
ENV CPATH=/usr/local/gdrcopy/include:$CPATH \
    LIBRARY_PATH=/usr/local/gdrcopy/lib64:$LIBRARY_PATH

# Mellanox OFED version 4.5-1.0.1.0
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        wget && \
    rm -rf /var/lib/apt/lists/*
RUN wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add - && \
    mkdir -p /etc/apt/sources.list.d && wget -q -nc --no-check-certificate -P /etc/apt/sources.list.d https://linux.mellanox.com/public/repo/mlnx_ofed/4.5-1.0.1.0/ubuntu18.04/mellanox_mlnx_ofed.list && \
    apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ibverbs-utils \
        libibmad \
        libibmad-devel \
        libibumad \
        libibumad-devel \
        libibverbs-dev \
        libibverbs1 \
        libmlx4-1 \
        libmlx4-dev \
        libmlx5-1 \
        libmlx5-dev \
        librdmacm-dev \
        librdmacm1 && \
    rm -rf /var/lib/apt/lists/*

# UCX version 1.8.1
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        binutils-dev \
        file \
        libnuma-dev \
        make \
        wget && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://github.com/openucx/ucx/releases/download/v1.8.1/ucx-1.8.1.tar.gz && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/ucx-1.8.1.tar.gz -C /var/tmp -z && \
    cd /var/tmp/ucx-1.8.1 &&   ./configure --prefix=/usr/local/ucx --enable-mt --enable-optimizations --with-cuda=/usr/local/cuda --with-gdrcopy=/usr/local/gdrcopy --with-verbs && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /var/tmp/ucx-1.8.1 /var/tmp/ucx-1.8.1.tar.gz
ENV CPATH=/usr/local/ucx/include:$CPATH \
    LD_LIBRARY_PATH=/usr/local/ucx/lib:$LD_LIBRARY_PATH \
    LIBRARY_PATH=/usr/local/ucx/lib:$LIBRARY_PATH \
    PATH=/usr/local/ucx/bin:$PATH

# SLURM PMI2 version 20.02.5
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bzip2 \
        file \
        make \
        perl \
        tar \
        wget && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://download.schedmd.com/slurm/slurm-20.02.5.tar.bz2 && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/slurm-20.02.5.tar.bz2 -C /var/tmp -j && \
    cd /var/tmp/slurm-20.02.5 &&   ./configure --prefix=/usr/local/slurm-pmi2 && \
    cd /var/tmp/slurm-20.02.5 && \
    make -C contribs/pmi2 install && \
    rm -rf /var/tmp/slurm-20.02.5 /var/tmp/slurm-20.02.5.tar.bz2

# OpenMPI version 4.0.3
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bzip2 \
        file \
        hwloc \
        libnuma-dev \
        make \
        openssh-client \
        perl \
        tar \
        wget && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://www.open-mpi.org/software/ompi/v4.0/downloads/openmpi-4.0.3.tar.bz2 && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/openmpi-4.0.3.tar.bz2 -C /var/tmp -j && \
    cd /var/tmp/openmpi-4.0.3 &&  CC=gcc CXX=g++ F77=gfortran F90=gfortran FC=gfortran ./configure --prefix=/usr/local/openmpi --disable-getpwuid --disable-oshmem --enable-fortran --enable-mca-no-build=btl-uct --enable-orterun-prefix-by-default --with-cuda --with-pmi=/usr/local/slurm-pmi2 --with-slurm --with-ucx --without-verbs && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    echo "/usr/local/openmpi/lib" >> /etc/ld.so.conf.d/hpccm.conf && ldconfig && \
    rm -rf /var/tmp/openmpi-4.0.3 /var/tmp/openmpi-4.0.3.tar.bz2
ENV PATH=/usr/local/openmpi/bin:$PATH

# Anaconda
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        wget && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp http://repo.anaconda.com/miniconda/Miniconda3-py38_4.8.3-Linux-x86_64.sh && \
    bash /var/tmp/Miniconda3-py38_4.8.3-Linux-x86_64.sh -b -p /usr/local/anaconda && \
    /usr/local/anaconda/bin/conda init && \
    ln -s /usr/local/anaconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    . /usr/local/anaconda/etc/profile.d/conda.sh && \
    conda activate base && \
    conda install -y numba numpy pip && \
    /usr/local/anaconda/bin/conda clean -afy && \
    rm -rf /var/tmp/Miniconda3-py38_4.8.3-Linux-x86_64.sh

ENV PATH=/usr/local/anaconda/bin:$PATH

# pip
RUN pip --no-cache-dir install cupy-cuda110==8.6.0

# https://github.com/mpi4py/mpi4py/archive/master.tar.gz
RUN mkdir -p /var/tmp && wget -q -nc --no-check-certificate -P /var/tmp https://github.com/mpi4py/mpi4py/archive/master.tar.gz && \
    mkdir -p /var/tmp && tar -x -f /var/tmp/master.tar.gz -C /var/tmp -z && \
    cd /var/tmp/mpi4py-master && \
    python setup.py build && \
    cd /var/tmp/mpi4py-master && \
    python setup.py install && \
    rm -rf /var/tmp/mpi4py-master /var/tmp/master.tar.gz

ENV OMPI_MCA_pml=ucx \
    PATH=/usr/local/anaconda/bin:$PATH \
    UCX_NET_DEVICES=mlx5_0:1,mlx5_2:1,mlx5_4:1,mlx5_6:1 \
    UCX_TLS=rc,cuda_copy,gdr_copy,cuda_ipc,sm,dc,self

COPY test-mpi-cupy.py /usr/local/bin/test-mpi-cupy.py

ENTRYPOINT ["/usr/local/bin/test-mpi-cupy.py"]


