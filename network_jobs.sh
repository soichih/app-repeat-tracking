#!/bin/bash

set -e
set -x

module load matlab/2017a
./main $1
