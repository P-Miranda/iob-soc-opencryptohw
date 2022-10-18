SHELL = /bin/bash
export 

#run on external memory implies DDR use
ifeq ($(RUN_EXTMEM),1)
USE_DDR=1
endif

#ILA_DIR=./submodules/ILA
#ILA_PYTHON_DIR=$(ILA_DIR)/software/python
#ila-build: ilaFormat.txt
#	$(ILA_PYTHON_DIR)/ilaGenerateSource.py ilaFormat.txt ila.c
#	$(ILA_PYTHON_DIR)/ilaGenerateVerilog.py ilaFormat.txt $(HW_DIR)/include/
#	cp ila.c $(FIRM_DIR)/
#	cp ila.c $(PC_DIR)/

#ila-generate-vcd: ilaFormat.txt ilaData.txt
#	$(ILA_PYTHON_DIR)/ilaDataToVCD.py ilaFormat.txt ilaData.txt ilaOut.vcd

ila-clean:
	@rm -f $(HW_DIR)/include/signal_inst.vh $(FIRM_DIR)/ila.c $(PC_DIR)/ila.c ila.c

#
# BUILD EMBEDDED SOFTWARE
#
SW_DIR:=./software
FIRM_DIR:=$(SW_DIR)/firmware

#default baud and frequency if not given
BAUD ?=$(SIM_BAUD)
FREQ ?=$(SIM_FREQ)

fw-build: #ila-build
	make -C $(FIRM_DIR) build-all

fw-clean:
	make -C $(FIRM_DIR) clean-all

fw-debug:
	make -C $(FIRM_DIR) debug

#
# EMULATE ON PC
#

PC_DIR:=$(SW_DIR)/pc-emul
pc-emul-build: #ila-build
	make -C $(PC_DIR) build

pc-emul-run: pc-emul-build
	make -C $(PC_DIR) run

pc-emul-clean: fw-clean
	make -C $(PC_DIR) clean

pc-emul-test: pc-emul-clean
	make -C $(PC_DIR) test


HW_DIR=./hardware
#
# SIMULATE RTL
#
#default simulator running locally or remotely
SIMULATOR ?=verilator
SIM_DIR=$(HW_DIR)/simulation/$(SIMULATOR)
#default baud and system clock frequency
SIM_BAUD = 2500000
SIM_FREQ =50000000
sim-build: #ila-build
	make -C $(PC_DIR) run
	make fw-build
	make -C $(SIM_DIR) build

./hardware/src/versat_instance.v:
	make -C $(PC_DIR) run
	make fw-build SIM=1
	make -C $(SIM_DIR) build

sim-run: sim-build ./hardware/src/versat_instance.v
	make -C $(SIM_DIR) run

sim-clean: fw-clean
	make -C $(SIM_DIR) clean

sim-test:
	make -C $(SIM_DIR) test

sim-versat-fus:
	make -C $(SIM_DIR) xunitM SIMULATOR=icarus
	make -C $(SIM_DIR) xunitF SIMULATOR=icarus

sim-debug:
	make -C $(SIM_DIR) debug

#
# BUILD, LOAD AND RUN ON FPGA BOARD
#
#default board running locally or remotely
BOARD ?=AES-KU040-DB-G
BOARD_DIR =$(shell find hardware -name $(BOARD))
#default baud and system clock freq for boards
BOARD_BAUD = 115200
#default board frequency
BOARD_FREQ ?=100000000
ifeq ($(BOARD), CYCLONEV-GT-DK)
BOARD_FREQ =50000000
endif

fpga-fw-build: #ila-build
	make fw-build BAUD=$(BOARD_BAUD) FREQ=$(BOARD_FREQ)

fpga-build: #ila-build
	make -C $(PC_DIR) run
	make fw-build BAUD=$(BOARD_BAUD) FREQ=$(BOARD_FREQ)
	make -C $(BOARD_DIR) build

fpga-run: fpga-fw-build
	make -C $(BOARD_DIR) run TEST_LOG="$(TEST_LOG)"

fpga-clean: fw-clean
	make -C $(BOARD_DIR) clean

fpga-veryclean:
	make -C $(BOARD_DIR) veryclean

fpga-debug:
	make -C $(BOARD_DIR) debug

fpga-test:
	make -C $(BOARD_DIR) test

#
# COMPILE DOCUMENTS
#
DOC_DIR=document/$(DOC)
doc-build:
	make -C $(DOC_DIR) $(DOC).pdf

doc-clean:
	make -C $(DOC_DIR) clean

doc-test:
	make -C $(DOC_DIR) test

#
# CLEAN
#

clean: pc-emul-clean sim-clean fpga-clean doc-clean ila-clean

#
# TEST ALL PLATFORMS
#

test-pc-emul: pc-emul-test

test-pc-emul-clean: pc-emul-clean

test-sim:
	make sim-test SIMULATOR=verilator
	make sim-test SIMULATOR=icarus

test-sim-clean:
	make sim-clean SIMULATOR=verilator
	make sim-clean SIMULATOR=icarus

test-fpga:
	make fpga-test BOARD=CYCLONEV-GT-DK
	make fpga-test BOARD=AES-KU040-DB-G

test-fpga-clean:
	make fpga-clean BOARD=CYCLONEV-GT-DK
	make fpga-clean BOARD=AES-KU040-DB-G

test-doc:
	make fpga-clean BOARD=CYCLONEV-GT-DK
	make fpga-clean BOARD=AES-KU040-DB-G
	make fpga-build BOARD=CYCLONEV-GT-DK
	make fpga-build BOARD=AES-KU040-DB-G
	make doc-test DOC=pb
	make doc-test DOC=presentation

test-doc-clean:
	make doc-clean DOC=pb
	make doc-clean DOC=presentation

test: test-clean test-pc-emul test-sim test-fpga test-doc

test-clean: test-pc-emul-clean test-sim-clean test-fpga-clean test-doc-clean

debug:
	@echo $(UART_DIR)
	@echo $(CACHE_DIR)

.PHONY: fw-build fw-clean fw-debug\
	pc-emul-build pc-emul-run pc-emul-clean pc-emul-test \
	sim-build sim-run sim-clean sim-test \
	fpga-build fpga-run fpga-clean fpga-test \
	doc-build doc-clean doc-test \
	clean \
	test-pc-emul test-pc-emul-clean \
	test-sim test-sim-clean \
	test-fpga test-fpga-clean \
	test-doc test-doc-clean \
	test test-clean \
	debug
	#ila-build ila-generate-vcd ila-clean
