# RAProd5 NLP Pipeline 

## Step 1: Export Notes from Database to Flat File (Windows)

Use `dump_sql_notes.bat` or run the command directly on CMD to export all the RAPROD5 notes into a single flat file. Note that we get rid of new line characters, so every note is in a single line/row

* **Writes to:** `\\eristwofs.partners.org\VBIO-METHODSDEV\SHARE\RAPROD5\raw_data\notes\raprod5_obs_text_full.txt`


### Optional: Quick Count Check

After export (Linux/WSL/PowerShell with grep/head equivalents):
```bash
wc -l /mnt/eristwo/SHARE/RAPROD5/raw_data/notes/raprod5_obs_text_full.txt
```

## Step 2: Batch by Patient Ranges

Batch by patient ranges of 1,000 using `batch_raprod5_notes.sbatch`.

* **Input:** `IN="/data/vbio-methodsdev/SHARE/RAPROD5/raw_data/notes/rapdrod5_obs_text_full.txt"`
* **Output:** `OUTDIR="/data/vbio-methodsdev/SHARE/RAPROD5/raw_data/notes_batches"`
* **Output files:** `rapdrod5_obs_text_full_00001_01000.txt`, `rapdrod5_obs_text_full_01001_02000.txt`, etc.
  * Each file starts with the standard header `patient_num|encounter_num|start_date|notes`
