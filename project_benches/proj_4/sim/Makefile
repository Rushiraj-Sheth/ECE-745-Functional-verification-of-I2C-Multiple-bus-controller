export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile

GEN_TRANS_TYPE ?= ncsu_transaction
TEST_SEED ?= 12345

clean: 
	rm -rf work *.wlf transcript qrun.out


comp_I2C_MB:
	vcom +cover=bcefsx ../rtl/iicmb_int_pkg.vhd
	vcom +cover=bcefsx ../rtl/iicmb_pkg.vhd
	vcom +cover=bcefsx ../rtl/mbyte.vhd
	vcom +cover=bcefsx ../rtl/mbit.vhd
	vcom +cover=bcefsx ../rtl/bus_state.vhd
	vcom +cover=bcefsx ../rtl/filter.vhd
	vcom +cover=bcefsx ../rtl/conditioner.vhd
	vcom +cover=bcefsx ../rtl/conditioner_mux.vhd
	vcom +cover=bcefsx ../rtl/iicmb_m.vhd
	vcom +cover=bcefsx ../rtl/regblock.vhd
	vcom +cover=bcefsx ../rtl/wishbone.vhd
	vcom +cover=bcefsx ../rtl/iicmb_m_wb.vhd


comp_bench: comp_ncsu_pkg comp_wb_pkg comp_i2c_pkg comp_i2cmb_env_pkg 
	vlog ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

simulate:
	vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

debug_3step: clean compile simulate run_gui

run_cli:
	vsim  -c -coverage -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GEN_TRANS_TYPE); coverage save $(GEN_TRANS_TYPE).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

run_gui:
	vsim  -sv_seed $(TEST_SEED) -do "do wave.do;run -a" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

gui: clean compile optimize run_cli

debug:
	qrun -64 -gui -visualizer -onfinish stop -classdebug -uvmcontrol=all -msgmode both -permit_unmatched_virtual_intf -l run.log -f lab1_filelist.f -sv_seed 123456 -msglimit error -msglimitcount 20 -do "set IterationLimit 140000; set NoQuitOnFinish 1; coverage attribute -name TESTNAME -value test_top; coverage save -onexit test_top.ucdb; do wave.do" -debug,livesim -qwavedb=+signal+memory=1024+report+parameter+class+assertion+uvm_schematic+msg+classmemory=1024+statictaskfunc -top top -covermultiuserenv -designfile design.bin +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) 

convert_testplan:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./test_plan_layered_testbench.ucdb
	
merge_coverage:
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 
	
report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb 

regress:
	./regress.sh