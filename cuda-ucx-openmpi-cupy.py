Stage0 += baseimage(image='nvcr.io/nvidia/cuda:11.0-devel-ubuntu18.04')
compiler = gnu()
Stage0 += compiler
Stage0 += gdrcopy(ldconfig=True)
Stage0 += mlnx_ofed(version='4.5-1.0.1.0')
Stage0 += ucx(
    version='1.8.1', cuda=True, configure_opts=[],
    gdrcopy='/usr/local/gdrcopy', with_verbs=True,
    with_ugni=False, with_xpmem=False,
    enable_mt=True, enable_optimizations=True, 
)
Stage0 += slurm_pmi2()
Stage0 += openmpi(
    version='4.0.3', cuda=True, infiniband=False, 
    disable_oshmem=True, ldconfig=True, ucx=True,  
    pmi='/usr/local/slurm-pmi2', enable_fortran=True,
    enable_mca_no_build='btl-uct', with_slurm=True, 
    with_verbs=False, with_ugni=False, with_cray_xpmem=False, 
    with_alps=False, toolchain=compiler.toolchain,
)
Stage0 += conda(packages=['numpy', 'numba', 'pip'], eula=True)
Stage0 += environment(variables={'PATH': '/usr/local/anaconda/bin:$PATH'})
Stage0 += pip(packages=['cupy-cuda110==8.6.0'], ospackages=[])
Stage0 += generic_build(
    build=['python setup.py build'],
    install=['python setup.py install'],
    directory='mpi4py-master',
    url='https://github.com/mpi4py/mpi4py/archive/master.tar.gz'
)
Stage0 += environment(
    variables={
        'PATH': '/usr/local/anaconda/bin:$PATH',
        'UCX_NET_DEVICES': 'mlx5_0:1,mlx5_2:1,mlx5_4:1,mlx5_6:1',
        'UCX_TLS': 'rc,cuda_copy,gdr_copy,cuda_ipc,sm,dc,self',
        'OMPI_MCA_pml': 'ucx',
    }
)
Stage0 += copy(src='test-mpi-cupy.py', dest='/usr/local/bin/test-mpi-cupy.py')
Stage0 += runscript(commands=['/usr/local/bin/test-mpi-cupy.py'])


