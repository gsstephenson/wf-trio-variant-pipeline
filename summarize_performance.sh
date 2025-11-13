#!/bin/bash
#############################################################################
# Performance Summary Report Generator
# Extracts and displays time statistics from all three analyses
#############################################################################

PROJECT_DIR="/mnt/work_1/gest9386/CU_Boulder/MCDB-4520/project"

echo "=========================================="
echo "TRIO ANALYSIS PERFORMANCE SUMMARY"
echo "=========================================="
echo ""

# Function to extract time stats
extract_stats() {
    local SAMPLE=$1
    local LOG_DIR="${PROJECT_DIR}/${SAMPLE}_chr1/logs"
    
    echo "----------------------------------------"
    echo "${SAMPLE} ($([ "${SAMPLE}" == "HG002" ] && echo "Son" || [ "${SAMPLE}" == "HG003" ] && echo "Father" || echo "Mother"))"
    echo "----------------------------------------"
    
    # Find most recent time log
    local TIME_LOG=$(ls -t ${LOG_DIR}/time_stats_*.txt 2>/dev/null | head -1)
    
    if [ -f "${TIME_LOG}" ]; then
        echo "Elapsed time:     $(grep "Elapsed (wall clock)" ${TIME_LOG} | awk '{print $NF}')"
        echo "CPU time:         $(grep "User time" ${TIME_LOG} | awk '{print $NF}')s user + $(grep "System time" ${TIME_LOG} | awk '{print $NF}')s system"
        echo "CPU utilization:  $(grep "Percent of CPU" ${TIME_LOG} | awk '{print $NF}')"
        echo "Max RAM:          $(grep "Maximum resident" ${TIME_LOG} | awk '{print $NF}') KB"
        echo "Avg RAM:          $(grep "Average resident" ${TIME_LOG} | awk '{print $NF}') KB"
        echo "I/O Reads:        $(grep "File system inputs" ${TIME_LOG} | awk '{print $NF}')"
        echo "I/O Writes:       $(grep "File system outputs" ${TIME_LOG} | awk '{print $NF}')"
    else
        echo "Time log not found"
    fi
    
    echo ""
}

# Display stats for each sample
extract_stats "HG002"
extract_stats "HG003"
extract_stats "HG004"

echo "=========================================="
echo "OUTPUT LOCATIONS"
echo "=========================================="
for SAMPLE in HG002 HG003 HG004; do
    echo "${SAMPLE}: ${PROJECT_DIR}/${SAMPLE}_chr1/output/"
done

echo ""
echo "=========================================="
echo "MASTER LOGS"
echo "=========================================="
ls -lh ${PROJECT_DIR}/pipeline_master_*.log 2>/dev/null || echo "No master logs found"

echo ""
