VIVADO ?= vivado
REPO_ROOT := $(abspath .)
DEFAULT_PROJECT_NAME := $(notdir $(REPO_ROOT))
BUILD ?= build/default
JOBS ?= 32
TOP ?= top
BOARD_PART ?= tiferking.cn:as02mc04:part0:1.0
PART ?= xcku3p-ffvb676-2-e
HW_FREQ ?= 1000000
PROJECT_NAME ?= $(DEFAULT_PROJECT_NAME)
BOARD_CONSTRAINTS ?= 1
LED_IOSTANDARD ?= BOARD
BOARD_AUTO_PORTS ?= 1
BOARD_AUTO_IOSTANDARD ?= NONE

-include project.mk
-include local.mk

ABS_BUILD := $(abspath $(BUILD))
PROJECT_XPR := $(ABS_BUILD)/project/$(PROJECT_NAME).xpr
VIVADO_ENV := REPO_ROOT="$(REPO_ROOT)" BUILD="$(ABS_BUILD)" PROJECT_NAME="$(PROJECT_NAME)" TOP="$(TOP)" PART="$(PART)" BOARD_PART="$(BOARD_PART)" JOBS="$(JOBS)" HW_FREQ="$(HW_FREQ)" BOARD_CONSTRAINTS="$(BOARD_CONSTRAINTS)" LED_IOSTANDARD="$(LED_IOSTANDARD)" BOARD_AUTO_PORTS="$(BOARD_AUTO_PORTS)" BOARD_AUTO_IOSTANDARD="$(BOARD_AUTO_IOSTANDARD)"
VIVADO_BATCH = cd "$(ABS_BUILD)" && env $(VIVADO_ENV) $(VIVADO) -mode batch

.PHONY: help project gui synth impl bit reports probe program clean

help:
	@printf '%s\n' \
	  'AS02MC04 Vivado template targets:' \
	  '  make project        Create/update Vivado project under BUILD' \
	  '  make gui            Open the generated project in Vivado GUI' \
	  '  make synth          Run synthesis and write reports/checkpoint' \
	  '  make impl           Run implementation and write reports/checkpoint' \
	  '  make bit            Build bitstream into BUILD/output' \
	  '  make reports        Regenerate reports from available runs' \
	  '  make probe          Open Hardware Manager and list JTAG devices only' \
	  '  make program        Volatile JTAG programming; requires CONFIRM=1' \
	  '  make clean          Remove generated build/Vivado artifacts' \
	  '' \
	  'Variables:' \
	  '  VIVADO=$(VIVADO)' \
	  '  PROJECT_NAME=$(PROJECT_NAME)' \
	  '  BUILD=$(BUILD)' \
	  '  JOBS=$(JOBS)' \
	  '  TOP=$(TOP)' \
	  '  BOARD_PART=$(BOARD_PART)' \
	  '  PART=$(PART)' \
	  '  HW_FREQ=$(HW_FREQ)' \
	  '  BOARD_CONSTRAINTS=$(BOARD_CONSTRAINTS)' \
	  '  LED_IOSTANDARD=$(LED_IOSTANDARD)' \
	  '  BOARD_AUTO_PORTS=$(BOARD_AUTO_PORTS)' \
	  '  BOARD_AUTO_IOSTANDARD=$(BOARD_AUTO_IOSTANDARD)'

$(ABS_BUILD):
	mkdir -p "$(ABS_BUILD)/logs"

project: $(ABS_BUILD)
	$(VIVADO_BATCH) -source "$(REPO_ROOT)/scripts/create_project.tcl" \
	  -log "$(ABS_BUILD)/logs/create_project.log" \
	  -journal "$(ABS_BUILD)/logs/create_project.jou"

gui: project
	cd "$(ABS_BUILD)" && $(VIVADO) -mode gui "$(PROJECT_XPR)" \
	  -log "$(ABS_BUILD)/logs/gui.log" \
	  -journal "$(ABS_BUILD)/logs/gui.jou"

synth: project
	cd "$(ABS_BUILD)" && env $(VIVADO_ENV) STAGE=synth $(VIVADO) -mode batch -source "$(REPO_ROOT)/scripts/build.tcl" \
	  -log "$(ABS_BUILD)/logs/synth.log" \
	  -journal "$(ABS_BUILD)/logs/synth.jou"

impl: project
	cd "$(ABS_BUILD)" && env $(VIVADO_ENV) STAGE=impl $(VIVADO) -mode batch -source "$(REPO_ROOT)/scripts/build.tcl" \
	  -log "$(ABS_BUILD)/logs/impl.log" \
	  -journal "$(ABS_BUILD)/logs/impl.jou"

bit: project
	cd "$(ABS_BUILD)" && env $(VIVADO_ENV) STAGE=bit $(VIVADO) -mode batch -source "$(REPO_ROOT)/scripts/build.tcl" \
	  -log "$(ABS_BUILD)/logs/bit.log" \
	  -journal "$(ABS_BUILD)/logs/bit.jou"

reports: project
	cd "$(ABS_BUILD)" && env $(VIVADO_ENV) STAGE=reports $(VIVADO) -mode batch -source "$(REPO_ROOT)/scripts/build.tcl" \
	  -log "$(ABS_BUILD)/logs/reports.log" \
	  -journal "$(ABS_BUILD)/logs/reports.jou"

probe: $(ABS_BUILD)
	$(VIVADO_BATCH) -source "$(REPO_ROOT)/scripts/probe.tcl" \
	  -log "$(ABS_BUILD)/logs/probe.log" \
	  -journal "$(ABS_BUILD)/logs/probe.jou"

program: $(ABS_BUILD)
	cd "$(ABS_BUILD)" && env $(VIVADO_ENV) CONFIRM="$(CONFIRM)" $(VIVADO) -mode batch -source "$(REPO_ROOT)/scripts/program.tcl" \
	  -log "$(ABS_BUILD)/logs/program.log" \
	  -journal "$(ABS_BUILD)/logs/program.jou"

clean:
	rm -rf build .Xil *.jou *.log vivado*.str webtalk*.jou webtalk*.log usage_statistics_webtalk.*
