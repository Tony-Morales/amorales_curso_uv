create_clock -name clk -period 2 -waveform {0 1} [get_ports "clk"]

set_clock_transition -rise 0.1 [get_clocks "clk"]
set_clock_transition -fall 0.1 [get_clocks "clk"]
set_clock_uncertainty 0.01 [get_ports "clk"]

set_input_delay  -clock [get_clocks "clk"] -max 0.1  [all_inputs]
set_output_delay -clock [get_clocks "clk"] -max 0.1  [all_outputs]
