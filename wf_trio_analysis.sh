#!/bin/bash
#############################################################################
# Flexible Family Trio Variant Analysis Pipeline v3.0
# MCDB 4520 - Computational Genomics Group Project
# 
# A parameterized pipeline for running wf-human-variation on any combination
# of family members and chromosomes.
#
# Usage: ./wf_trio_analysis.sh [OPTIONS]
#
# Version: 3.0 (Portability Release)
# Author: gsstephenson
# Repository: wf-trio-variant-pipeline
#############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
# If TRIO_DATA_DIR is set (e.g., from setup_environment.sh), use it
DATA_DIR="${TRIO_DATA_DIR:-/mnt/data_1/CU_Boulder/MCDB-4520/data/human_trios/family1}"
CONFIG_FILE=""
SAMPLES=()
CHROMOSOMES=()
OUTPUT_BASE=""
MAX_THREADS=$(nproc)  # Auto-detect by default
RUN_ALL_SAMPLES=false
RUN_ALL_CHROMOSOMES=false
MAX_THREADS=$(nproc)  # Auto-detect available CPUs
DRY_RUN=false
RESUME=false

# All available samples and chromosomes
ALL_SAMPLES=("HG002" "HG003" "HG004")
ALL_CHROMOSOMES=("chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" \
                 "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" \
                 "chr21" "chr22" "chrX" "chrY")

# Sample sex mapping
declare -A SAMPLE_SEX
SAMPLE_SEX["HG002"]="XY"  # Son
SAMPLE_SEX["HG003"]="XY"  # Father
SAMPLE_SEX["HG004"]="XX"  # Mother

#############################################################################
# Help Function
#############################################################################
show_help() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  Flexible Family Trio Variant Analysis Pipeline v3.0${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    cat << 'EOF'
USAGE:
    wf_trio_analysis.sh [OPTIONS]

REQUIRED OPTIONS:
    -o, --output DIR
        Output base directory (will create organized structure inside)

    -s, --sample SAMPLE
        Sample to analyze: HG002 (son), HG003 (father), or HG004 (mother)
        Can be specified multiple times: -s HG002 -s HG003
        
    -c, --chromosome CHR
        Chromosome to analyze: chr1, chr2, ..., chr22, chrX, chrY
        Can be specified multiple times: -c chr1 -c chr2

OPTIONAL FLAGS:
    --all-samples
        Run analysis on all three family members (HG002, HG003, HG004)
        
    --all-chromosomes
        Run analysis on all chromosomes (chr1-22, X, Y)
        
    --all
        Run complete analysis: all samples × all chromosomes
        
    --config FILE
        Path to custom nextflow.config (default: auto-detected)
        
    --data-dir DIR
        Data directory containing BAM files
        
    -t, --threads NUM
        Maximum number of CPU threads to use (default: auto-detect)
        
    --dry-run
        Show what would be executed without running analysis
        
    --resume
        Resume failed/interrupted analysis from last checkpoint
        
    -h, --help
        Show this help message and exit

EXAMPLES:
    # Analyze HG002 on chromosome 1
    ./wf_trio_analysis.sh -s HG002 -c chr1 -o /path/to/output

    # Analyze all three family members on chromosome 17
    ./wf_trio_analysis.sh --all-samples -c chr17 -o /path/to/output

    # Analyze HG002 on multiple chromosomes
    ./wf_trio_analysis.sh -s HG002 -c chr1 -c chr13 -c chr17 -o /path/to/output

    # Analyze two samples on chromosome 1
    ./wf_trio_analysis.sh -s HG002 -s HG003 -c chr1 -o /path/to/output

    # Run complete trio analysis on all chromosomes
    ./wf_trio_analysis.sh --all -o /path/to/output

    # Analyze father on all chromosomes
    ./wf_trio_analysis.sh -s HG003 --all-chromosomes -o /path/to/output

    # Limit to 8 threads (for smaller machines)
    ./wf_trio_analysis.sh -s HG002 -c chr1 -o /path/to/output -t 8

    # Use maximum threads (auto-detected if -t not specified)
    ./wf_trio_analysis.sh -s HG002 -c chr1 -o /path/to/output -t 32

    # Use specific thread count for smaller machine
    ./wf_trio_analysis.sh -s HG002 -c chr1 -o /path/to/output -t 8

OUTPUT STRUCTURE:
    OUTPUT_DIR/
    ├── SAMPLE_CHR/
    │   ├── output/          # Analysis results (VCF, reports)
    │   ├── work/            # Nextflow work (auto-cleaned on success)
    │   └── logs/            # Execution logs and time statistics
    ├── pipeline_master_TIMESTAMP.log
    └── analysis_summary.txt

SAMPLE INFO:
    HG002  -  Son (male, child)        -  Sex: XY
    HG003  -  Father (male)            -  Sex: XY
    HG004  -  Mother (female)          -  Sex: XX

REQUIREMENTS:
    - Nextflow installed and in PATH
    - BAM files in: DATA_DIR/SAMPLE/SAMPLE_CHR.bam
    - Reference genome in: DATA_DIR/reference/hg38_CHR.fa
    - nextflow.config in script directory or specified with --config

EOF
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
}

#############################################################################
# Logging Functions
#############################################################################
MASTER_LOG=""

log_info() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${msg}"
    [ -n "${MASTER_LOG}" ] && echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - ${msg}" >> "${MASTER_LOG}"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${msg}"
    [ -n "${MASTER_LOG}" ] && echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - ${msg}" >> "${MASTER_LOG}"
}

log_warning() {
    local msg="$1"
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${msg}"
    [ -n "${MASTER_LOG}" ] && echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - ${msg}" >> "${MASTER_LOG}"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - ${msg}"
    [ -n "${MASTER_LOG}" ] && echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - ${msg}" >> "${MASTER_LOG}"
}

#############################################################################
# Parse Command Line Arguments
#############################################################################
parse_args() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                OUTPUT_BASE="$2"
                shift 2
                ;;
            -s|--sample)
                SAMPLES+=("$2")
                shift 2
                ;;
            -c|--chromosome)
                CHROMOSOMES+=("$2")
                shift 2
                ;;
            --all-samples)
                RUN_ALL_SAMPLES=true
                shift
                ;;
            --all-chromosomes)
                RUN_ALL_CHROMOSOMES=true
                shift
                ;;
            --all)
                RUN_ALL_SAMPLES=true
                RUN_ALL_CHROMOSOMES=true
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --data-dir)
                DATA_DIR="$2"
                shift 2
                ;;
            -t|--threads)
                MAX_THREADS="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --resume)
                RESUME=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [ -z "${OUTPUT_BASE}" ]; then
        log_error "Output directory is required. Use -o or --output"
        exit 1
    fi

    # Handle --all-samples flag
    if [ "${RUN_ALL_SAMPLES}" = true ]; then
        SAMPLES=("${ALL_SAMPLES[@]}")
    fi

    # Handle --all-chromosomes flag
    if [ "${RUN_ALL_CHROMOSOMES}" = true ]; then
        CHROMOSOMES=("${ALL_CHROMOSOMES[@]}")
    fi

    # Validate samples and chromosomes are provided
    if [ ${#SAMPLES[@]} -eq 0 ]; then
        log_error "At least one sample must be specified. Use -s, --all-samples, or --all"
        exit 1
    fi

    if [ ${#CHROMOSOMES[@]} -eq 0 ]; then
        log_error "At least one chromosome must be specified. Use -c, --all-chromosomes, or --all"
        exit 1
    fi

    # Validate sample names
    for sample in "${SAMPLES[@]}"; do
        if [[ ! " ${ALL_SAMPLES[@]} " =~ " ${sample} " ]]; then
            log_error "Invalid sample: ${sample}. Must be one of: ${ALL_SAMPLES[*]}"
            exit 1
        fi
    done

    # Validate chromosome names
    for chr in "${CHROMOSOMES[@]}"; do
        if [[ ! " ${ALL_CHROMOSOMES[@]} " =~ " ${chr} " ]]; then
            log_error "Invalid chromosome: ${chr}. Must be one of: ${ALL_CHROMOSOMES[*]}"
            exit 1
        fi
    done
    
    # Validate thread count
    if ! [[ "${MAX_THREADS}" =~ ^[0-9]+$ ]] || [ "${MAX_THREADS}" -lt 1 ]; then
        log_error "Invalid thread count: ${MAX_THREADS}. Must be a positive integer."
        exit 1
    fi
    
    local available_cpus=$(nproc)
    if [ "${MAX_THREADS}" -gt "${available_cpus}" ]; then
        log_warning "Requested ${MAX_THREADS} threads but only ${available_cpus} available. Using ${available_cpus}."
        MAX_THREADS="${available_cpus}"
    fi
}

#############################################################################
# Setup Function
#############################################################################
setup_environment() {
    # Create output base directory
    mkdir -p "${OUTPUT_BASE}"
    OUTPUT_BASE=$(realpath "${OUTPUT_BASE}")
    
    # Setup master log
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    MASTER_LOG="${OUTPUT_BASE}/pipeline_master_${timestamp}.log"
    
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Flexible Trio Analysis Pipeline v3.0"
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Output directory: ${OUTPUT_BASE}"
    log_info "Data directory: ${DATA_DIR}"
    log_info "Samples: ${SAMPLES[*]}"
    log_info "Chromosomes: ${CHROMOSOMES[*]}"
    log_info "Max threads: ${MAX_THREADS}"
    log_info "Dry run: ${DRY_RUN}"
    log_info "Resume mode: ${RESUME}"
    log_info "Total analyses to run: $((${#SAMPLES[@]} * ${#CHROMOSOMES[@]}))"
    log_info ""
    
    # Dry run mode - just show what would be executed
    if [ "${DRY_RUN}" = true ]; then
        log_info "DRY RUN MODE - No analyses will be executed"
        log_info ""
        for sample in "${SAMPLES[@]}"; do
            for chr in "${CHROMOSOMES[@]}"; do
                log_info "Would run: ${sample} ${chr}"
                log_info "  Input: ${DATA_DIR}/${sample}/${sample}_${chr}.bam"
                log_info "  Output: ${OUTPUT_BASE}/${sample}_${chr}/output/"
            done
        done
        log_info ""
        log_info "DRY RUN COMPLETE - Use without --dry-run to execute"
        exit 0
    fi
    
    # Find or validate config file
    if [ -z "${CONFIG_FILE}" ]; then
        # Try to find config in script directory
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "${script_dir}/nextflow.config" ]; then
            CONFIG_FILE="${script_dir}/nextflow.config"
            log_info "Using config file: ${CONFIG_FILE}"
        else
            log_warning "No nextflow.config found. Using Nextflow defaults."
        fi
    else
        if [ ! -f "${CONFIG_FILE}" ]; then
            log_error "Config file not found: ${CONFIG_FILE}"
            exit 1
        fi
        log_info "Using config file: ${CONFIG_FILE}"
    fi
    
    # Check nextflow installation
    if ! command -v nextflow &> /dev/null; then
        log_error "Nextflow is not installed or not in PATH"
        exit 1
    fi
    
    log_info "Nextflow version: $(nextflow -version 2>&1 | head -1)"
    log_info "Available CPU cores: $(nproc)"
    log_info "Total memory: $(free -h | awk '/^Mem:/ {print $2}')"
    log_info ""
}

#############################################################################
# Run Analysis Function
#############################################################################
run_analysis() {
    local sample=$1
    local chromosome=$2
    local sex="${SAMPLE_SEX[$sample]}"
    
    local bam_file="${DATA_DIR}/${sample}/${sample}_${chromosome}.bam"
    local ref_genome="$(dirname ${DATA_DIR})/reference/hg38_${chromosome}.fa"
    
    local analysis_dir="${OUTPUT_BASE}/${sample}_${chromosome}"
    local output_dir="${analysis_dir}/output"
    local work_dir="${analysis_dir}/work"
    local log_dir="${analysis_dir}/logs"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local time_log="${log_dir}/time_stats_${timestamp}.txt"
    local nf_log="${log_dir}/nextflow_${timestamp}.log"
    
    log_info "══════════════════════════════════════════════════════════"
    log_info "Starting: ${sample} ${chromosome}"
    log_info "══════════════════════════════════════════════════════════"
    log_info "BAM: ${bam_file}"
    log_info "Reference: ${ref_genome}"
    log_info "Sex: ${sex}"
    log_info "Output: ${output_dir}"
    
    # Verify input files
    if [ ! -f "${bam_file}" ]; then
        log_error "BAM file not found: ${bam_file}"
        return 1
    fi
    
    if [ ! -f "${bam_file}.bai" ]; then
        log_error "BAM index not found: ${bam_file}.bai"
        return 1
    fi
    
    if [ ! -f "${ref_genome}" ]; then
        log_error "Reference genome not found: ${ref_genome}"
        return 1
    fi
    
    # Create directories
    mkdir -p "${output_dir}" "${work_dir}" "${log_dir}"
    
    # Build nextflow command
    local nf_cmd="nextflow run epi2me-labs/wf-human-variation"
    
    if [ -n "${CONFIG_FILE}" ]; then
        nf_cmd="${nf_cmd} -c ${CONFIG_FILE}"
    fi
    
    # Add resume flag if enabled
    if [ "${RESUME}" = true ]; then
        nf_cmd="${nf_cmd} -resume"
    fi
    
    nf_cmd="${nf_cmd} \
        --bam ${bam_file} \
        --ref ${ref_genome} \
        --override_basecaller_cfg dna_r10.4.1_e8.2_400bps_sup@v5.0.0 \
        --sample_name ${sample}_${chromosome} \
        --snp \
        --sv \
        --str \
        --sex ${sex} \
        --bam_min_coverage 0 \
        --annotation true \
        --out_dir ${output_dir} \
        --threads ${MAX_THREADS} \
        -w ${work_dir} \
        -with-report ${log_dir}/nextflow_report_${timestamp}.html \
        -with-timeline ${log_dir}/nextflow_timeline_${timestamp}.html \
        -with-trace ${log_dir}/nextflow_trace_${timestamp}.txt \
        -with-dag ${log_dir}/nextflow_dag_${timestamp}.html"
    
    # Run with time tracking
    log_info "Launching Nextflow workflow..."
    
    if /usr/bin/time -v -o "${time_log}" bash -c "${nf_cmd}" 2>&1 | tee "${nf_log}"; then
        log_success "Analysis completed: ${sample} ${chromosome}"
        
        # Display time stats
        log_info "Time statistics:"
        grep -E "(Elapsed|Maximum resident|Percent of CPU)" "${time_log}" | while read line; do
            log_info "  ${line}"
        done
        
        # Clean up work directory
        log_info "Cleaning work directory..."
        rm -rf "${work_dir}"
        
        return 0
    else
        log_error "Analysis failed: ${sample} ${chromosome}"
        log_warning "Work directory preserved: ${work_dir}"
        return 1
    fi
}

#############################################################################
# Generate Summary
#############################################################################
generate_summary() {
    local summary_file="${OUTPUT_BASE}/analysis_summary.txt"
    
    cat > "${summary_file}" << EOF
═══════════════════════════════════════════════════════════
Flexible Trio Analysis Pipeline v3.0 - Summary
═══════════════════════════════════════════════════════════

Run Date: $(date '+%Y-%m-%d %H:%M:%S')
Output Directory: ${OUTPUT_BASE}

Samples Analyzed: ${SAMPLES[*]}
Chromosomes Analyzed: ${CHROMOSOMES[*]}
Total Analyses: $((${#SAMPLES[@]} * ${#CHROMOSOMES[@]}))

Output Structure:
EOF

    for sample in "${SAMPLES[@]}"; do
        for chr in "${CHROMOSOMES[@]}"; do
            if [ -d "${OUTPUT_BASE}/${sample}_${chr}/output" ]; then
                echo "  ✓ ${sample}_${chr}/output/" >> "${summary_file}"
            fi
        done
    done
    
    cat >> "${summary_file}" << EOF

Reports and logs saved in each analysis subdirectory.
Master log: ${MASTER_LOG}

═══════════════════════════════════════════════════════════
EOF

    cat "${summary_file}"
}

#############################################################################
# Main Execution
#############################################################################
main() {
    parse_args "$@"
    setup_environment
    
    local total_analyses=$((${#SAMPLES[@]} * ${#CHROMOSOMES[@]}))
    local current=0
    local failed=0
    
    local pipeline_start=$(date +%s)
    
    # Run all sample-chromosome combinations
    for sample in "${SAMPLES[@]}"; do
        for chr in "${CHROMOSOMES[@]}"; do
            ((current++))
            log_info ""
            log_info "Progress: ${current}/${total_analyses}"
            
            if ! run_analysis "${sample}" "${chr}"; then
                ((failed++))
                log_error "Failed: ${sample} ${chr}"
            fi
        done
    done
    
    # Calculate runtime
    local pipeline_end=$(date +%s)
    local duration=$((pipeline_end - pipeline_start))
    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))
    
    log_info ""
    log_info "═══════════════════════════════════════════════════════════"
    
    if [ ${failed} -eq 0 ]; then
        log_success "ALL ANALYSES COMPLETED SUCCESSFULLY!"
    else
        log_warning "${failed}/${total_analyses} analyses failed"
    fi
    
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Total runtime: ${hours}h ${minutes}m ${seconds}s"
    log_info ""
    
    generate_summary
    
    exit ${failed}
}

# Run main
main "$@"
