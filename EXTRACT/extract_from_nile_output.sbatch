#!/usr/bin/env bash
#SBATCH --job-name=nile_out_extract
#SBATCH --output=nile_out_extract_%j.out
#SBATCH --error=nile_outextract_%j.err
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G

set -euo pipefail

# edit these three paths
ROOT_DIR="/path/to/DIR_with_nile_output_csv_files" #if not csv, update the extention below in the find command
IDS_FILE="/path/to/patient_ids.txt"      # one patient id per line
OUT_FILE="/path/to/NILE_OUT_extracted.txt"

find "$ROOT_DIR" -type f -name '*.txt' -print0 \
  | xargs -0 awk -F'|' 'NR==FNR { ids[$1]=1; next } ($1 in ids)' "$IDS_FILE" \
  > "$OUT_FILE"

