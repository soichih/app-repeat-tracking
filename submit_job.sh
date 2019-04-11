#!/bin/bash -l

export LD_LIBRARY_PATH=/usr/lib/fsl/5.0:/usr/share/fsl/5.0/bin:/.singularity.d/libs
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/fsl/5.0/bin:/usr/lib/ants:/mrtrix3/bin

export FSLMULTIFILEQUIT=TRUE
export FSLCLUSTER_MAILOPTS=n
export FSLTCLSH=/usr/bin/tclsh
export FSLWISH=/usr/bin/wish
export FSLBROWSER=/etc/alternatives/x-www-browser
export FSLDIR=/usr/share/fsl/5.0
export FSLOUTPUTTYPE=NIFTI_GZ

## define number of threads to use
NCORE=1

## export more log messages
set -x
set -e

##
## parse inputs
##

## file inputs
ANAT=./t1.nii.gz # `jq -r '.anat' config.json`

## CSD fits
LMAX2=./lmax2.nii.gz # `jq -r '.lmax2' config.json`
LMAX4=./lmax4.nii.gz # `jq -r '.lmax4' config.json`
LMAX6=./lmax6.nii.gz # `jq -r '.lmax6' config.json`
LMAX8=./lmax8.nii.gz # `jq -r '.lmax8' config.json`
LMAX10=./lmax10.nii.gz # `jq -r '.lmax10' config.json`
LMAX12=./lmax12.nii.gz # `jq -r '.lmax12' config.json`
LMAX14=./lmax14.nii.gz # `jq -r '.lmax14' config.json`

## tracking params
CURVS="5 10 20 40 80" # `jq -r '.curvs' config.json`
MIN_LENGTH=10  # `jq -r '.min_length' config.json`
MAX_LENGTH=200 # `jq -r '.max_length' config.json`
NUM_FIBERS=$1
#NUM_FIBERS=`jq -r '.num_fibers' config.json`

##
## begin execution
##

echo "Converting estimated CSD fit(s) into MRTrix3 format..."

if [ -f $LMAX2 ]; then
    echo "Converting lmax2..."
    mrconvert ${LMAX2} ./intermediate/lmax2.mif -force -nthreads $NCORE -quiet
    LMAXS=2
fi

if [ -f $LMAX4 ]; then
    echo "Converting lmax4..."
    mrconvert ${LMAX4} ./intermediate/lmax4.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 4"
fi

if [ -f $LMAX6 ]; then
    echo "Converting lmax6..."
    mrconvert ${LMAX6} ./intermediate/lmax6.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 6"
fi

if [ -f $LMAX8 ]; then
    echo "Converting lmax8..."
    mrconvert ${LMAX8} ./intermediate/lmax8.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 8"
fi

if [ -f $LMAX10 ]; then
    echo "Converting lmax10..."
    mrconvert ${LMAX10} ./intermediate/lmax10.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 10"
fi

if [ -f $LMAX12 ]; then
    echo "Converting lmax12..."
    mrconvert ${LMAX12} ./intermediate/lmax12.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 12"
fi

if [ -f $LMAX14 ]; then
    echo "Converting lmax14..."
    mrconvert ${LMAX14} ./intermediate/lmax14.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 14"
fi

## convert anatomy
mrconvert $ANAT ${anat}.mif -force -nthreads $NCORE -quiet

echo "Creating 5-Tissue-Type (5TT) tracking mask..."

## convert anatomy 
5ttgen fsl ${anat}.mif ./intermediate/5tt.mif -nocrop -sgm_amyg_hipp -tempdir ./tmp -force -nthreads $NCORE -quiet

## generate gm-wm interface seed mask
5tt2gmwmi 5tt.mif ./intermediate/gmwmi_seed.mif -force -nthreads $NCORE -quiet
