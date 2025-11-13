# Odysseus Scratch Directory Fix - v4.1

## Problem
When running on Odysseus, the pipeline failed with this error:
```
FATAL: While making image from oci registry: error fetching image to cache: 
while building SIF from layers: unable to create new build: 
failed to create build parent dir: stat /scratch/gest9386/.apptainer_tmp_20251113_111748: 
no such file or directory
```

**Root Cause**: The script was hardcoded to use `/scratch/${USER}` for temporary container files, but this directory doesn't exist on Odysseus.

## Solution
Implemented environment-specific scratch directory detection:

### Changes Made

#### 1. `setup_environment.sh`
- Added `TRIO_SCRATCH_DIR` environment variable
- **Piel**: `export TRIO_SCRATCH_DIR="/scratch/${USER}"`
- **Odysseus**: `export TRIO_SCRATCH_DIR="/mnt/work_1/${USER}/CU_Boulder/MCDB-4520"`
- **Custom**: `export TRIO_SCRATCH_DIR="$(pwd)/tmp"`

#### 2. `wf_trio_analysis.sh`
- Added `DEFAULT_SCRATCH_DIR` detection based on hostname
- Replaced hardcoded `/scratch/${USER}` paths with `${SCRATCH_DIR}` variable
- Updated both Apptainer and Singularity tmp directory creation
- Added scratch directory to log output for debugging

### Environment Detection Logic

```bash
# Piel Server (has /scratch)
if [[ $(hostname) == *"piel"* ]]; then
    DEFAULT_SCRATCH_DIR="/scratch/${USER}"
    
# Odysseus (uses /mnt/work_1)
else
    DEFAULT_SCRATCH_DIR="/mnt/work_1/${USER}/CU_Boulder/MCDB-4520"
fi

# Allow override via environment variable
SCRATCH_DIR="${TRIO_SCRATCH_DIR:-${DEFAULT_SCRATCH_DIR}}"
```

### Container Temp Directory Usage

```bash
# Apptainer (Odysseus)
export APPTAINER_TMPDIR="${SCRATCH_DIR}/.apptainer_tmp_${timestamp}"

# Singularity (Piel)
export SINGULARITY_TMPDIR="${SCRATCH_DIR}/.singularity_tmp_${timestamp}"
```

## Testing

### Verify Environment Detection
```bash
cd /mnt/work_1/gest9386/CU_Boulder/MCDB-4520/wf-trio-variant-pipeline
source setup_environment.sh

# Should show:
# Detected: Local server environment (Odysseus)
# Scratch directory: /mnt/work_1/gest9386/CU_Boulder/MCDB-4520
```

### Test Dry Run
```bash
./wf_trio_analysis.sh -s HG004 -c chr1 -o ../project --dry-run

# Should show:
# [INFO] Scratch directory: /mnt/work_1/gest9386/CU_Boulder/MCDB-4520
```

### Run Actual Analysis
```bash
source setup_environment.sh
./wf_trio_analysis.sh -s HG004 -c chr1 -o ../project
```

## Manual Override (if needed)

If the auto-detection doesn't work for your setup:

```bash
export TRIO_SCRATCH_DIR="/your/custom/scratch/path"
./wf_trio_analysis.sh -s HG004 -c chr1 -o ../project
```

## Compatibility

- ✅ **Piel Server**: Works with Singularity + `/scratch` (as before)
- ✅ **Odysseus**: Works with Apptainer + `/mnt/work_1` (now fixed)
- ✅ **Custom Environments**: Falls back to `$(pwd)/tmp`
- ✅ **Backward Compatible**: No changes needed for existing Piel workflows

## Files Modified

1. `setup_environment.sh` - Added `TRIO_SCRATCH_DIR` export
2. `wf_trio_analysis.sh` - Dynamic scratch directory detection
3. `VERSION.md` - Documented v4.1 release

## Next Steps

1. Test on Odysseus: `./wf_trio_analysis.sh -s HG004 -c chr1 -o ../project`
2. Verify on Piel (if accessible) to ensure backward compatibility
3. Monitor `.apptainer_tmp_*` cleanup in scratch directory after runs
