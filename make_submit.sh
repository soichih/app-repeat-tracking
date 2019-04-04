#!/bin/bash

cat << EOF > submit.job
universe = vanilla
executable = mrtrix3_tracking.sh

Requirements = HAS_SINGULARITY == TRUE

+ProjectName="Diffusion-predictor"
+SingularityImage = "/cvmfs/singularity.opensciencegrid.org/brainlife/mrtrix3:3.0_RC3"
+SingularityBindCVMFS = True

should_transfer_files = IF_NEEDED
when_to_transfer_output = ON_EXIT

transfer_input_files = `jq -r '.anat' config.json`,`jq -r '.lmax2' config.json`,`jq -r '.lmax4' config.json`,`jq -r '.lmax6' config.json`,`jq -r '.lmax8' config.json`,`jq -r '.lmax10' config.json`,`jq -r '.lmax12' config.json`,`jq -r '.lmax14' config.json`
transfer_output_files = out

output = out
error = err
log = log

queue
EOF
