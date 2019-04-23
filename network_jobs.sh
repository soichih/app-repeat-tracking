#!/bin/bash

set -e
set -x

module load matlab/R2017a
./main $1
