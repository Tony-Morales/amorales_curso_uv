#!/bin/bash
set -e

if [ "$1" == "xsim" ]; then
    RUN_CMD="./run_sim_xsim.sh"
elif [ "$1" == "xrun" ]; then
    RUN_CMD="./run_sim_xrun.sh"
else
    echo "Usage: $0 <xsim|xrun>"
    exit 1
fi


$RUN_CMD vector_nb_data_16_nb_count_16      16  16
$RUN_CMD vector_nb_data_16_nb_count_8       16  8
$RUN_CMD vector_nb_data_32_nb_count_16      32  16
$RUN_CMD vector_nb_data_32_nb_count_8       32  8
$RUN_CMD vector_nb_data_8_nb_count_8        8  8 
$RUN_CMD vector_ovf_nb_data_16_nb_count_16  16  16
$RUN_CMD vector_ovf_nb_data_16_nb_count_8   16  8
$RUN_CMD vector_ovf_nb_data_32_nb_count_16  32  16
$RUN_CMD vector_ovf_nb_data_32_nb_count_8   32  8
$RUN_CMD vector_ovf_nb_data_8_nb_count_8    8   8

$RUN_CMD vector_hand_rx_2_fullsize          8  8 
$RUN_CMD vector_hand_rx_2_resize            8  8 
$RUN_CMD vector_hand_rx_fullsize            8  8 
$RUN_CMD vector_hand_rx_resize              8  8 
$RUN_CMD vector_knee_rx_fullsize            8  8 
$RUN_CMD vector_knee_rx_resize              8  8  

