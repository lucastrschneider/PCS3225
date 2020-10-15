# Name: Makefile
# Author: Lucas Haug
# Author: Lucas Schneider
# 07/2020

# Makefile for VHDL projects

###############################################################################
## Project specification
###############################################################################

# Current project folder
EP ?= EP4

# Include the project specif information
include $(EP)/description.mk

###############################################################################
## Input files
###############################################################################

# Build directory
WORK_DIR := $(EP)/work

# Source directories
CPNT_DIR := $(EP)/component
TB_DIR := $(EP)/testbench

# Source Files
CPNT_TARGETS	:= $(addprefix $(CPNT_DIR)/, $(addsuffix .vhd, $(CPNT_LIST)))
TB_TARGETS		:= $(wildcard $(TB_DIR)/*.vhd)
ALL_TARGETS		:= $(CPNT_TARGETS) $(TB_TARGETS)

# Default values, can be set on the command line or here
DEBUG	?= 1
VISUAL	?= 0
VERBOSE	?= 1

###############################################################################
## Compiler settings
###############################################################################

# Executable
GHDL := ghdl
VERSION := 93c

# Generic flags
GHDL_FLAGS := --std=$(VERSION) --workdir=$(WORK_DIR)

ifeq ($(DEBUG), 1)
GHDL_FLAGS += -v
endif

# Verbosity
ifeq ($(VERBOSE),0)
AT := @
else
AT :=
endif

###############################################################################
## Build and Auxiliary Targets
###############################################################################

# General
analyse: | $(WORK_DIR)
	$(AT)$(GHDL) -a $(GHDL_FLAGS) $(ALL_TARGETS)

check_syntax: | $(WORK_DIR)
	$(AT)$(GHDL) -s $(GHDL_FLAGS) $(ALL_TARGETS)

clean:
	$(AT)rm -rf $(WORK_DIR)

$(WORK_DIR):
	$(AT)mkdir -p $(WORK_DIR)

print:
	@echo $(CPNT_LIST) "\n"$(CPNT_TARGETS) "\n"$(TB_TARGETS)

prepare:
	$(AT)$(PREPARE_TEST)

# Tests
test: | $(WORK_DIR)
	$(AT)$(GHDL) -r $(GHDL_FLAGS) $(CPNT)_tb --vcd=$(WORK_DIR)/$(CPNT)_test.vcd
ifeq ($(VISUAL), 1)
	gtkwave $(WORK_DIR)/$(CPNT)_test.vcd
endif

###############################################################################

.PHONY: analyse check_syntax clean print test

.DEFAULT_GOAL := analyse