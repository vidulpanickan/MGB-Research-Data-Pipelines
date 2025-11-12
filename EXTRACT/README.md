# Note Extraction Jobs

This folder contains small SLURM jobs for extracting notes for a given set of patients.

## Files

- `extract_from_nile_output.sbatch`  
  Run this to extract **NILE-processed output** (post-NILE notes) for a specific set of patients.

- `extract_biobank_notes.sbatch`  
  Run this to extract **raw Biobank / RPDR notes** for a specific set of patients using `rpdr_note_extract.sh`.

- `rpdr_note_extract.sh`  
  Bash script that does the actual extraction (called by the `.sbatch` jobs).

## How to use

1. **Edit the sbatch scripts**  
   Open each of  
   - `extract_from_nile_output.sbatch`  
   - `extract_biobank_notes.sbatch`  
   
   and update the paths at the top (e.g. `ROOT_DIR`, `IDS_FILE`, `OUTPUT_DIR`, `KEYPOS`) to match your project.

2. **Submit the job(s)** from your cluster login node:
   ```bash
   sbatch extract_from_nile_output.sbatch
   # or
   sbatch extract_biobank_notes.sbatch
   ```

3. **Check logs**  
   SLURM logs (`slurm-*.out` / `slurm-*.err`) and the extraction log inside your `OUTPUT_DIR` (e.g. `extraction_progress.log`) will show progress and any errors.
