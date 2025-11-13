# Version 4.1 - Odysseus Scratch Directory Fix

**Release Date:** November 13, 2025

## Bug Fixes

### Fixed Apptainer Temporary Directory Issue on Odysseus
- **Problem**: Script attempted to use `/scratch` directory which doesn't exist on Odysseus
- **Solution**: Environment-specific scratch directory detection:
  - **Piel server**: Uses `/scratch/${USER}` (as before)
  - **Odysseus**: Uses `/mnt/work_1/${USER}/CU_Boulder/MCDB-4520`
  - **Custom**: Uses `$(pwd)/tmp` as fallback
- **Impact**: Eliminates "no such file or directory" errors during container image pulls on Odysseus
- **New Feature**: Added `TRIO_SCRATCH_DIR` environment variable for manual override

### Technical Details
- `setup_environment.sh` now exports `TRIO_SCRATCH_DIR` for each environment
- `wf_trio_analysis.sh` uses `${SCRATCH_DIR}` instead of hardcoded `/scratch` paths
- Container temporary directories now created in environment-appropriate locations
- Maintains full backward compatibility with Piel server setup

---

# Version 4.0 - Production-Ready Cross-Platform Release

**Release Date:** November 13, 2025

---

# Version 3.0 - Portability Release

**Release Date:** November 12, 2025

## New Features

### Environment Auto-Detection
- Added `setup_environment.sh` for automatic environment detection
- Detects ODYSSEUS, Piel server, or custom environments
- Sets `TRIO_DATA_DIR` and `TRIO_PROJECT_DIR` automatically

### Cross-Platform Support
- Pipeline now works seamlessly on:
  - ODYSSEUS (local server with `/mnt/data_1/` paths)
  - Piel server (`/data/human_trios/` paths)
  - Custom environments (user-defined paths)

### Enhanced Configuration
- `wf_trio_analysis.sh` now respects `TRIO_DATA_DIR` environment variable
- Maintains backward compatibility with hardcoded defaults
- `--data-dir` flag still overrides all other settings

### Comprehensive Documentation
- Added `PORTABILITY_GUIDE.md` with:
  - Environment-specific setup instructions
  - Troubleshooting guide
  - Best practices for different systems
  - Migration guide for legacy scripts

### Improved Testing
- Added 6 new portability smoke tests (41 total)
- Tests for environment variable handling
- Tests for flag override behavior
- Tests for auto-detection functionality

## Breaking Changes
None - fully backward compatible with v2.0

## Migration from v2.0
No changes required! Existing workflows continue to work.

To use new portability features:
```bash
source setup_environment.sh
./wf_trio_analysis.sh --all
```

## Version History

### v4.1 (2025-11-13) - Odysseus Scratch Directory Fix
- **Fixed**: Apptainer failing due to missing `/scratch` directory on Odysseus
- **Environment-Specific Scratch Paths**: Auto-detects correct temp directory per server
- **New Variable**: `TRIO_SCRATCH_DIR` for manual scratch directory override
- **Tested**: Verified on both Piel (singularity + /scratch) and Odysseus (apptainer + /mnt/work_1)

### v4.0 (2025-11-13) - Production-Ready Cross-Platform Release
- **Automatic Container Engine Detection**: Auto-detects and uses `singularity` on Piel, `apptainer` on Odysseus
- **Intelligent Path Resolution**: Automatically selects correct data paths based on server environment
- **Dynamic Temporary Storage Management**: 
  - Uses `/scratch` for container tmp (2.3T available vs 490M in `/tmp`)
  - Automatic cleanup of container build files after completion
  - Prevents disk space crashes during large container pulls
- **Enhanced Error Handling**: Fixed arithmetic expansion bug causing silent failures
- **Optimized Storage**: Auto-cleanup of old Nextflow cache (retains last 7 days)
- **Production Ready**: Fully tested on both Piel (singularity) and Odysseus (apptainer)
- **Zero Configuration**: Works out-of-the-box on both servers without manual setup

### v3.0 (2025-11-12) - Portability Release
- Multi-environment support
- Auto-detection system
- Enhanced documentation
- 41 passing smoke tests

### v2.0 (2025-11-11) - Flexible Pipeline
- Parameterized sample/chromosome selection
- Thread configuration via -t flag
- Dry-run mode
- 35 passing smoke tests

### v1.0 (2025-11-10) - Initial Release
- Hardcoded chr1 trio analysis
- Basic automation
- Performance logging
