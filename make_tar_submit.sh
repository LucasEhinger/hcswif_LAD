#!/bin/bash
# Snapshot lad_replay into a tarball that each batch job extracts into its
# own Condor scratch directory. This is the same isolation trick used by
# hcswif2_all_segs.sh / hcswif2_n_segs.sh on the JLab ifarm ("tar -xf
# lad_replay.tar.gz"): every job works from its own private copy of the
# code/config, so editing lad_replay while jobs are queued or running can't
# collide with them.
#
# Run this once before condor_submit, and again any time you've changed
# lad_replay and want newly-submitted jobs to pick up the change. Jobs
# already extracted from an older tarball are unaffected either way.
#
# Usage: ./make_tar_submit.sh

set -e

LAD_REPLAY_DIR=/work/submit/ehingerl/hallc/software/lad_replay
TARBALL_DIR=$(dirname "$(readlink -f "$0")")/tarballs
TARBALL="${TARBALL_DIR}/lad_replay.tar.gz"

mkdir -p "$TARBALL_DIR"

# -h/--dereference is intentionally NOT used here: ROOTfiles and
# REPORT_OUTPUT under lad_replay are absolute symlinks into /ceph/submit.
# Packing them as symlinks (tar's default) rather than dereferencing means
# every job's extracted copy still writes its output to that same shared,
# persistent location -- no separate output-staging step is needed.
tar -czf "$TARBALL" -C "$(dirname "$LAD_REPLAY_DIR")" \
    --exclude='lad_replay/.git' \
    lad_replay

echo "Wrote $TARBALL"
