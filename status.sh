#!/bin/bash

#allows test execution
if [ -z $TASK_DIR ]; then export TASK_DIR=`pwd`; fi

#return code 0 = running
#return code 1 = finished successfully
#return code 2 = failed

if [ -f finished ]; then
    echo "already finished"
    exit 1
fi

if [ -f jobid ]; then
    jobid=`cat jobid`
    ./fsurf status --id $jobid > .status
    jobstate=`cat .status | grep Status | cut -d " " -f 2`
    echo $jobstate
    if [ -z $jobstate ]; then
        exit 2 #removed?
    fi
    if [ $jobstate == "QUEUED" ]; then
        exit 0
    fi
    if [ $jobstate == "RUNNING" ]; then
	tail -1 .status
        exit 0
    fi
    if [ $jobstate == "DELETE PENDING" ]; then
        exit 2
    fi
    if [ $jobstate == "DELETED" ]; then
        exit 2
    fi
    if [ $jobstate == "COMPLETED" ]; then
        #need to download result as part of status call.. (
	#TODO should I spawn a separate process to do that?)
	./fsurf output --id $jobid
	outfile=${jobid}_subject_output.tar.bz2 #hope this won't change..
	if [ -s ${outfile} ]; then
		tar -jxvf ${outfile} && rm $outflie
		mv subject output 
		./fsurf remove --id $jobid
	       	touch finished
		exit 1
	else
		echo "failed to download output file"
		exit 2
	fi
    fi

    #assume failed for all other state
    #'ERROR'
    #'FAILED',
    exit 2
fi

echo "can't determine the status!"
exit 3
