ROOT_DIR=../..
include ../software.mk

BUILD_DIR=./build

#additional linker flag
LFLAGS+=-Wl,-Map,firmware.map

#cache
ifeq ($(USE_DDR),1)
include $(CACHE_DIR)/software/software.mk
endif

#uart
include $(UART_DIR)/software/embedded/embedded.mk

#timer
include $(TIMER_DIR)/software/embedded/embedded.mk

#ethernet	
include $(ETHERNET_DIR)/software/embedded/embedded.mk

#versat
include $(VERSAT_DIR)/software/embedded/embedded.mk

#HEADERS
HDR+=periphs.h
HDR+=versat_data.inc
HDR+=verilogWrapper.inc

#INCLUDES
INCLUDE+=$(incdir)$(FIRM_DIR)/units

#SOURCES
SRC+= firmware.S $(ALGORITHM)/firmware.cpp $(UART_DIR)/software/printf.c
SRC+= $(FIRM_DIR)/automaticTests.cpp
SRC+= $(FIRM_DIR)/unitConfiguration.cpp
SRC+= $(FIRM_DIR)/versatSHA.cpp
SRC+= $(FIRM_DIR)/versatAES.cpp

ifeq ($(ALGORITHM),SHA256)
SRC+= $(FIRM_DIR)/crypto/*.c
INCLUDE+=$(incdir)$(FIRM_DIR)/$(ALGORITHM)
SRC+= $(FIRM_DIR)/$(ALGORITHM)/fullSHATests.cpp
endif

ifeq ($(ALGORITHM),AES256)
SRC+= $(FIRM_DIR)/crypto/*.c
INCLUDE+=$(incdir)$(FIRM_DIR)/$(ALGORITHM)
INCLUDE+=$(incdir)$(CACHE_DIR)/software/
SRC+= $(FIRM_DIR)/$(ALGORITHM)/fullAESTests.cpp
endif

ifeq ($(ALGORITHM),MCELIECE)
SRC+= $(FIRM_DIR)/versatMCELIECE.cpp
INCLUDE+=$(incdir)$(FIRM_DIR)/$(ALGORITHM)
SRC+= $(FIRM_DIR)/$(ALGORITHM)/fullMCELIECETests.cpp
SRC+= $(FIRM_DIR)/$(ALGORITHM)/operations.cpp
SRC+= $(FIRM_DIR)/$(ALGORITHM)/versat_pk_gen.cpp
SRC+= $(wildcard $(FIRM_DIR)/$(ALGORITHM)/*.c)
INCLUDE+=$(incdir)$(FIRM_DIR)/$(ALGORITHM)/common
SRC+= $(wildcard $(FIRM_DIR)/$(ALGORITHM)/common/*.c)
endif


#PROFILE
ifeq ($(PROFILE),1)
HDR+=$(FIRM_DIR)/profile.h
SRC+= $(FIRM_DIR)/profile.c
DEFINE+=$(defmacro)PROFILE
endif

#SIMULATION
ifeq ($(SIM),1)
DEFINE+=$(defmacro)SIM
endif
ifneq ($(GENERATE_ONLY),)
DEFINE+=$(defmacro)GENERATE_ONLY
endif

#RULES

build: firmware.elf

firmware.elf: ../template.lds $(HDR) $(SRC) 
	$(TOOLCHAIN_PREFIX)gcc -o $@ $(CFLAGS) $(LFLAGS) $(DEFINE) $(INCLUDE) $(SRC) $(LLIBS) -lgcc -lc -lnosys -fno-exceptions
	$(TOOLCHAIN_PREFIX)objcopy -O binary firmware.elf firmware.bin

versat_data.inc: $(PC_DIR)/versat_data.inc
	cp $< $@

verilogWrapper.inc: $(PC_DIR)/build/verilogWrapper.inc
	cp $< $@

$(PC_DIR)/%.inc:
	@make -C $(ROOT_DIR) pc-emul-gen-versat HARDWARE_TEST=2

$(BUILD_DIR)/%.o: %.cpp
	mkdir -p $(BUILD_DIR)
	$(TOOLCHAIN_PREFIX)g++ -c -o $@ $(CFLAGS) $(LFLAGS) $(DEFINE) $(INCLUDE) $< $(LLIBS) -fno-exceptions

clean:
	@rm -rf firmware.bin firmware.elf firmware.map *.hex periphs.h UARTsw_reg.h TIMERsw_reg.h *swreg.h \
		*swreg_emb.c \
		*d_in.bin *d_out.bin \
		verilogWrapper.inc versat_data.inc \
		eth_frame_struct.h

.PHONY: build clean
