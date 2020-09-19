# Name: description.mk
# Author: Lucas Schneider
# 07/2020

# Name of all components in priority order
CPNT_LIST := rom_simples rom_arquivo rom_arquivo_generica

# Name of the component to be tested
CPNT ?= rom_simples

# Commands to prepare test files
PREPARE_TEST :=