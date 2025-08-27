## CLock Source Waveform
set CLK_PERIOD        1
set CLK_RISING_EDGE   0
set CLK_FALLING_EDGE  [expr $CLK_PERIOD/2.0]

## Clock Imperfect Effect
set CLK_UNCERTAINTY   0.1
set CLK_TRANSITION    0.1
set CLK_LATENCY       1

## IO Delay
set INPUT_MAX_DELAY   [expr $CLK_PERIOD/2.0]
set OUTPUT_MAX_DELAY  [expr $CLK_PERIOD/2.0]
set INPUT_MIN_DELAY   0
set OUTPUT_MIN_DELAY  0

## Loading
set OUTPUT_LOADING    0.01

###############################################################################
create_clock -name clk -period $CLK_PERIOD -waveform "$CLK_RISING_EDGE $CLK_FALLING_EDGE" [get_ports clk]

set_ideal_network       [get_ports clk]
set_ideal_network       [get_ports rst]

set_clock_uncertainty -setup $CLK_UNCERTAINTY [get_clocks clk]
set_clock_uncertainty -hold 0.02 [get_clocks clk]
set_clock_transition $CLK_TRANSITION [get_clocks clk]
set_clock_latency $CLK_LATENCY [get_clocks clk]

set_input_delay -max $INPUT_MAX_DELAY -clock clk [remove_from_collection [all_inputs] [get_ports {clk rst}]]
set_input_delay -min $INPUT_MIN_DELAY -clock clk [remove_from_collection [all_inputs] [get_ports {clk rst}]]

set_output_delay -max $OUTPUT_MAX_DELAY -clock clk [all_outputs]
set_output_delay -min $OUTPUT_MIN_DELAY -clock clk [all_outputs]

set_load -pin_load $OUTPUT_LOADING [all_outputs]
