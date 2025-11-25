# Create work library
vlib work

# Compile Verilog
#     All Verilog files that are part of this design should have
#     their own "vlog" line below.
vlog "./*.sv"


# Call vsim to invoke simulator
#     Make sure the last item on the line is the name of the
#     testbench module you want to execute.

vsim -voptargs="+acc" -t 1ps -lib work CPUstim
# vsim -voptargs="+acc" -t 1ps -lib work datamem_testbench
# vsim -voptargs="+acc" -t 1ps -lib work 

# Source the wave do file
#     This should be the file that sets up the signal window for
#     the module you are testing.
do CPUstim_wave.do
# do datamem_wave.do

# Set the window types
view wave
view structure
view signals

# Run the simulation
run -all

# End
