# operating conditions and boundary conditions #

set cycle  0.2         ;#clock period defined by designer

create_clock -name clk -period $cycle [get_ports  clk]
set_dont_touch_network      [get_clocks clk]
set_clock_uncertainty -setup 0.1  [get_clocks clk]
set_clock_uncertainty -hold 0.03  [get_clocks clk]
set_clock_latency      0.5  [get_clocks clk]
set_fix_hold [get_clocks clk]


set_input_delay  [expr $cycle * 0.5] -clock clk [remove_from_collection [all_inputs] {clk}]
set_output_delay [expr $cycle * 0.5] -clock clk [all_outputs]
set enable_recovery_removal_arcs true
set_drive 1 [all_inputs]
set_load 0.05 [all_outputs]



set_max_fanout 20 [all_inputs]
