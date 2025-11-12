#!/usr/bin/env bash
set -Eeuo pipefail

# Description: Batch extract reports for specified IDs from all files in subdirectories of a root folder.
# Usage: batch_extract_all.sh <ROOT_DIR> <IDS_FILE> <OUTPUT_DIR> [KEYPOS]
# Example: batch_extract_all.sh ../test_biobank/ ids.txt extracted_biobank 1
#
# Notes:
# - KEYPOS = 1 for EMPI, 2 for EPIC_PMRN, 4 for MRN
# - Requires: gawk
# - This script embeds the AWK program and cleans it up automatically.

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: $0 <ROOT_DIR> <IDS_FILE> <OUTPUT_DIR> [KEYPOS]" >&2
  exit 1
fi

ROOT_DIR="$1"
IDS_FILE="$2"
OUTPUT_DIR="$3"
KEYPOS="${4:-1}"

# Verify required tools and files
if ! command -v gawk >/dev/null 2>&1; then
  echo "ERROR: gawk not found. Please install GNU Awk." >&2
  exit 2
fi
if [[ ! -d "$ROOT_DIR" ]]; then
  echo "ERROR: Input directory not found: $ROOT_DIR" >&2
  exit 4
fi
if [[ ! -f "$IDS_FILE" ]]; then
  echo "ERROR: IDs file not found: $IDS_FILE" >&2
  exit 5
fi

# Ensure output directory exists
if [[ ! -d "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR" || { echo "ERROR: Unable to create output directory $OUTPUT_DIR" >&2; exit 6; }
fi

# Prepare log file for progress messages
log_file="$OUTPUT_DIR/extraction_progress.log"
: > "$log_file"   # truncate log file to start fresh

# Find all immediate subdirectories under ROOT_DIR
shopt -s nullglob
subdirs=( "$ROOT_DIR"/*/ )
if (( ${#subdirs[@]} == 0 )); then
  echo "No subdirectories found under: $ROOT_DIR" | tee -a "$log_file" >&2
  exit 7
fi

# Initialize counters for summary
dirs_count=${#subdirs[@]}
files_processed=0
files_with_matches=0
files_no_matches=0
files_skipped=0

echo "Starting extraction in $dirs_count subdirectories under $ROOT_DIR" | tee -a "$log_file"

# Define expected header pattern (to identify valid report files)
HEADER_REGEX='^EMPI\|EPIC_PMRN\|MRN_Type\|MRN\|Report_Number\|Report_Date_Time\|Report_Description\|Report_Status\|Report_Type\|Report_Text[[:space:]]*$'
BOM=$'\xEF\xBB\xBF'  # Byte Order Mark (UTF-8 BOM)

# --- Embed AWK program into a temp file and clean up on exit ---
awk_tmp="$(mktemp "${TMPDIR:-/tmp}/export_notes.XXXXXX" 2>/dev/null || mktemp -t export_notes)"
trap 'rm -f "$awk_tmp"' EXIT

cat > "$awk_tmp" <<'AWK_PROG'
# GNU awk script: export_notes.awk
# Usage example:
#   gawk -v keypos=1 -f export_notes.awk ids.txt input.txt > output.psv
# keypos = 1 for EMPI, 2 for EPIC_PMRN, 4 for MRN

BEGIN {
  RS = "\\[report_end\\][[:space:]]*";  # one report block per record
  OFS = "|";
  header = "EMPI|EPIC_PMRN|MRN_Type|MRN|Report_Number|Report_Date_Time|Report_Description|Report_Status|Report_Type|Report_Text";
}

# Load IDs (ids.txt) — split manually by newlines because RS is not newline.
NR == FNR {
  n = split($0, A, /\r?\n/);
  for (i = 1; i <= n; i++) if (A[i] != "") ids[A[i]] = 1;
  next;
}

# Process each report block from the big file
{
  # Find the first non-header pipe-delimited line -> metadata line
  meta = ""; meta_idx = 0;
  n = split($0, L, /\n/);

  for (i = 1; i <= n; i++) {
    if (L[i] ~ /\|/) {
      if (L[i] ~ /^EMPI\|EPIC_PMRN\|MRN_Type\|MRN\|Report_Number\|Report_Date_Time\|Report_Description\|Report_Status\|Report_Type\|Report_Text[[:space:]]*$/) {
        continue;  # skip any header line that reappears inside the file
      }
      meta = L[i]; meta_idx = i; break;
    }
  }
  if (meta == "") next;

  # Strip CR in meta just to parse fields cleanly (meta is not output as free text)
  gsub(/\r/, "", meta);
  split(meta, F, /\|/);

  kp = (keypos ? keypos : 1);   # which identifier to match (default EMPI)
  keyval = F[kp];
  if (!(keyval in ids)) next;

  # -------- Build Report_Text with exact rule: \n -> " ", \r -> " " ----------
  # Start with F[10] (text on the metadata line), then each subsequent line.
  # IMPORTANT: We do NOT collapse or trim spaces—only replace LF/CR with spaces.
  text = (length(F) >= 10 ? F[10] : "");
  # Replace any CR that might exist inside F[10]
  gsub(/\r/, " ", text);

  for (j = meta_idx + 1; j <= n; j++) {
    # Replace CR in the body line (if present)
    gsub(/\r/, " ", L[j]);
    # The newline between lines becomes exactly one space (NOTE: code below uses TWO spaces per your snippet)
    text = text "  " L[j];
  }

  # Protect pipe delimiter: if notes can contain '|', replace with space so we keep 10 columns
  # (Remove this line if you must preserve literal '|' in Report_Text)
  gsub(/\|/, " ", text);

  # Print header once (only if at least one match occurs)
  if (!printed++) print header;

  # Defensive: ensure all meta fields exist
  empi     = (length(F) >= 1  ? F[1] : "");
  epic     = (length(F) >= 2  ? F[2] : "");
  mrn_type = (length(F) >= 3  ? F[3] : "");
  mrn      = (length(F) >= 4  ? F[4] : "");
  rep_no   = (length(F) >= 5  ? F[5] : "");
  rep_dt   = (length(F) >= 6  ? F[6] : "");
  rep_desc = (length(F) >= 7  ? F[7] : "");
  rep_stat = (length(F) >= 8  ? F[8] : "");
  rep_type = (length(F) >= 9  ? F[9] : "");

  print empi, epic, mrn_type, mrn, rep_no, rep_dt, rep_desc, rep_stat, rep_type, text;
}
AWK_PROG

# Loop over each subdirectory
for dir in "${subdirs[@]}"; do
  dir="${dir%/}"  # strip trailing slash
  subdir_name="$(basename "$dir")"

  # Use find to list all files in this subdirectory (recursively, if nested folders exist)
  { while IFS= read -r -d '' file; do
      [[ -f "$file" ]] || continue  # safety check

      # Read the first line of the file to verify header (skip file if header doesn't match)
      firstline=""
      IFS= read -r firstline < "$file" || true
      firstline=${firstline%$'\r'}          # remove trailing CR if present (Windows line endings)
      firstline=${firstline#$BOM}           # remove BOM if present at start
      if [[ ! $firstline =~ $HEADER_REGEX ]]; then
        ((files_skipped++))
        continue  # skip this file, not in expected format
      fi

      base_name="$(basename -- "$file")"
      base_no_ext="${base_name%.*}"        # remove file extension (e.g. ".txt")
      output_file="${OUTPUT_DIR}/${subdir_name}_${base_no_ext}_extracted.txt"
      temp_file="${output_file}.tmp"

      echo "Processing $subdir_name, running extraction on $base_name..." | tee -a "$log_file"

      # Run embedded AWK script to extract matching records
      if LC_ALL=C gawk -v keypos="$KEYPOS" -f "$awk_tmp" "$IDS_FILE" "$file" > "$temp_file"; then
        if [[ -s "$temp_file" ]]; then
          mv -f "$temp_file" "$output_file"
          ((files_with_matches++))
        else
          rm -f "$temp_file"
          ((files_no_matches++))
        fi
        ((files_processed++))
      else
        # If AWK execution failed, log an error (do not terminate the whole script)
        rm -f "$temp_file"  # remove any partial output
        echo "ERROR: AWK processing failed for file $file" | tee -a "$log_file" >&2
      fi

  done < <(find "$dir" -type f -print0 2>/dev/null); } || true

done

# After processing all directories, log summary information
echo "Extraction complete." | tee -a "$log_file"
echo "Directories processed: $dirs_count" | tee -a "$log_file"
echo "Files processed (with matching IDs): $files_with_matches" | tee -a "$log_file"
echo "Files processed (no matching IDs): $files_no_matches" | tee -a "$log_file"
echo "Files skipped (header format mismatch): $files_skipped" | tee -a "$log_file"
