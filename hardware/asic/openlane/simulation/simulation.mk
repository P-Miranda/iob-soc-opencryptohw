include hardware.mk

#axi portmap for axi ram
VHDR+=s_axi_portmap.vh
s_axi_portmap.vh:
	$(LIB_DIR)/software/python/axi_gen.py axi_portmap 's_' 's_' 'm_'

#default baud and freq for simulation
BAUD=$(SIM_BAUD)
FREQ=$(SIM_FREQ)

#define for testbench
DEFINE+=$(defmacro)BAUD=$(BAUD)
DEFINE+=$(defmacro)FREQ=$(FREQ)

# PDK defines
DEFINE+=$(defmacro)UNIT_DELAY=\#1
DEFINE+=$(defmacro)FUNCTIONAL


#ddr controller address width
DDR_ADDR_W=$(DCACHE_ADDR_W)

CONSOLE_CMD=$(PYTHON_DIR)/console -L

#produce waveform dump
VCD ?= 0

ifeq ($(VCD),1)
DEFINE+=$(defmacro)VCD
endif

ifeq ($(INIT_MEM),0)
CONSOLE_CMD+=-f
endif

ifneq ($(wildcard  firmware.hex),)
FW_SIZE=$(shell wc -l firmware.hex | awk '{print $$1}')
endif

DEFINE+=$(defmacro)FW_SIZE=$(FW_SIZE)

#SOURCES

# xunit tests
XUNITM_VSRC+=$(HW_DIR)/simulation/verilog_tb/test_xunitM_tb.v
XUNITF_VSRC+=$(HW_DIR)/simulation/verilog_tb/test_xunitF_tb.v

#verilog testbench
TB_DIR:=$(HW_DIR)/simulation/verilog_tb

#axi memory
include $(AXI_DIR)/hardware/axiram/hardware.mk
include $(AXI_DIR)/hardware/axiinterconnect/hardware.mk

VSRC+=system_top.v

#testbench
ifneq ($(SIMULATOR),verilator)
VSRC+=system_tb.v
endif

# Input/Output
SOC_IN_BIN=soc-in.bin
TEST_IN_BIN=$(SW_TEST_DIR)/$(basename $(TEST_VECTOR_RSP))_d_in.bin
SOC_OUT_BIN:=soc-out.bin


#RULES
build: $(VSRC) $(VHDR) $(HEXPROGS) $(SOC_IN_BIN)
ifeq ($(SIM_SERVER),)
	make comp
else
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) "if [ ! -d $(REMOTE_ROOT_DIR) ]; then mkdir -p $(REMOTE_ROOT_DIR); fi"
	rsync -avz --delete --force --exclude-from=$(ROOT_DIR)/.rsync_exclude $(SIM_SYNC_FLAGS) $(ROOT_DIR) $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ROOT_DIR)
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) 'make -C $(REMOTE_ROOT_DIR)/hardware/asic/openlane/simulation build VCD=$(VCD) SIMULATOR=$(SIMULATOR)'
endif

run: sim
ifeq ($(VCD),1)
	if [ ! `pgrep -u $(USER) gtkwave` ]; then gtkwave system.vcd; fi &
endif

sim:
ifeq ($(SIM_SERVER),)
	cp $(FIRM_DIR)/firmware.bin .
	@rm -f soc2cnsl cnsl2soc
	$(CONSOLE_CMD) $(TEST_LOG) &
	bash -c "trap 'make kill-cnsl' INT TERM KILL EXIT; make exec"
else
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) "if [ ! -d $(REMOTE_ROOT_DIR) ]; then mkdir -p $(REMOTE_ROOT_DIR); fi"
	rsync -avz --force --exclude-from=$(ROOT_DIR)/.rsync_exclude $(SIM_SYNC_FLAGS) $(ROOT_DIR) $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ROOT_DIR)
	bash -c "trap 'make kill-remote-sim' INT TERM KILL; ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) 'make -C $(REMOTE_ROOT_DIR)/hardware/asic/openlane/simulation $@ SIMULATOR=$(SIMULATOR) INIT_MEM=$(INIT_MEM) USE_DDR=$(USE_DDR) RUN_EXTMEM=$(RUN_EXTMEM) VCD=$(VCD) TEST_LOG=\"$(TEST_LOG)\"'"
ifneq ($(TEST_LOG),)
	scp $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ROOT_DIR)/hardware/simulation/$(SIMULATOR)/test.log $(SIM_DIR)
endif
ifeq ($(VCD),1)
	scp $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ROOT_DIR)/hardware/simulation/$(SIMULATOR)/*.vcd $(SIM_DIR)
endif
	# scp $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ROOT_DIR)/hardware/asic/openlane/simulation/$(SOC_OUT_BIN) .
endif

#
#EDIT TOP OR TB DEPENDING ON SIMULATOR
#

system_tb.v:
	cp $(TB_DIR)/system_core_tb.v $@
	$(if $(HFILES), $(foreach f, $(HFILES), sed -i '/PHEADER/a `include \"$f\"' $@;),) # insert header files

#create  simulation top module
system_top.v: $(TB_DIR)/system_top_core.v
	cp $< $@
	$(foreach p, $(PERIPHERALS), $(eval HFILES=$(shell echo `ls $($p_DIR)/hardware/include/*.vh | grep -v pio | grep -v inst | grep -v swreg | grep -v port`)) \
	$(eval HFILES+=$(notdir $(filter %swreg_def.vh, $(VHDR)))) \
	$(if $(HFILES), $(foreach f, $(HFILES), sed -i '/PHEADER/a `include \"$(notdir $f)\"' $@;),)) # insert header files
	$(foreach p, $(PERIPHERALS), if test -f $($p_DIR)/hardware/include/pio.vh; then sed s/input/wire/ $($p_DIR)/hardware/include/pio.vh | sed s/output/wire/  | sed s/\,/\;/ > wires_tb.vh; sed -i '/PWIRES/r wires_tb.vh' $@; fi;) # declare and insert wire declarations
	$(foreach p, $(PERIPHERALS), if test -f $($p_DIR)/hardware/include/pio.vh; then sed s/input// $($p_DIR)/hardware/include/pio.vh | sed s/output// | sed 's/\[.*\]//' | sed 's/\([A-Za-z].*\),/\.\1(\1),/' > ./ports.vh; sed -i '/PORTS/r ports.vh' $@; fi;) #insert and connect pins in uut instance
	$(foreach p, $(PERIPHERALS), if test -f $($p_DIR)/hardware/include/inst_tb.vh; then sed -i '/endmodule/e cat $($p_DIR)/hardware/include/inst_tb.vh' $@; fi;) # insert peripheral instances


#add peripheral testbench sources
VSRC+=$(foreach p, $(PERIPHERALS), $(shell if test -f $($p_DIR)/hardware/testbench/module_tb.sv; then echo $($p_DIR)/hardware/testbench/module_tb.sv; fi;))

kill-remote-sim:
	@echo "INFO: Remote simulator $(SIMULATOR) will be killed"
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) 'killall -q -u $(SIM_USER) -9 $(SIM_PROC); \
	make -C $(REMOTE_ROOT_DIR)/hardware/simulation/$(SIMULATOR) kill-cnsl'
ifeq ($(VCD),1)
	scp $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ROOT_DIR)/hardware/simulation/$(SIMULATOR)/*.vcd $(SIM_DIR)
endif

kill-sim:
	@if [ "`ps aux | grep $(USER) | grep console | grep python3 | grep -v grep`" ]; then \
	kill -9 $$(ps aux | grep $(USER) | grep console | grep python3 | grep -v grep | awk '{print $$2}'); fi

test: clean-testlog test-shortmsg

test-shortmsg: sim-shortmsg # validate

sim-shortmsg:
	make -C $(PC_DIR) gen-versat
	make build INIT_MEM=1 USE_DDR=1 RUN_EXTMEM=1 HARDWARE_TEST=2
	make run INIT_MEM=1 USE_DDR=1 RUN_EXTMEM=1 HARDWARE_TEST=2

validate:
	cp $(SOC_OUT_BIN) $(SW_TEST_DIR)
	make -C $(SW_TEST_DIR) validate SOC_OUT_BIN=$(SOC_OUT_BIN) TEST_VECTOR_RSP=$(TEST_VECTOR_RSP) 

$(SOC_IN_BIN): $(TEST_IN_BIN)
	cp $< $@

$(TEST_IN_BIN):
	make -C $(SW_TEST_DIR) gen_test_data TEST_VECTOR_RSP=$(TEST_VECTOR_RSP)

#clean target common to all simulators
clean-remote: hw-clean
	@rm -f soc2cnsl cnsl2soc *.txt
	@rm -f system.vcd
ifneq ($(SIM_SERVER),)
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) "if [ ! -d $(REMOTE_ROOT_DIR) ]; then mkdir -p $(REMOTE_ROOT_DIR); fi"
	rsync -avz --delete --force --exclude-from=$(ROOT_DIR)/.rsync_exclude $(SIM_SYNC_FLAGS) $(ROOT_DIR) $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ROOT_DIR)
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) 'make -C $(REMOTE_ROOT_DIR) sim-clean SIMULATOR=$(SIMULATOR)'
endif

#clean test log only when sim testing begins
clean-testlog:
	@rm -f test.log
ifneq ($(SIM_SERVER),)
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) "if [ ! -d $(REMOTE_ROOT_DIR) ]; then mkdir -p $(REMOTE_ROOT_DIR); fi"
	rsync -avz --delete --force --exclude-from=$(ROOT_DIR)/.rsync_exclude $(SIM_SYNC_FLAGS) $(ROOT_DIR) $(SIM_USER)@$(SIM_SERVER):$(REMOTE_ROOT_DIR)
	ssh $(SIM_SSH_FLAGS) $(SIM_USER)@$(SIM_SERVER) 'rm -f $(REMOTE_ROOT_DIR)/hardware/simulation/$(SIMULATOR)/test.log'
endif

debug:
	@echo $(VHDR)
	@echo $(VSRC)
	@echo $(INCLUDE)
	@echo $(DEFINE)
	@echo $(MEM_DIR)
	@echo $(CPU_DIR)
	@echo $(CACHE_DIR)
	@echo $(UART_DIR)

.PRECIOUS: system.vcd test.log

.PHONY: build run sim \
	kill-remote-sim clean-remote \
	test test1 test2 test3 test4 test5 clean-testlog
