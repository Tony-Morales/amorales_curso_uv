create_clock -name i_clock -period 50 -waveform {0 1} [get_ports "i_clock"]

set_clock_transition -rise 0.1 [get_clocks "i_clock"]
set_clock_transition -fall 0.1 [get_clocks "i_clock"]
set_clock_uncertainty 0.01 [get_ports "i_clock"]

set_input_delay  -clock [get_clocks "i_clock"] -max 0.1  [remove_from_collection [all_inputs] [get_ports "i_clock i_reset_n"]]
set_output_delay -clock [get_clocks "i_clock"] -max 0.1  [all_outputs]

set_false_path -from [get_ports "i_reset_n"]
