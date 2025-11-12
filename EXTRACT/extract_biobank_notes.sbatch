#!/usr/bin/env bash
#SBATCH --job-name=biobank_extract
#SBATCH --output=slurm-%x-%j.out
#SBATCH --error=slurm-%x-%j.err
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G

set -Eeuo pipefail

# ---- EDIT THESE FOUR LINES ----
ROOT_DIR="/data/vbio-methodsdev/SHARE/BIOBANK/2025/Raw_Data/Biobank_RPDR_notes_2025"
IDS_FILE="/path/to/ids.txt"
OUTPUT_DIR="/path/to/output_dir"
KEYPOS=1          # 1 = EMPI, 2 = EPIC_PMRN, 4 = MRN
# -------------------------------

cd "${SLURM_SUBMIT_DIR:-$PWD}"

chmod +x ./rpdr_note_extract.sh

./rpdr_note_extract.sh "$ROOT_DIR" "$IDS_FILE" "$OUTPUT_DIR" "$KEYPOS"

