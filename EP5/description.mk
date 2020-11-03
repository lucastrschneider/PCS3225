# Name: description.mk
# Author: Lucas Schneider
# 07/2020

# Name of all components in priority order
CPNT_LIST := signExtend alu alucontrol

# Name of the component to be tested
CPNT ?= 

# Commands to prepare test files
PREPARE_TEST :=