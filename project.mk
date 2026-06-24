# Project configuration for this AS02MC04 design.
#
# This file is intentionally versioned in downstream projects. Keep project
# identity and board choices here so template Makefile/Tcl updates merge cleanly.
#
# Board-pin-to-RTL-port mappings live in constraints/board_ports.tcl.

TOP := top
BUILD = $(HOME)/build/$(PROJECT_NAME)

BOARD_PART := tiferking.cn:as02mc04:part0:1.0
PART := xcku3p-ffvb676-2-e

BOARD_CONSTRAINTS := 1
LED_IOSTANDARD := BOARD
BOARD_AUTO_PORTS := 1
BOARD_AUTO_IOSTANDARD := NONE

HW_FREQ := 10000000
