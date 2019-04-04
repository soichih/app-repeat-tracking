#!/bin/bash -l

export LD_LIBRARY_PATH=/usr/lib/fsl/5.0:/usr/share/fsl/5.0/bin:/.singularity.d/libs
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/share/fsl/5.0/bin:/usr/lib/ants:/mrtrix3/bin

FSLDIR=/usr/local/fsl/5.0
FSLOUTPUTTYPE=NIFTI_GZ
FSLMULTIFILEQUIT=TRUE
FSLCLSH=$FSLDIR/bin/fsltcsh
FSLWISH=$FSLDIR/bin/fslwish
FSLCONFDIR=$FSLDIR/config
FSLMACHTYPE=$FSLDIR/config/fslmachtype.sh

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

NUM_FIBERS=$1 # `jq -r '.num_fibers' config.json`

##
## begin execution
##

rm -rf out/
mkdir out/

echo "Converting estimated CSD fit(s) into MRTrix3 format..."

if [ -f $LMAX2 ]; then
    echo "Converting lmax2..."
    mrconvert ${LMAX2} lmax2.mif -force -nthreads $NCORE -quiet
    LMAXS=2
fi

if [ -f $LMAX4 ]; then
    echo "Converting lmax4..."
    mrconvert ${LMAX4} lmax4.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 4"
fi

if [ -f $LMAX6 ]; then
    echo "Converting lmax6..."
    mrconvert ${LMAX6} lmax6.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 6"
fi

if [ -f $LMAX8 ]; then
    echo "Converting lmax8..."
    mrconvert ${LMAX8} lmax8.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 8"
fi

if [ -f $LMAX10 ]; then
    echo "Converting lmax10..."
    mrconvert ${LMAX10} lmax10.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 10"
fi

if [ -f $LMAX12 ]; then
    echo "Converting lmax12..."
    mrconvert ${LMAX12} lmax12.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 12"
fi

if [ -f $LMAX14 ]; then
    echo "Converting lmax14..."
    mrconvert ${LMAX14} lmax14.mif -force -nthreads $NCORE -quiet
    LMAXS="$LMAXS 14"
fi

## convert anatomy
mrconvert $ANAT ${anat}.mif -force -nthreads $NCORE -quiet

echo "Tractography will be created on lmax(s): $LMAXS"

## compute the required size of the final output
TOTAL=0

for lmax in $LMAXS; do
    for curv in $CURVS; do
	TOTAL=$(($TOTAL+$NUM_FIBERS))
    done
done

for lmax in $LMAXS; do
    for curv in $CURVS; do
	TOTAL=$(($TOTAL+$NUM_FIBERS))
    done
done

echo "Expecting $TOTAL streamlines in track.tck."

echo "Creating 5-Tissue-Type (5TT) tracking mask..."

## convert anatomy 
5ttgen fsl ${anat}.mif 5tt.mif -nocrop -sgm_amyg_hipp -tempdir ./tmp -force -nthreads $NCORE -quiet

## generate gm-wm interface seed mask
5tt2gmwmi 5tt.mif gmwmi_seed.mif -force -nthreads $NCORE -quiet

echo "Performing Anatomically Constrained Tractography (ACT)..."

## MRTrix3 Probabilistic
echo "Tracking iFOD2 streamlines..."
for lmax in $LMAXS; do

    fod=lmax$lmax.mif
	
    for curv in $CURVS; do

	echo "Tracking iFOD2 streamlines at Lmax ${lmax} with a maximum curvature of ${curv} degrees..."
	tckgen $fod -algorithm iFOD2 \
	       -select $NUM_FIBERS -act 5tt.mif -backtrack -crop_at_gmwmi -seed_gmwmi gmwmi_seed.mif \
	       -angle ${curv} -minlength $MIN_LENGTH -maxlength $MAX_LENGTH \
	       wb_iFOD2_lmax${lmax}_curv${curv}.tck -force -nthreads $NCORE -quiet
	    
    done
done

## MRTrix 0.2.12 deterministic
echo "Tracking SD_STREAM streamlines..."
    
for lmax in $LMAXS; do

    fod=lmax$lmax.mif
    
    for curv in $CURVS; do

	echo "Tracking SD_STREAM streamlines at Lmax ${lmax} with a maximum curvature of ${curv} degrees..."
	tckgen $fod -algorithm SD_STREAM \
	       -select $NUM_FIBERS -act 5tt.mif -crop_at_gmwmi -seed_gmwmi gmwmi_seed.mif \
	       -angle ${curv} -minlength $MIN_LENGTH -maxlength $MAX_LENGTH \
	       wb_SD_STREAM_lmax${lmax}_curv${curv}.tck -force -nthreads $NCORE -quiet
	
    done
done

## combine different parameters into 1 output
tckedit wb*.tck out/track.tck -force -nthreads $NCORE -quiet

## find the final size
COUNT=`tckinfo out/track.tck | grep -w 'count' | awk '{print $2}'`
echo "Ensemble tractography generated $COUNT of a requested $TOTAL"

## if count is wrong, say so / fail / clean for fast re-tracking
if [ $COUNT -ne $TOTAL ]; then
    echo "Incorrect count. Tractography failed."
    rm -f wb*.tck
    rm -f out/track.tck
    exit 1
else
    echo "Correct count. Tractography complete."
    rm -f wb*.tck
fi

## simple summary text
tckinfo out/track.tck > out/tckinfo.txt

## clear mrtrix files
rm -f *.mif

