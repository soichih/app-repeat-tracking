#!/bin/bash

#allows test execution
if [ -z $TASK_DIR ]; then export TASK_DIR=`pwd`; fi

T1=`./jq -r '.t1' config.json`
./fsurf submit \
	--subject='subject' \
	--input=$T1 \
	--version "6.0.0" \
	--defaced \
	--deidentified \
	| tee submit.log

#to restart job
rm -f finished
rm -f jobid

id=$(cat submit.log | grep Workflow | cut -d " " -f 2)
[ ! -z "$id" ] && echo -n $id > jobid
