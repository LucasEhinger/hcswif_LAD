# Running lad_replay batch jobs on MIT SUBMIT

This is the SUBMIT/HTCondor counterpart to the ifarm/swif2 workflow
described in `README.md`. It reuses `make_lad_runlist.sh` unchanged, and
mirrors `hcswif2_n_segs.sh`'s tarball-isolation trick so that editing
`lad_replay` doesn't affect jobs that are already queued or running.

New files (none of the existing hcswif files are modified):

| File | Role | ifarm equivalent |
|---|---|---|
| `setup_submit.sh` | Loads ROOT (CVMFS LCG_105 view) + hcana + LADlib | `setup.sh` |
| `make_tar_submit.sh` | Snapshots `lad_replay` into `tarballs/lad_replay.tar.gz`, preserving the `ROOTfiles`/`REPORT_OUTPUT` symlinks into `/ceph/submit` | the `tar czf lad_replay.tar.gz` step baked into hcswif.py's job prep |
| `run_lad_replay_submit.sh` | Per-job executable: extracts the tarball into the job's Condor scratch dir, then runs hcana | `hcswif2_n_segs.sh` |
| `replay_submit.sub` | HTCondor submit description; one job per run-list line | the JSON written by `hcswif.py` |

## Workflow

```bash
# 1. Generate a run list exactly as before (unchanged script):
./make_lad_runlist.sh <start_run> <end_run> <n_segs_per_file> run-lists/myrunlist.dat
#    NOTE: make_lad_runlist.sh looks for raw files under /cache/hallc/c-lad/raw
#    (the ifarm path). On SUBMIT the raw data lives at
#    /ceph/submit/data/user/e/ehingerl/hallc/raw -- edit your own copy of the
#    command, or the script's search path, accordingly before running it here.

# 2. Snapshot the current lad_replay code/config:
./make_tar_submit.sh

# 3. Submit -- one job per run list line:
condor_submit replay_submit.sub runlist=run-lists/myrunlist.dat

# 4. Monitor:
condor_q
condor_q -run          # see which execute nodes jobs landed on
condor_rm <clusterid>  # cancel, if needed
```

Because each job extracts its own private copy of `lad_replay` from the
tarball into `$_CONDOR_SCRATCH_DIR`, you can freely edit the live
`/work/submit/ehingerl/hallc/software/lad_replay` tree (e.g. to prep the next
batch) without touching jobs already running from an older snapshot. Re-run
`make_tar_submit.sh` whenever you want *new* submissions to pick up the
changes.

Output (`ROOTfiles/`, `REPORT_OUTPUT/`) lands directly in
`/ceph/submit/data/user/e/ehingerl/hallc/lad_replay/` regardless of which
snapshot a job ran from, since those are absolute symlinks preserved inside
the tarball -- no separate output-copy step is needed.
