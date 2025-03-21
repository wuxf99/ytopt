#!/bin/bash
#This script is for running an app on a laptop using mpirun without any scheduler

# set the number of nodes (for a single node, total number of MPI processes)
let nnds=2
# set the number of nodes for the MPI ranks per run (for a single node, number of MPI ranks)
let nranks=1
# set the number of workers (nnds/nranks plus 1)
let nws=3
# set the maximum application runtime(s) as timeout baseline for each evaluation
let appto=500

#--- process processexe.pl to change the number of nodes (no change)
# set the MPI ranks per run
./processcp.pl ${nranks}

# set application timeout
./plopper.pl plopper.py ${appto}

# find the conda path
cdpath=$(conda info | grep -i 'base environment')
arr=(`echo ${cdpath}`)
cpath="$(echo ${arr[3]})/etc/profile.d/conda.sh"

#-----This part creates a submission script---------
cat >batch.job <<EOF
#!/bin/bash -x

# Script to run libEnsemble using multiprocessing on launch nodes.
# Assumes Conda environment is set up.

# To be run with central job management
# - Manager and workers run on launch node.
# - Workers submit tasks to the nodes in the job available (using exe.pl)

# Name of calling script
export EXE=run_ytopt.py

# Communication Method
export COMMS="--comms local"

# Number of workers. For multiple nodes per worker, have nworkers be a divisor of nnodes, then add 1
# e.g. for 2 nodes per worker, set nnodes = 12, nworkers = 7
export NWORKERS="--nworkers ${nws}"  # extra worker running generator (no resources needed)
# Adjust exe.pl so workers correctly use their resources

# Name of Conda environment
export CONDA_ENV_NAME=ytune

export PMI_NO_FORK=1 # Required for python kills on Theta

# Activate conda environment
#source /usr/local/miniconda/etc/profile.d/conda.sh
source $cpath
export PYTHONNOUSERSITE=1
conda activate \$CONDA_ENV_NAME

# Launch libE
python \$EXE \$COMMS \$NWORKERS --learner=RF --max-evals=8 > out.txt 2>&1
EOF
#-----This part submits the script you just created--------------
chmod +x batch.job
./batch.job
