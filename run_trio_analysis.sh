#!/bin/bash
#############################################################################
# Automated Family Trio Analysis Pipeline for Chromosome 1
# MCDB 4520 - Computational Genomics Group Project
# 
# This script runs wf-human-variation on all three family members:
# - HG002 (son, male)
# - HG003 (father, male)
# - HG004 (mother, female)
#
# Features:
# - Automated sequential execution
# - Comprehensive time logging with GNU time
# - Maximum CPU/memory utilization
# - Clear output directory structure
# - Error handling and logging
#############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project directories
PROJECT_DIR="/mnt/work_1/gest9386/CU_Boulder/MCDB-4520/project"
DATA_DIR="/mnt/data_1/CU_Boulder/MCDB-4520/data/human_trios"
REF_GENOME="${DATA_DIR}/reference/hg38_chr1.fa"

# Timestamp for this run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MASTER_LOG="${PROJECT_DIR}/pipeline_master_${TIMESTAMP}.log"

# Function to print colored messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${MASTER_LOG}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${MASTER_LOG}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${MASTER_LOG}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${MASTER_LOG}"
}

# Function to run analysis for one family member
run_analysis() {
    local SAMPLE_NAME=$1
    local SEX=$2
    local BAM_FILE="${DATA_DIR}/${SAMPLE_NAME}/${SAMPLE_NAME}_chr1.bam"
    local OUTPUT_DIR="${PROJECT_DIR}/${SAMPLE_NAME}_chr1/output"
    local WORK_DIR="${PROJECT_DIR}/${SAMPLE_NAME}_chr1/work"
    local LOG_DIR="${PROJECT_DIR}/${SAMPLE_NAME}_chr1/logs"
    local TIME_LOG="${LOG_DIR}/time_stats_${TIMESTAMP}.txt"
    local NF_LOG="${LOG_DIR}/nextflow_${TIMESTAMP}.log"
    
    log_info "=========================================="
    log_info "Starting analysis for ${SAMPLE_NAME}"
    log_info "=========================================="
    log_info "BAM File: ${BAM_FILE}"
    log_info "Reference: ${REF_GENOME}"
    log_info "Output Dir: ${OUTPUT_DIR}"
    log_info "Work Dir: ${WORK_DIR}"
    log_info "Sex: ${SEX}"
    
    # Verify input files exist
    if [ ! -f "${BAM_FILE}" ]; then
        log_error "BAM file not found: ${BAM_FILE}"
        return 1
    fi
    
    if [ ! -f "${BAM_FILE}.bai" ]; then
        log_error "BAM index file not found: ${BAM_FILE}.bai"
        return 1
    fi
    
    if [ ! -f "${REF_GENOME}" ]; then
        log_error "Reference genome not found: ${REF_GENOME}"
        return 1
    fi
    
    # Create output directories
    mkdir -p "${OUTPUT_DIR}" "${WORK_DIR}" "${LOG_DIR}"
    
    # Run nextflow with time tracking
    log_info "Launching Nextflow workflow..."
    
    /usr/bin/time -v -o "${TIME_LOG}" \
        nextflow run epi2me-labs/wf-human-variation \
        -c "${PROJECT_DIR}/nextflow.config" \
        --bam "${BAM_FILE}" \
        --ref "${REF_GENOME}" \
        --override_basecaller_cfg dna_r10.4.1_e8.2_400bps_sup@v5.0.0 \
        --sample_name "${SAMPLE_NAME}_chr1" \
        --snp \
        --sv \
        --str \
        --sex "${SEX}" \
        --bam_min_coverage 0 \
        --annotation true \
        --out_dir "${OUTPUT_DIR}" \
        -w "${WORK_DIR}" \
        -with-report "${LOG_DIR}/nextflow_report_${TIMESTAMP}.html" \
        -with-timeline "${LOG_DIR}/nextflow_timeline_${TIMESTAMP}.html" \
        -with-trace "${LOG_DIR}/nextflow_trace_${TIMESTAMP}.txt" \
        -with-dag "${LOG_DIR}/nextflow_dag_${TIMESTAMP}.html" \
        2>&1 | tee "${NF_LOG}"
    
    local EXIT_CODE=${PIPESTATUS[0]}
    
    if [ ${EXIT_CODE} -eq 0 ]; then
        log_success "Analysis completed successfully for ${SAMPLE_NAME}"
        
        # Display time statistics
        log_info "Time statistics for ${SAMPLE_NAME}:"
        echo "----------------------------------------" | tee -a "${MASTER_LOG}"
        grep -E "(Elapsed|Maximum resident|Percent of CPU)" "${TIME_LOG}" | tee -a "${MASTER_LOG}"
        echo "----------------------------------------" | tee -a "${MASTER_LOG}"
        
        # Clean up work directory to save space
        log_info "Cleaning up work directory..."
        rm -rf "${WORK_DIR}"
        log_success "Work directory cleaned: ${WORK_DIR}"
    else
        log_error "Analysis failed for ${SAMPLE_NAME} with exit code ${EXIT_CODE}"
        log_warning "Work directory preserved for debugging: ${WORK_DIR}"
        return ${EXIT_CODE}
    fi
    
    log_info "Output files saved to: ${OUTPUT_DIR}"
    log_info "Log files saved to: ${LOG_DIR}"
    log_info ""
    
    return 0
}

# Main execution
main() {
    log_info "=========================================="
    log_info "MCDB 4520 - Family Trio Analysis Pipeline"
    log_info "Chromosome 1 - Oxford Nanopore Data"
    log_info "=========================================="
    log_info "Project Directory: ${PROJECT_DIR}"
    log_info "Data Directory: ${DATA_DIR}"
    log_info "Reference Genome: ${REF_GENOME}"
    log_info "Master Log: ${MASTER_LOG}"
    log_info "Timestamp: ${TIMESTAMP}"
    log_info ""
    
    # Check if nextflow is installed
    if ! command -v nextflow &> /dev/null; then
        log_error "Nextflow is not installed or not in PATH"
        exit 1
    fi
    
    log_info "Nextflow version: $(nextflow -version | head -1)"
    log_info "Available CPU cores: $(nproc)"
    log_info "Total memory: $(free -h | awk '/^Mem:/ {print $2}')"
    log_info ""
    
    # Start timer for entire pipeline
    PIPELINE_START=$(date +%s)
    
    # Run analysis for each family member
    # HG002 - Son (male, child)
    if run_analysis "HG002" "XY"; then
        log_success "HG002 (son) analysis completed"
    else
        log_error "HG002 (son) analysis failed"
        exit 1
    fi
    
    # HG003 - Father (male)
    if run_analysis "HG003" "XY"; then
        log_success "HG003 (father) analysis completed"
    else
        log_error "HG003 (father) analysis failed"
        exit 1
    fi
    
    # HG004 - Mother (female)
    if run_analysis "HG004" "XX"; then
        log_success "HG004 (mother) analysis completed"
    else
        log_error "HG004 (mother) analysis failed"
        exit 1
    fi
    
    # Calculate total pipeline runtime
    PIPELINE_END=$(date +%s)
    PIPELINE_DURATION=$((PIPELINE_END - PIPELINE_START))
    HOURS=$((PIPELINE_DURATION / 3600))
    MINUTES=$(((PIPELINE_DURATION % 3600) / 60))
    SECONDS=$((PIPELINE_DURATION % 60))
    
    log_info ""
    log_info "=========================================="
    log_success "ALL ANALYSES COMPLETED SUCCESSFULLY!"
    log_info "=========================================="
    log_info "Total pipeline runtime: ${HOURS}h ${MINUTES}m ${SECONDS}s"
    log_info ""
    log_info "Output locations:"
    log_info "  HG002 (son):    ${PROJECT_DIR}/HG002_chr1/output/"
    log_info "  HG003 (father): ${PROJECT_DIR}/HG003_chr1/output/"
    log_info "  HG004 (mother): ${PROJECT_DIR}/HG004_chr1/output/"
    log_info ""
    log_info "Master log: ${MASTER_LOG}"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Review HTML reports in each output directory"
    log_info "  2. Examine VCF files for variant calling results"
    log_info "  3. Compare variants across family members"
    log_info "  4. Identify de novo mutations in HG002 (child)"
    log_info "=========================================="
}

# Run main function
main

exit 0
