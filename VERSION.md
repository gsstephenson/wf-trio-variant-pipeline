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
