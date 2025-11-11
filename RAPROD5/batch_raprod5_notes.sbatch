#!/bin/bash
#SBATCH --job-name=bucket_all
#SBATCH --output=logs/bucket_%j.out
#SBATCH --error=logs/bucket_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=08:00:00

set -euo pipefail

# ---- EDIT THESE ----
IN="/data/vbio-methodsdev/SHARE/RAPROD5/raw_data/notes/rapdrod5_obs_text_full.txt"
OUTDIR="/data/vbio-methodsdev/SHARE/RAPROD5/raw_data/notes_batches"
DELIM="|"
# --------------------

mkdir -p "$OUTDIR" logs
stem="${IN##*/}"; stem="${stem%.*}"
LOGFILE="logs/bucket_${SLURM_JOB_ID:-manual}.progress"
: > "$LOGFILE"   # reset progress log

# Pre-create 77 bucket files with required header
for i in $(seq 0 76); do
  lo=$(( i*1000 + 1 ))
  hi=$(( (i+1)*1000 ))
  printf 'patient_num|encounter_num|start_date|notes\n' \
    > "$OUTDIR/${stem}_$(printf '%05d_%05d' "$lo" "$hi").txt"
done

# One-pass stream: route each line; log rows processed periodically
LC_ALL=C awk -v FS="$DELIM" -v out="$OUTDIR" -v s="$stem" -v logfile="$LOGFILE" '
  {
    if ((NR % 1000000) == 0) { printf("rows processed: %d\n", NR) >> logfile; fflush(logfile) }
    n = $1 + 0
    if (n < 1 || n > 77000) next
    b  = int((n-1)/1000)
    lo = b*1000 + 1
    hi = (b+1)*1000
    fn = sprintf("%s/%s_%05d_%05d.txt", out, s, lo, hi)
    print >> fn
  }
  END {
    printf("rows processed: %d (final)\n", NR) >> logfile; fflush(logfile)
  }
' "$IN"

