#!/bin/bash

#allows test execution
if [ -z $TASK_DIR ]; then export TASK_DIR=`pwd`; fi

jobid=`cat jobid`
condor_rm $jobid
#./fsurf remove --id $jobid
