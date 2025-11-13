# Family Trio Variant Analysis Pipeline
## MCDB 4520/5520 Computational Genomics Group Project

> **Current Version: v3.0** - Cross-platform portability with auto-detection  
> **Tested on:** ODYSSEUS local server, Piel server  
> **Works anywhere:** Any Linux system with Nextflow installed

---

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [Available Data](#available-data)
- [Output Files](#output-files)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)

---

## Overview

Automated pipeline for **Oxford Nanopore long-read variant analysis** of human family trio data:
- **HG002** (son/proband - male)
- **HG003** (father - male)  
- **HG004** (mother - female)

**What this pipeline does:**
- SNP calling (single nucleotide variants)
- SV calling (structural variants)
- STR calling (short tandem repeats)
- Quality control reports
- Performance logging with detailed time/memory statistics

**Workflow:** [epi2me-labs/wf-human-variation](https://github.com/epi2me-labs/wf-human-variation) (Nextflow)

---

## Quick Start

### For Students Using Piel Server

```bash
# 1. Clone repository
cd /scratch/$USER
git clone https://github.com/gsstephenson/NEXTFLOW_trio-variant-analysis-chr1.git
cd NEXTFLOW_trio-variant-analysis-chr1

# 2. Setup environment (auto-detects Piel)
source setup_environment.sh

# 3. Run analysis (example: HG002 on chr1)
./run_flexible_analysis.sh -s HG002 -c chr1 -o ./my_results

# Data is already on Piel at: /data/human_trios
```

### For Students Using ODYSSEUS or Local Machine

```bash
# 1. Clone repository
git clone https://github.com/gsstephenson/NEXTFLOW_trio-variant-analysis-chr1.git
cd NEXTFLOW_trio-variant-analysis-chr1

# 2. Setup environment (auto-detects your system)
source setup_environment.sh

# 3. If data not available, specify location
./run_flexible_analysis.sh \
    --data-dir /path/to/your/data \
    -s HG002 -c chr1 \
    -o ./my_results
```

### For Custom Environments

See [PORTABILITY_GUIDE.md](PORTABILITY_GUIDE.md) for detailed setup instructions.

---

## Installation

### Prerequisites

1. **Nextflow** (v23.04.0+)
   ```bash
   curl -s https://get.nextflow.io | bash
   sudo mv nextflow /usr/local/bin/
   ```

2. **Singularity or Docker** (for containerized workflow)
   ```bash
   # Check if already installed
   singularity --version
   # or
   docker --version
   ```

3. **GNU Time** (for performance tracking)
   ```bash
   # Usually pre-installed, verify with:
   /usr/bin/time --version
   ```

### Setup

```bash
# Clone this repository
git clone https://github.com/gsstephenson/NEXTFLOW_trio-variant-analysis-chr1.git
cd NEXTFLOW_trio-variant-analysis-chr1

# Make scripts executable
chmod +x *.sh

# Test your setup
./smoke_test.sh
```

---

## Usage Examples

### Basic Analysis

```bash
# Setup environment first (always do this!)
source setup_environment.sh

# Single sample, single chromosome
./run_flexible_analysis.sh -s HG002 -c chr1 -o ./output
```

### Advanced Usage

```bash
# Multiple samples
./run_flexible_analysis.sh -s HG002 -s HG003 -c chr1 -o ./output

# Multiple chromosomes
./run_flexible_analysis.sh -s HG002 -c chr1 -c chr2 -c chr3 -o ./output

# All samples on one chromosome (family trio analysis)
./run_flexible_analysis.sh --all-samples -c chr1 -o ./trio_chr1

# One sample across all available chromosomes
./run_flexible_analysis.sh -s HG002 --all-chromosomes -o ./HG002_genome

# Everything (WARNING: Long runtime!)
./run_flexible_analysis.sh --all -o ./complete_analysis

# Control thread usage
./run_flexible_analysis.sh -s HG002 -c chr1 -o ./output -t 16

# Test before running (dry-run mode)
./run_flexible_analysis.sh --dry-run -s HG002 -c chr1 -o ./output
```

### Get Help

```bash
./run_flexible_analysis.sh --help
```

---

## Available Data

### On Piel Server
**Location:** `/data/human_trios/`

Available samples and chromosomes:
- **Samples:** HG002, HG003, HG004
- **Chromosomes:** chr1, chr2, chr3, chr4, chr6, chr13, chr15, chr17, chr19, chr22
- **Reference:** hg38 (human genome build 38)

### Data Structure
```
/data/human_trios/
├── HG002/              # Son (proband)
│   ├── HG002_chr1.bam
│   ├── HG002_chr1.bam.bai
│   ├── HG002_chr2.bam
│   └── ... (other chromosomes)
├── HG003/              # Father
│   ├── HG003_chr1.bam
│   └── ...
├── HG004/              # Mother
│   ├── HG004_chr1.bam
│   └── ...
└── reference/
    ├── hg38_chr1.fa
    ├── hg38_chr2.fa
    └── ... (other chromosomes)
```

### File Sizes (approximate)
- **BAM files:** 10-14 GB per chromosome
- **Reference FASTA:** 200-300 MB per chromosome
- **Total dataset:** ~300 GB (all samples, all chromosomes)

---

## Output Files

### Directory Structure
After running analysis, you'll get:

```
my_results/
└── HG002_chr1/                       # SAMPLE_CHROMOSOME/
    ├── output/                       # ← Your results here!
    │   ├── HG002_chr1.wf-human-snp-report.html
    │   ├── HG002_chr1.wf-human-sv-report.html
    │   ├── HG002_chr1.wf-human-str-report.html
    │   ├── HG002_chr1.wf_snp.vcf.gz
    │   ├── HG002_chr1.wf_sv.vcf.gz
    │   ├── HG002_chr1.wf_str.vcf.gz
    │   └── ... (more files)
    ├── work/                         # Temporary (auto-cleaned on success)
    └── logs/                         # Performance statistics
        ├── time_stats_TIMESTAMP.txt
        ├── nextflow_TIMESTAMP.log
        ├── nextflow_report_TIMESTAMP.html
        ├── nextflow_timeline_TIMESTAMP.html
        └── nextflow_trace_TIMESTAMP.txt
```

### Key Output Files Explained

| File | Description | Use Case |
|------|-------------|----------|
| `*-snp-report.html` | SNP analysis report | View single nucleotide variants |
| `*-sv-report.html` | Structural variant report | View insertions, deletions, duplications |
| `*-str-report.html` | Short tandem repeat report | View STR expansions |
| `*.wf_snp.vcf.gz` | SNP variants (VCF) | Load into IGV, downstream analysis |
| `*.wf_sv.vcf.gz` | SV variants (VCF) | Load into IGV, downstream analysis |
| `*.wf_str.vcf.gz` | STR variants (VCF) | Load into IGV, downstream analysis |
| `time_stats_*.txt` | Performance metrics | Benchmark system performance |
| `nextflow_timeline_*.html` | Workflow timeline | Visualize pipeline execution |

---

## Documentation

This repository includes comprehensive documentation:

### Core Documentation
- **[README.md](README.md)** (this file) - Quick start and overview
- **[PORTABILITY_GUIDE.md](PORTABILITY_GUIDE.md)** - Cross-platform setup for ODYSSEUS/Piel/custom systems
- **[VERSION.md](VERSION.md)** - Version history and release notes

### Scripts
- **`setup_environment.sh`** - Auto-detects your environment and sets paths
- **`run_flexible_analysis.sh`** - Main pipeline script (v3.0)
- **`smoke_test.sh`** - Validation suite (41 tests)
- **`summarize_performance.sh`** - Extract performance statistics
- **`download_all_chromosomes.sh`** - Bulk data download utility

### Configuration
- **`nextflow.config`** - Nextflow performance tuning

---

## Validation & Testing

### Run Smoke Tests (Recommended)

```bash
./smoke_test.sh
```

**What it tests:**
- ✓ Script help functionality
- ✓ Argument validation
- ✓ Thread configuration
- ✓ Data file availability
- ✓ Environment detection
- ✓ Portability features
- ✓ Dependency checks

**Expected:** `41/41 tests passing`

### Dry-Run Mode

Test your command without running the analysis:

```bash
./run_flexible_analysis.sh --dry-run -s HG002 -c chr1 -o ./test
```

This shows exactly what would be executed without actually running it.

---

## Performance

### Estimated Runtimes
- **Single chromosome, single sample:** 1-4 hours
- **Trio (3 samples), one chromosome:** 3-12 hours
- **All available data:** 50-150+ hours

*Times vary based on:*
- System CPU count (auto-detected)
- Available memory
- Chromosome size
- I/O performance

### Resource Usage
The pipeline auto-tunes based on your system:
- **CPU threads:** Auto-detected via `nproc` (override with `-t` flag)
- **Memory:** Scales with thread count
- **Disk:** ~30-50 GB temporary files per sample (auto-cleaned)

### Monitor Performance

```bash
# After analysis completes
./summarize_performance.sh
```

Shows:
- Wall clock time
- CPU utilization
- Memory usage (peak & average)
- I/O statistics

---

## Project-Specific Info (MCDB 4520/5520)

### Clinically Relevant Genes (Chr1)
According to project directive:
- **DPYD** - Drug metabolism (pharmacogenomics)
- **GBP1** - Immunity and inflammation
- **MTHFR** - Folate metabolism

### Analysis Goals
1. **Identify de novo mutations** - Variants in HG002 not present in HG003 or HG004
2. **Inheritance patterns** - Determine parental origin of variants
3. **Clinical significance** - Focus on genes relevant to disease/drug response

### Trio Analysis Workflow
```bash
# 1. Run all three samples on chr1
./run_flexible_analysis.sh --all-samples -c chr1 -o ./trio_chr1

# 2. Compare VCF files
# - Load HG002_chr1.wf_snp.vcf.gz
# - Load HG003_chr1.wf_snp.vcf.gz
# - Load HG004_chr1.wf_snp.vcf.gz

# 3. Identify de novo variants
# - Present in HG002
# - Absent in both HG003 and HG004
# - Meet quality thresholds

# 4. Focus on clinically relevant genes
# - Filter variants in DPYD, GBP1, MTHFR
```

---

## Troubleshooting

### Common Issues

#### "Data files not found"
```bash
# Check your data directory
ls $TRIO_DATA_DIR

# Override if needed
./run_flexible_analysis.sh --data-dir /correct/path -s HG002 -c chr1 -o ./output
```

#### "Permission denied"
```bash
# Make sure scripts are executable
chmod +x *.sh

# On Piel, use /scratch instead of home directory
cd /scratch/$USER
```

#### "Nextflow not found"
```bash
# Install Nextflow
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# Or add to PATH
export PATH=$PATH:/path/to/nextflow
```

#### Pipeline crashes or fails
```bash
# Check the logs
cat SAMPLE_CHROMOSOME/logs/nextflow_*.log

# Resume from checkpoint (if Nextflow supports)
./run_flexible_analysis.sh --resume -s HG002 -c chr1 -o ./output
```

#### Out of memory errors
```bash
# Use fewer threads
./run_flexible_analysis.sh -s HG002 -c chr1 -o ./output -t 8

# Edit nextflow.config to reduce memory allocation
```

#### Want to test on a different system?
See [PORTABILITY_GUIDE.md](PORTABILITY_GUIDE.md) for detailed cross-platform instructions.

---

## Version History

### v3.0 (2025-11-13) - Current
✨ **Portability Release**
- Multi-environment support (ODYSSEUS, Piel, custom)
- Auto-detection via `setup_environment.sh`
- Environment variable support (`TRIO_DATA_DIR`, `TRIO_PROJECT_DIR`)
- 41 smoke tests (6 new portability tests)
- Comprehensive documentation for any group

### v2.0 (2025-11-11)
⚡ **Flexible Pipeline**
- Parameterized sample/chromosome selection
- Thread configuration via `-t` flag
- Dry-run mode
- Batch processing with `--all` flags
- 35 smoke tests

### v1.0 (2025-11-10)
🎯 **Initial Release**
- Chr1 trio analysis (hardcoded)
- Performance logging
- Basic automation

---

## FAQ

**Q: Which version should I use?**  
A: Use v3.0 (`run_flexible_analysis.sh`) - it's the most flexible and portable.

**Q: Can I run this on my laptop?**  
A: Yes, if you have Nextflow and the data files. Use `setup_environment.sh` and specify your data location.

**Q: How long does it take?**  
A: 1-4 hours per sample per chromosome, depending on your system.

**Q: Do I need to download the data?**  
A: If using Piel server, data is already at `/data/human_trios/`. Otherwise, yes.

**Q: Can I analyze just one gene?**  
A: The pipeline analyzes entire chromosomes. Filter VCF outputs afterwards for specific genes.

**Q: What if I want a different chromosome?**  
A: Use `-c chr2` (or any available chromosome). See available data with `ls $TRIO_DATA_DIR/HG002/`.

**Q: Can multiple people run this simultaneously?**  
A: Yes! Just use different output directories (`-o`).

**Q: How do I cite this pipeline?**  
A: Cite the epi2me-labs/wf-human-variation workflow and include this GitHub repository.

---

## Contributing

Found a bug or have a suggestion? 
- Open an issue on GitHub
- Fork and submit a pull request
- Contact the course instructors

---

## License

This pipeline setup is for educational use in MCDB 4520/5520. The underlying `wf-human-variation` workflow has its own license (check the [epi2me-labs repository](https://github.com/epi2me-labs/wf-human-variation)).

---

## Acknowledgments

- **Data:** Genome in a Bottle Consortium (GIAB)
- **Workflow:** Oxford Nanopore Technologies (epi2me-labs)
- **Course:** MCDB 4520/5520 Computational Genomics, CU Boulder
- **Infrastructure:** Piel server, ODYSSEUS server

---

## Repository

**GitHub:** [gsstephenson/NEXTFLOW_trio-variant-analysis-chr1](https://github.com/gsstephenson/NEXTFLOW_trio-variant-analysis-chr1)

**Quick Clone:**
```bash
git clone https://github.com/gsstephenson/NEXTFLOW_trio-variant-analysis-chr1.git
```
