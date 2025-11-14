# NILE Processor README

A Java-based CSV processor that uses the NILE library for Named Entity Recognition (NER) on medical notes.

---

## Requirements

- Java JDK 20 or later (`java` and `javac` available on `PATH`)
  - Check if Java is installed by running `java -version` in CMD or Linux terminal
  - Download JDK 20: [Oracle JDK 20 Archive Downloads](https://www.oracle.com/java/technologies/javase/jdk20-archive-downloads.html)
- `NILE` directory and `NILE/lib` JARs in the project folder
- Example input files and dictionary are provided for quick testing

### Directory Layout (Example)

```text
.
├─ NILE/
│  ├─ NILECSVProcessor.java (and/or .class)
│  ├─ NER_dictionary.txt
│  └─ lib/
├─ data/
│  └─ example_csv.csv
└─ output/
   └─ csv_processing/
```

---

## Usage

### 1. Compile (only needed if building from source)

Navigate to the project root: NILE_java_SEP2026/refactored-nile-processing-main/  and from here, run the following:

#### macOS / Linux

```bash
javac -cp ".:NILE/lib/nile_20.jar:NILE/lib/opencsv-5.12.0.jar:NILE/lib/commons-lang3-3.12.0.jar:NILE/lib/commons-collections4-4.4.jar" \
  NILE/NILECSVProcessor.java
```

#### Windows (Command Prompt)

```bat
javac -cp ".;NILE\lib\nile_20.jar;NILE\lib\opencsv-5.12.0.jar;NILE\lib\commons-lang3-3.12.0.jar;NILE\lib\commons-collections4-4.4.jar" NILE\NILECSVProcessor.java
```

---

### 2. Run

#### macOS / Linux

```bash
java -cp ".:NILE/lib/nile_20.jar:NILE/lib/opencsv-5.12.0.jar:NILE/lib/commons-lang3-3.12.0.jar:NILE/lib/commons-collections4-4.4.jar" \
  NILE.NILECSVProcessor \
  --dictionary-path NILE/NER_dictionary.txt \
  --input-csv data/example_csv.csv \
  --output-csv output/csv_processing/output.csv
```

#### Windows (Command Prompt)

```bat
java -cp ".;NILE\lib\nile_20.jar;NILE\lib\opencsv-5.12.0.jar;NILE\lib\commons-lang3-3.12.0.jar;NILE\lib\commons-collections4-4.4.jar" NILE.NILECSVProcessor ^
  --dictionary-path NILE\NER_dictionary.txt ^
  --input-csv data\example_csv.csv ^
  --output-csv output\csv_processing\output.csv
```

---

### 3. Example Data

Example input CSV: `NILE_java_SEP2026/refactored-nile-processing-main/NILE/data/example_csv.csv`

---

## Parameters

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `--dictionary-path` | Path to the NER dictionary file (e.g., `NILE/NER_dictionary.txt`) |
| `--input-csv` | Path to the input CSV file |
| `--output-csv` | Path to the output CSV file |

### Optional Column Mappings (with defaults)

| Parameter | Default Value |
|-----------|---------------|
| `--patient-num-col` | `patient_num` |
| `--encounter-num-col` | `encounter_num` |
| `--start-date-col` | `start_date` |
| `--notes-col` | `notes` |

### Example with Explicit Column Mappings

```bash
java -cp ".:NILE/lib/nile_20.jar:NILE/lib/opencsv-5.12.0.jar:NILE/lib/commons-lang3-3.12.0.jar:NILE/lib/commons-collections4-4.4.jar" \
  NILE.NILECSVProcessor \
  --dictionary-path NILE/NER_dictionary.txt \
  --input-csv data/example_csv.csv \
  --output-csv output/csv_processing/output.csv \
  --patient-num-col patient_num \
  --encounter-num-col encounter_num \
  --start-date-col start_date \
  --notes-col notes
```

---

## Output

The tool reads a comma-separated CSV file and writes a pipe-delimited CSV with columns:

```text
patient_num|encounter_num|start_date|code_certainty
```

---

## Quality Control

After processing, verify that the NILE output contains the expected number of records. Check that the note count in the output matches the input note count. If some notes were dropped during processing, certain characters in the notes field may be causing issues with the NILE run.

To clean problematic characters from your input data, use the following Python/pandas snippet:

```python
df["notes"] = (
    df["notes"]
    .str.strip(r"\/")                         # remove leading/trailing \ or /
    .str.replace('"', "", regex=False)        # remove all double quotes
)
```

This preprocessing step removes or replaces characters that commonly interfere with CSV parsing and NILE processing.
