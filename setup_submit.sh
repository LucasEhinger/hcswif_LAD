#!/bin/bash
# Environment setup for running lad_replay batch jobs on MIT SUBMIT (HTCondor).
# Counterpart to setup.sh, which loads modules on the JLab ifarm. This
# version loads ROOT from the CVMFS LCG view hcana was actually built
# against, then points at the already-built hcana/LADlib install dirs.
#
# This script is sourced by run_lad_replay_submit.sh inside each job; it is
# not tied to any per-job scratch copy, since the compiled hcana/LADlib
# libraries themselves aren't edited between job submission and job start
# (only lad_replay's SCRIPTS/DBASE/PARAM configuration is, which is what
# make_tar_submit.sh snapshots).

source /cvmfs/sft.cern.ch/lcg/views/LCG_105/x86_64-el9-gcc11-opt/setup.sh

HCANA_DIR=/work/submit/ehingerl/hallc/software/hcana
LADLIB_DIR=/work/submit/ehingerl/hallc/software/LADlib

export LD_LIBRARY_PATH="${HCANA_DIR}/install/lib64:${LADLIB_DIR}/install/lib64:${LD_LIBRARY_PATH}"
export PATH="${HCANA_DIR}/install/bin:${PATH}"
export HCANA="${HCANA_DIR}/install/bin/hcana"

if ! command -v hcana >/dev/null; then
    echo "Could not find hcana! Check HCANA_DIR in $(readlink -f "$0")"
    exit 1
fi

echo "Setting hcana from: $HCANA"
echo "ROOT version: $(root-config --version)"
