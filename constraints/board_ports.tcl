## Project-specific AS02MC04 board-port mapping.
##
## Map named pins from the installed Vivado board file to this project's
## top-level RTL ports.

proc emit_project_board_constraints {fh pins c emitted_ports_var} {
    upvar $emitted_ports_var emitted_ports

    set board_xml [dict get $c board_xml]
    set clk_freq [board_clock_frequency $board_xml diff_100mhz_clk 100000000]
    set clk_period [format %.3f [expr {1000000000.0 / double($clk_freq)}]]
    set led_iostandard [dict get $c led_iostandard]

    emit_optional_board_port_constraint $fh $pins diff_100mhz_clk_p clk_100mhz_p BOARD emitted_ports
    emit_optional_board_port_constraint $fh $pins diff_100mhz_clk_n clk_100mhz_n BOARD emitted_ports
    emit_optional_clock_constraint $fh clk_100mhz_p $clk_period clk_100mhz

    emit_optional_board_port_constraint $fh $pins GPIO_LED_R led_r $led_iostandard emitted_ports
    emit_optional_board_port_constraint $fh $pins GPIO_LED_G led_g $led_iostandard emitted_ports
    emit_optional_board_port_constraint $fh $pins SFP_1_LED sfp_1_led $led_iostandard emitted_ports
    emit_optional_board_port_constraint $fh $pins SFP_2_LED sfp_2_led $led_iostandard emitted_ports

    emit_optional_board_port_constraint $fh $pins SFP_1_MOD_DEF_0 sfp_1_mod_def_0 BOARD emitted_ports
    emit_optional_board_port_constraint $fh $pins SFP_2_MOD_DEF_0 sfp_2_mod_def_0 BOARD emitted_ports
    emit_optional_board_port_constraint $fh $pins SFP_1_LOS sfp_1_los BOARD emitted_ports
    emit_optional_board_port_constraint $fh $pins SFP_2_LOS sfp_2_los BOARD emitted_ports
    emit_optional_board_port_constraint $fh $pins SFP_1_TX_FAULT sfp_1_tx_fault BOARD emitted_ports
    emit_optional_board_port_constraint $fh $pins SFP_2_TX_FAULT sfp_2_tx_fault BOARD emitted_ports
}
