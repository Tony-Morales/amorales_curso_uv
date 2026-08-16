#!/bin/bash
# Exit in case any command fails
set -e

# Get args to select input file 
TEST_NAME=${1:-input}
TEST_FILE="${TEST_NAME}.txt"
# Get args to select module parameters
NB_DATA=${2:-8}
NB_COUNT=${3:-8}

# File and Top Module Definitions
TB_TOP="tb_adaptive_lre"
SIM_DIR="sim_build_xrun/$TEST_NAME"
TIMESCALE="1ns/1ps"

RTL_FILES=(
    "adaptive_lre_encoder.sv"
    "adaptive_lre_encoder_fsm.sv"
    "adaptive_lre_fifo.sv"
    "adaptive_lre_counter.sv"
    "adaptive_lre_comparator.sv"
    "adaptive_lre.sv"
    "../tb/tb.sv"
)

echo "**********************************************************"
echo "Starting Cadence xrun simulation..."
echo "Top Module:  ${TB_TOP}"
echo " NB_DATA: ${NB_DATA}"
echo " NB_COUNT: ${NB_COUNT}"
echo " Vector: ${TEST_FILE}"
echo "**********************************************************"

# Create and clean temporary simulation directory
rm -rf ${SIM_DIR}
mkdir -p ${SIM_DIR}

# Copy files to the working directory
for file in "${RTL_FILES[@]}"; do
    if [ -f "../rtl/$file" ]; then
        cp "../rtl/$file" "./$SIM_DIR"
    else
        echo "Error: File ../rtl/$file not found"
        exit 1
    fi
done

# Copy TEST_FILE and rename to "input.txt"
if [ -f "../tb/vectors/$TEST_FILE" ]; then
    cp "../tb/vectors/$TEST_FILE" "./$SIM_DIR/input.txt"
else
    echo "Error: Test file ../tb/vectors/$TEST_FILE not found"
    exit 1
fi

cd ${SIM_DIR}

xrun -sv *.sv \
    +define+DEF_NB_DATA=${NB_DATA} \
    +define+DEF_NB_COUNT=${NB_COUNT} \
    -timescale ${TIMESCALE} \
    -access +rwc 

echo "**********************************************************"
echo " Simulation Finished Successfully"
echo "**********************************************************"