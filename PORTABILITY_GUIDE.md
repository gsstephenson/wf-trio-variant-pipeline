# Portability Guide: Running on Different Systems

## Quick Start for Different Environments

### Option 1: Auto-Detection (Recommended)
```bash
# Load environment settings first
source setup_environment.sh

# Then run analysis
./wf_trio_analysis.sh --all -t 16
```

### Option 2: Manual Override
```bash
# Run with explicit paths (works on any system)
./wf_trio_analysis.sh \
    --data-dir /data/human_trios/family1 \
    --all \
    -t 16
```

---

## Environment Profiles

### 🖥️ Local Server (ODYSSEUS)
**Auto-detected when:** `/mnt/data_1/CU_Boulder` exists

**Paths:**
- Data: `/mnt/data_1/CU_Boulder/MCDB-4520/data/human_trios/family1`
- Project: `/mnt/work_1/${USER}/CU_Boulder/MCDB-4520/project`

**Setup:**
```bash
# Auto-detected, just source:
source setup_environment.sh
./wf_trio_analysis.sh --all
```

---

### 🌐 Piel Server
**Auto-detected when:** hostname contains "piel"

**Paths:**
- Data: `/data/human_trios`
- Project: `/scratch/${USER}/trio_project`

**Setup:**
```bash
# On Piel server:
cd /scratch/$USER/trio_project
source setup_environment.sh
./wf_trio_analysis.sh --all -t 32
```

**Important Notes:**
- Data is already on Piel at `/data/human_trios/`
- Use `/scratch/` for your working directory (faster than home)
- Check resource availability with `sinfo` or your scheduler

---

### 💻 Custom/Unknown Environment
**Auto-detected when:** Neither above condition matches

**Paths:**
- Data: `./data/human_trios/family1` (relative to current directory)
- Project: Current working directory

**Setup:**
```bash
# Either source environment file:
source setup_environment.sh

# OR manually export paths:
export TRIO_DATA_DIR=/your/custom/path/to/data
export TRIO_PROJECT_DIR=/your/custom/project/path

# Then run:
./wf_trio_analysis.sh --all
```

---

## Hardcoded Path Issues (Legacy Scripts)

### ✅ Fixed Scripts:
- `wf_trio_analysis.sh` - Uses environment variables + `--data-dir` flag
- `setup_environment.sh` - Auto-detection system

### ⚠️ Legacy Scripts (Avoid for Portability):
These scripts have hardcoded paths and should only be used on ODYSSEUS:

1. **`run_trio_analysis.sh`** - Original v1 script
   - Hardcoded: `/mnt/work_1/` and `/mnt/data_1/`
   - **Use v2 (`wf_trio_analysis.sh`) instead**

2. **`summarize_performance.sh`** 
   - Hardcoded: `/mnt/work_1/gest9386/CU_Boulder/MCDB-4520/project`
   - Fix: Edit line 7 to use `TRIO_PROJECT_DIR` or pass as argument

3. **`download_all_chromosomes.sh`**
   - Hardcoded: `/mnt/data_1/...` and piel remote path
   - Fix: Edit lines 10-11 for your environment

4. **`smoke_test.sh`**
   - Hardcoded: `/mnt/data_1/...` for validation tests
   - Fix: Edit line 21 or set `TRIO_DATA_DIR` before running

---

## Common Workflows

### Running on Piel (From Scratch)
```bash
# 1. Clone/copy project to Piel
ssh username@piel.int.colorado.edu
cd /scratch/$USER
git clone <your-repo-url> trio_project
cd trio_project

# 2. Data is already there!
ls /data/human_trios/

# 3. Setup and run
source setup_environment.sh
./wf_trio_analysis.sh --all -t 32

# 4. Check results
ls HG002_chr1/output/
```

### Running on Your Local Machine
```bash
# 1. First time setup
cd /path/to/your/project
source setup_environment.sh

# 2. If data not detected, download:
./download_all_chromosomes.sh  # or edit paths first!

# 3. Run analysis
./wf_trio_analysis.sh --all -t $(nproc)
```

### Running with Custom Paths
```bash
# Override any detected settings:
export TRIO_DATA_DIR=/my/custom/data/location
export TRIO_PROJECT_DIR=$(pwd)

# Or use flags directly:
./wf_trio_analysis.sh \
    --data-dir /my/custom/data/location \
    --sample HG002 \
    --chromosome chr1 \
    -t 16
```

---

## Validation

### Test Your Environment Setup
```bash
# Check what environment is detected:
source setup_environment.sh

# Should output:
# Detected: [piel/local/custom] environment
# Data directory: /path/to/data
# Project directory: /path/to/project

# Verify data files exist:
ls -lh $TRIO_DATA_DIR/*.bam
ls -lh $TRIO_DATA_DIR/*.fasta
```

### Run Smoke Tests
```bash
# Set environment first:
source setup_environment.sh

# Run tests (edit smoke_test.sh paths if needed):
./smoke_test.sh
```

---

## Troubleshooting

### "Data files not found"
```bash
# Check environment variables:
echo $TRIO_DATA_DIR

# Verify path exists:
ls $TRIO_DATA_DIR

# Override if needed:
export TRIO_DATA_DIR=/correct/path
# OR
./wf_trio_analysis.sh --data-dir /correct/path --all
```

### "Permission denied" on Piel
```bash
# Use scratch space instead of home:
cd /scratch/$USER/trio_project

# Check file permissions:
ls -la $TRIO_DATA_DIR
```

### "Too many threads requested"
```bash
# Check available cores:
nproc

# Use appropriate thread count:
./wf_trio_analysis.sh --all -t 16  # or whatever is reasonable
```

---

## Best Practices

1. **Always source `setup_environment.sh` first**
   ```bash
   source setup_environment.sh
   ```

2. **Use the v2 flexible pipeline** (`wf_trio_analysis.sh`)
   - Has environment variable support
   - Has `--data-dir` flag
   - More portable

3. **Test with dry-run first**
   ```bash
   ./wf_trio_analysis.sh --all --dry-run
   ```

4. **Document your environment in logs**
   ```bash
   source setup_environment.sh > my_run_environment.log
   ./wf_trio_analysis.sh --all 2>&1 | tee -a my_run_environment.log
   ```

5. **For group members: Provide clear instructions**
   - Which server are they using?
   - What paths should they set?
   - Example commands for their specific case

---

## Summary

**✅ For maximum portability, use this workflow:**
```bash
# Step 1: Setup
source setup_environment.sh

# Step 2: Verify
echo "Data: $TRIO_DATA_DIR"
echo "Project: $TRIO_PROJECT_DIR"

# Step 3: Run
./wf_trio_analysis.sh --all -t $(nproc)
```

**❌ Avoid:**
- Using legacy scripts on non-ODYSSEUS systems
- Assuming hardcoded paths will work everywhere
- Forgetting to source `setup_environment.sh`
