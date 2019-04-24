#!/bin/bash

set -e
set -x

source /cvmfs/oasis.opensciencegrid.org/osg/modules/lmod/current/init/bash

#module load matlab/R2018b

export MCRROOT=/cvmfs/connect.opensciencegrid.org/modules/packages/linux-rhel7-x86_64/gcc-4.8.5spack/matlab-R2018b-kxlw75gnubxtxbwm35774ulervu7h5fd/v95
export LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64

chmod +x ./main
./main $1
