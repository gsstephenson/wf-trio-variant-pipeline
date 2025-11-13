#!/bin/bash
#############################################################################
# Environment Configuration for Trio Analysis Pipeline
# Auto-detects and sets paths based on current environment
#############################################################################

# Detect environment
if [[ $(hostname) == *"piel"* ]]; then
    # Running on Piel server
    export TRIO_ENV="piel"
    export TRIO_DATA_DIR="/data/human_trios/family1"
    export TRIO_PROJECT_DIR="/scratch/${USER}/trio_project"
    export TRIO_SCRATCH_DIR="/scratch/${USER}"
    echo "Detected: Piel server environment"
elif [[ -d "/mnt/data_1/CU_Boulder" ]]; then
    # Running on local server (ODYSSEUS)
    export TRIO_ENV="local"
    export TRIO_DATA_DIR="/mnt/data_1/CU_Boulder/MCDB-4520/data/human_trios/family1"
    export TRIO_PROJECT_DIR="/mnt/work_1/${USER}/CU_Boulder/MCDB-4520/project"
    export TRIO_SCRATCH_DIR="/mnt/work_1/${USER}/CU_Boulder/MCDB-4520"
    echo "Detected: Local server environment (Odysseus)"
else
    # Unknown/custom environment - use current directory
    export TRIO_ENV="custom"
    export TRIO_DATA_DIR="./data/human_trios/family1"
    export TRIO_PROJECT_DIR="$(pwd)"
    export TRIO_SCRATCH_DIR="$(pwd)/tmp"
    echo "Detected: Custom environment"
    echo "Using current directory: ${TRIO_PROJECT_DIR}"
fi

echo "Data directory: ${TRIO_DATA_DIR}"
echo "Project directory: ${TRIO_PROJECT_DIR}"
echo "Scratch directory: ${TRIO_SCRATCH_DIR}"
echo ""
echo "To override, set these before running:"
echo "  export TRIO_DATA_DIR=/your/data/path"
echo "  export TRIO_PROJECT_DIR=/your/project/path"
echo "  export TRIO_SCRATCH_DIR=/your/scratch/path"
