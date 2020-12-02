set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) decred_top

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/decred_defines.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/addressalyzer.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/clock_div.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/decred.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/decred_top.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/hash_macro_nonblock.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/register_bank.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/spi_passthrough.v \
	$script_dir/../../verilog/rtl/decred_top/rtl/src/spi_slave_des.v"

#works
set ::env(CLOCK_PORT) "M1_CLK_IN"

# TODO
set ::env(CLOCK_TREE_SYNTH) 0

set ::env(CLOCK_PERIOD) "28"

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 2920 3520"
set ::env(DESIGN_IS_CORE) 0
set ::env(FP_PDN_CORE_RING) 0
set ::env(GLB_RT_MAXLAYER) 5

#set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg
# set ::env(FP_CONTEXT_DEF) $script_dir/../user_project_wrapper/runs/user_project_wrapper/tmp/floorplan/ioPlacer.def.macro_placement.def
# set ::env(FP_CONTEXT_LEF) $script_dir/../user_project_wrapper/runs/user_project_wrapper/tmp/merged_unpadded.lef

set ::env(PL_BASIC_PLACEMENT) 1

# (Too many errors to count 21.04% non-blocking (4 macros))
set ::env(FP_CORE_UTIL) "26"
set ::env(PL_TARGET_DENSITY) 0.22
set ::env(SYNTH_STRATEGY) "2"
set ::env(SYNTH_MAX_FANOUT) "6"
set ::env(FP_ASPECT_RATIO) "1"
set ::env(CELL_PAD) "0"
set ::env(GLB_RT_ADJUSTMENT) "0.0"
set ::env(DIODE_INSERTION_STRATEGY) "3"

# (1, 0 errors 10.55% non-blocking (2 macros))
#set ::env(FP_CORE_UTIL) "15"
#set ::env(PL_TARGET_DENSITY) 0.11
#set ::env(SYNTH_STRATEGY) "2"
#set ::env(SYNTH_MAX_FANOUT) "6"
#set ::env(FP_ASPECT_RATIO) "1"
#set ::env(CELL_PAD) "0"
#set ::env(GLB_RT_ADJUSTMENT) "0.0"
#set ::env(DIODE_INSERTION_STRATEGY) "3"

# no detailed routing errors (5.3% non-blocking (1 macro))
#set ::env(FP_CORE_UTIL) "6"
#set ::env(PL_TARGET_DENSITY) 0.06
#set ::env(SYNTH_STRATEGY) "2"
#set ::env(SYNTH_MAX_FANOUT) "6"
#set ::env(FP_ASPECT_RATIO) "1"
#set ::env(CELL_PAD) "2"
#set ::env(GLB_RT_ADJUSTMENT) "0.0"
#set ::env(DIODE_INSERTION_STRATEGY) "3"
