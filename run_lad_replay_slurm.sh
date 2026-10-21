#!/bin/bash
#SBATCH --job-name=lad_replay
#SBATCH --partition=submit
#SBATCH --time=1-00:00:00
#SBATCH --mem-per-cpu=8G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-19
#SBATCH --output=/work/submit/ehingerl/hallc/software/hcswif_LAD/logs/test20_2026Sept22_slurm/%A_%a.out
#SBATCH --error=/work/submit/ehingerl/hallc/software/hcswif_LAD/logs/test20_2026Sept22_slurm/%A_%a.err
#
# SLURM array job for lad_replay -- one array task per run-list line.
#
# SLURM is the right scheduler for this workflow: per the SubMIT user guide,
# SLURM compute nodes have direct access to /ceph, /work and /cvmfs, whereas
# HTCondor here flocks to external pools whose worker nodes do NOT, which is
# why the raw/ and ROOTfiles/ symlinks only resolve under SLURM.
#
# The per-task work (unpack the pinned tarball, set up hcana, run the replay)
# is delegated to run_lad_replay_submit.sh so both schedulers share one
# validated code path. That script takes its working directory from
# $_CONDOR_SCRATCH_DIR when set and otherwise the cwd, so we simply cd into a
# node-local scratch directory first.
#
# Usage:
#   sbatch run_lad_replay_slurm.sh
#   sbatch --array=1-5 run_lad_replay_slurm.sh          # subset
#   RUNLIST=run-lists/other.dat sbatch run_lad_replay_slurm.sh
#
# Keep --array in step with the number of lines in $RUNLIST.

set -euo pipefail

HCSWIF_DIR=/work/submit/ehingerl/hallc/software/hcswif_LAD
RUNLIST="${RUNLIST:-${HCSWIF_DIR}/run-lists/test20_2026Sept22.dat}"
REPLAY_SCRIPT=SCRIPTS/LAD_COIN/PRODUCTION/replay_production_lad_spec.C
EVENTS=-1

# Which lad_replay snapshot to run from; consumed by run_lad_replay_submit.sh.
export TARBALL="${TARBALL:-/work/submit/ehingerl/hallc/software/lad_replay_versions/lad_replay_2026_Sept22.tar.gz}"

# Run list columns: run seg_end seg_start config_num zero
line=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$RUNLIST")
if [[ -z "$line" ]]; then
    echo "No line ${SLURM_ARRAY_TASK_ID} in $RUNLIST -- is --array larger than the run list?" >&2
    exit 1
fi
read -r run seg_end seg_start config_num _rest <<< "$line"

echo "=== SLURM task ${SLURM_ARRAY_TASK_ID} on $(hostname) ==="
echo "run=$run segments=${seg_start}..${seg_end} config_num=$config_num"

# Node-local scratch: the replay unpacks ~40 MB here and writes its ROOT and
# report output straight to /ceph through the symlinks, so this stays small.
SCRATCH=$(mktemp -d "/tmp/lad_replay_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}_XXXXXX")
trap 'rm -rf "$SCRATCH"' EXIT
cd "$SCRATCH"

"${HCSWIF_DIR}/run_lad_replay_submit.sh" \
    "$REPLAY_SCRIPT" "$run" "$EVENTS" "$config_num" "$seg_end" "$seg_start"

echo "=== task ${SLURM_ARRAY_TASK_ID} (run $run) finished ==="
