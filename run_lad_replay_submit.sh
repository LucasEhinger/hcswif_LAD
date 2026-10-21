#!/bin/bash
# Per-job executable for HTCondor, playing the role of hcswif2_n_segs.sh on
# the JLab ifarm. Extracts the lad_replay snapshot built by
# make_tar_submit.sh into this job's own Condor scratch directory (isolating
# it from any edits made to the live lad_replay tree after submission), then
# runs hcana exactly as hcswif2_n_segs.sh does.
#
# Usage: run_lad_replay_submit.sh SCRIPT RUN EVENTS FILETYPE SEG_END SEG_START

set -e

ARGC=$#
if [[ $ARGC -ne 6 ]]; then
    echo "Usage: run_lad_replay_submit.sh SCRIPT RUN EVENTS FILETYPE SEG_END SEG_START"
    exit 1
fi

script=$1
run=$2
evt=$3
fileType=$4
seg_end=$5
seg_start=$6

hcswif_dir=$(dirname "$(readlink -f "$0")")
source "${hcswif_dir}/setup_submit.sh"

# Which snapshot to run from. Defaults to the tarball make_tar_submit.sh
# writes; override by exporting TARBALL (e.g. via the submit file's
# "environment =" line) to pin a job to an archived version instead.
TARBALL="${TARBALL:-${hcswif_dir}/tarballs/lad_replay.tar.gz}"
if [[ ! -f "$TARBALL" ]]; then
    echo "No lad_replay tarball found at $TARBALL -- run make_tar_submit.sh first"
    exit 1
fi

# $_CONDOR_SCRATCH_DIR is set by HTCondor to this job's private, auto-cleaned
# working directory on the execute node. Fall back to the cwd so this script
# can also be run by hand for testing.
SCRATCH="${_CONDOR_SCRATCH_DIR:-$(pwd)}"
WORKDIR="${SCRATCH}/lad_replay"
mkdir -p "$WORKDIR"

# Two tarball layouts are in circulation and we accept either:
#   make_tar_submit.sh      -> entries are prefixed "lad_replay/"
#   lad_replay/make_tar.sh  -> entries are the directory contents, "./..."
# Extract so that $WORKDIR ends up being the replay directory either way.
TAR_TOP=$(tar -tzf "$TARBALL" | head -1 | cut -d/ -f1)
if [[ "$TAR_TOP" == "lad_replay" ]]; then
    tar -xzf "$TARBALL" -C "$SCRATCH"
else
    tar -xzf "$TARBALL" -C "$WORKDIR"
fi

echo "Using tarball: $TARBALL (top-level entry: ${TAR_TOP}/)"
cd "$WORKDIR"
source setup.sh

runHcana="hcana -q \"${script}(${run},${evt},${fileType},1,${seg_end},${seg_start})\""
echo "pwd: $(pwd)"
echo "$runHcana"
eval $runHcana
