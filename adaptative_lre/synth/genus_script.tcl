#Directorio con la información de tiempos (el que contiene *.lib en formato liberate)
set_db init_lib_search_path /eda/gsclib045_all_v4.4/gsclib045/timing/
# directorios con las fuente en hdl
set_db init_hdl_search_path ../rtl
# Biblioteca con las celdas y tiempos que se quieren usar
read_libs slow_vdd1v0_basicCells.lib

# Leemos ficheros Verilog:
read_hdl adaptive_rle_comparator.sv  -sv
read_hdl adaptive_rle_counter.sv  -sv
read_hdl adaptive_rle_encoder_fsm.sv  -sv
read_hdl adaptive_rle_encoder.sv  -sv
read_hdl adaptive_rle_fifo.sv  -sv
read_hdl adaptive_rle.sv -sv

set_db hdl_max_memory_address_range 100000
# Sintetiza a rtl basico:
elaborate 

# Leemos fichero de restricciones:
read_sdc ./constraints.sdc

# fijamos los esfuerzos digitales a medio (low medium high)
set_db syn_generic_effort medium
set_db syn_map_effort medium
set_db syn_opt_effort medium

# Sintesis utilizando los componentes del read_libs
syn_generic
syn_map
syn_opt

# Generamos informes de todo tipo:
report_timing -max_paths 10 > reports/report_timing.rpt
report_power > reports/report_power.rpt
report_area > reports/report_area.rpt
report_qor > reports/report_qor.rpt

# Generamos Outputs para las siguientes etapas:
write_hdl > outputs/adaptive_rle_netlist.v
write_sdc > outputs/adaptive_rle_sintesis.sdc
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge -setuphold split > outputs/delays.sdf

# Lanzamos el visor interactivo para ver los resultados:
# gui_show
