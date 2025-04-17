############################################
# import design
############################################
set DESIGN "GSIM"

analyze -format verilog "./GSIM.v"
elaborate $DESIGN
link
current_design $DESIGN


############################################
# source sdc
############################################
source -echo -verbose ./GSIM_DC.sdc


############################################
# compile
############################################
uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
compile_ultra
compile -inc


############################################
# output design
############################################
current_design $DESIGN

set hdlin_enable_presto_for_vhdl "TRUE"
set sh_enable_line_editing true
set sh_line_editing_mode emacs
history keep 100
alias h history

set bus_inference_style {%s[%d]}
set bus_naming_style {%s[%d]}
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed {a-z A-Z 0-9 _} -max_length 255 -type cell
define_name_rules name_rule -allowed {a-z A-Z 0-9 _[]} -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive
change_names -hierarchy -rules name_rule

remove_unconnected_ports -blast buses [get_cells -hierarchical *]
set verilogout_higher_designs_first true
write -format ddc      -hierarchy -output "./${DESIGN}_syn.ddc"
write -format verilog  -hierarchy -output "./${DESIGN}_syn.v"
write_sdf -version 3.0 -context verilog ./${DESIGN}_syn.sdf
write_sdc ./Netlist/${DESIGN}_syn.sdc -version 1.8

report_timing
report_area