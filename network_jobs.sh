#!/bin/bash

set -e
set -x

source /cvmfs/oasis.opensciencegrid.org/osg/modules/lmod/current/init/bash

module load matlab/R2018b
./main $1
