create_clock -name clk -period 10.0 [get_ports clk]

set_clock_uncertainty -setup 0.20 [get_clocks clk]
set_clock_uncertainty -hold  0.05 [get_clocks clk]

set_input_delay 1.0 -clock clk [get_ports instr_rdata]
set_input_delay 1.0 -clock clk [get_ports data_rdata]
set_input_delay 1.0 -clock clk [get_ports rst]

set_output_delay 1.0 -clock clk [get_ports instr_addr]
set_output_delay 1.0 -clock clk [get_ports data_addr]
set_output_delay 1.0 -clock clk [get_ports data_wdata]
set_output_delay 1.0 -clock clk [get_ports data_read]
set_output_delay 1.0 -clock clk [get_ports data_write]
set_output_delay 1.0 -clock clk [get_ports debug_pc]
