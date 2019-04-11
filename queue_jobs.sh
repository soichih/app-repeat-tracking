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

## CSD fits
LMAX2=./intermediate/lmax2.mif # `jq -r '.lmax2' config.json`
LMAX4=./intermediate/lmax4.mif # `jq -r '.lmax4' config.json`
LMAX6=./intermediate/lmax6.mif # `jq -r '.lmax6' config.json`
LMAX8=./intermediate/lmax8.mif # `jq -r '.lmax8' config.json`
LMAX10=./intermediate/lmax10.mif # `jq -r '.lmax10' config.json`
LMAX12=./intermediate/lmax12.mif # `jq -r '.lmax12' config.json`
LMAX14=./intermediate/lmax14.mif # `jq -r '.lmax14' config.json`

## tracking params
CURVS="5 10 20 40 80" # `jq -r '.curvs' config.json`
MIN_LENGTH=10  # `jq -r '.min_length' config.json`
MAX_LENGTH=200 # `jq -r '.max_length' config.json`
NUM_FIBERS=$1

if [ -f $LMAX2 ]; then
    LMAXS=2
fi

if [ -f $LMAX4 ]; then
    LMAXS="$LMAXS 4"
fi

if [ -f $LMAX6 ]; then
    LMAXS="$LMAXS 6"
fi

if [ -f $LMAX8 ]; then
    LMAXS="$LMAXS 8"
fi

if [ -f $LMAX10 ]; then
    LMAXS="$LMAXS 10"
fi

if [ -f $LMAX12 ]; then
    LMAXS="$LMAXS 12"
fi

if [ -f $LMAX14 ]; then
    LMAXS="$LMAXS 14"
fi

echo "Tracking repeat ${rep}..."

## make the output directory with the second intput
mkdir rep$2
OUTDIR=rep$2

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

echo "Performing Anatomically Constrained Tractography (ACT)..."

## MRTrix3 Probabilistic
echo "Tracking iFOD2 streamlines..."
for lmax in $LMAXS; do

    fod=./intermediate/lmax$lmax.mif

    for curv in $CURVS; do

	echo "Tracking iFOD2 streamlines at Lmax ${lmax} with a maximum curvature of ${curv} degrees..."
	tckgen $fod -algorithm iFOD2 \
	       -select $NUM_FIBERS -act ./intermediate/5tt.mif -backtrack -crop_at_gmwmi -seed_gmwmi ./intermediate/gmwmi_seed.mif \
	       -angle ${curv} -minlength $MIN_LENGTH -maxlength $MAX_LENGTH \
	       ${OUTDIR}/wb_iFOD2_lmax${lmax}_curv${curv}.tck -force -nthreads $NCORE -quiet
    
    done
done

## MRTrix 0.2.12 deterministic
echo "Tracking SD_STREAM streamlines..."

for lmax in $LMAXS; do

    fod=./intermediate/lmax$lmax.mif

    for curv in $CURVS; do

	echo "Tracking SD_STREAM streamlines at Lmax ${lmax} with a maximum curvature of ${curv} degrees..."
	tckgen $fod -algorithm SD_STREAM \
	       -select $NUM_FIBERS -act ./intermediate/5tt.mif -crop_at_gmwmi -seed_gmwmi ./intermediate/gmwmi_seed.mif \
	       -angle ${curv} -minlength $MIN_LENGTH -maxlength $MAX_LENGTH \
	       ${OUTDIR}/wb_SD_STREAM_lmax${lmax}_curv${curv}.tck -force -nthreads $NCORE -quiet

    done
done

## combine different parameters into 1 output
tckedit ${OUTDIR}/wb*.tck ${OUTDIR}/track.tck -force -nthreads $NCORE -quiet

## find the final size
COUNT=`tckinfo ${OUTDIR}/track.tck | grep -w 'count' | awk '{print $2}'`
echo "Ensemble tractography generated $COUNT of a requested $TOTAL"

## if count is wrong, say so / fail / clean for fast re-tracking
if [ $COUNT -ne $TOTAL ]; then
    echo "Incorrect count. Tractography repeat $rep failed."
    rm -f ${OUTDIR}/wb*.tck
    #rm -f out/track.tck
    #exit 1
else
    echo "Correct count. Tractography complete."
    rm -f ${OUTDIR}/wb*.tck
fi

## simple summary text
tckinfo ${OUTDIR}/track.tck > ${OUTDIR}/tckinfo.txt

