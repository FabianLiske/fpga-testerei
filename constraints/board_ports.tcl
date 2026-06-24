## Project-specific AS02MC04 board-port mapping.
##
## Map named pins from the installed Vivado board file to this project's
## top-level RTL ports.

proc emit_project_board_constraints {fh pins c emitted_ports_var} {
    upvar $emitted_ports_var emitted_ports

    set led_iostandard [dict get $c led_iostandard]

    puts $fh "## Project mapping: red user LED."
    puts $fh "## LED_IOSTANDARD=$led_iostandard; use LED_IOSTANDARD=NONE to omit it or override with e.g. LVCMOS33."
    emit_optional_board_port_constraint $fh $pins GPIO_LED_R led $led_iostandard emitted_ports
}
