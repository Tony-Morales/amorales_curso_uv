#!/bin/bash

# To use: 
#  export PATH=/opt/Xilinx/Vivado/2024.2/bin:$PATH

# Exit in case any command fails
set -e


# Get args to select input file 
TEST_NAME=${1:-input}
TEST_FILE="${TEST_NAME}.txt"

# Get args to select module parameters
NB_DATA=${2:-8}
NB_COUNT=${3:-8}

# File and Top Module Definitions
TB_TOP="tb_adaptive_rle"
SIM_DIR="sim_build/$TEST_NAME"
TIMESCALE="1ns/1ps"

# RTL and Testbench files
RTL_FILES=(
    "adaptive_rle_encoder.sv"
    "adaptive_rle_encoder_fsm.sv"
    "adaptive_rle_fifo.sv"
    "adaptive_rle_counter.sv"
    "adaptive_rle_comparator.sv"
    "adaptive_rle.sv"
    "../tb/tb.sv"
)

echo "**********************************************************"
echo "Starting Simulation with Vivado XSim"
echo "Top Module: ${TB_TOP}"
echo " NB_DATA: ${NB_DATA}"
echo " NB_COUNT: ${NB_COUNT}"
echo " Vector: ${TEST_FILE}"
echo "**********************************************************"

# Create and clean temporary simulation directory
rm -rf ${SIM_DIR}
mkdir -p ${SIM_DIR}
echo $PWD

# Copy files to the working directory
for file in "${RTL_FILES[@]}"; do
    if [ -f "../rtl/$file" ]; then
        cp "../rtl/$file" ./$SIM_DIR
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

# Compilation
echo "Compiling sources ..."
xvlog -sv *.sv -d DEF_NB_DATA=${NB_DATA} -d DEF_NB_COUNT=${NB_COUNT}

# Elaboration
echo "Elaborating design ..."
xelab -debug all ${TB_TOP} -s ${TB_TOP}_snapshot -timescale ${TIMESCALE}

# Simulation (xsim)
echo "Running simulation ..."

# Generate a Tcl to run simulation
cat <<EOT > run.tcl
log_wave -r {/tb_adaptive_rle} 
run all;
# open_wave_config {../sim_waveform.wcfg}
# exit
EOT

# Run the simulation in console
xsim ${TB_TOP}_snapshot -tclbatch run.tcl -gui
echo "**********************************************************"
echo " Simulation Finished Successfully"
echo "**********************************************************"