`timescale 1ns/1ps

module top (
    input  wire clk_100mhz_p,
    input  wire clk_100mhz_n,
    input  wire sfp_1_mod_def_0,
    input  wire sfp_2_mod_def_0,
    input  wire sfp_1_los,
    input  wire sfp_2_los,
    input  wire sfp_1_tx_fault,
    input  wire sfp_2_tx_fault,
    output wire led_r,
    output wire led_g,
    output wire sfp_1_led,
    output wire sfp_2_led
);
    wire clk_ibuf;
    wire clk;

    logic [1:0] sfp_1_mod_def_0_sync = '1;
    logic [1:0] sfp_2_mod_def_0_sync = '1;
    logic [1:0] sfp_1_los_sync = '1;
    logic [1:0] sfp_2_los_sync = '1;
    logic [1:0] sfp_1_tx_fault_sync = '1;
    logic [1:0] sfp_2_tx_fault_sync = '1;

    wire sfp_1_present;
    wire sfp_2_present;
    wire sfp_status_ok;

    IBUFDS #(
        .DIFF_TERM("TRUE"),
        .IOSTANDARD("LVDS")
    ) u_clk_ibufds (
        .I(clk_100mhz_p),
        .IB(clk_100mhz_n),
        .O(clk_ibuf)
    );

    BUFG u_clk_bufg (
        .I(clk_ibuf),
        .O(clk)
    );

    always_ff @(posedge clk) begin
        sfp_1_mod_def_0_sync <= {sfp_1_mod_def_0_sync[0], sfp_1_mod_def_0};
        sfp_2_mod_def_0_sync <= {sfp_2_mod_def_0_sync[0], sfp_2_mod_def_0};
        sfp_1_los_sync <= {sfp_1_los_sync[0], sfp_1_los};
        sfp_2_los_sync <= {sfp_2_los_sync[0], sfp_2_los};
        sfp_1_tx_fault_sync <= {sfp_1_tx_fault_sync[0], sfp_1_tx_fault};
        sfp_2_tx_fault_sync <= {sfp_2_tx_fault_sync[0], sfp_2_tx_fault};
    end

    assign sfp_1_present = ~sfp_1_mod_def_0_sync[1];
    assign sfp_2_present = ~sfp_2_mod_def_0_sync[1];

    assign sfp_status_ok = sfp_1_present &&
                           sfp_2_present &&
                           ~sfp_1_los_sync[1] &&
                           ~sfp_2_los_sync[1] &&
                           ~sfp_1_tx_fault_sync[1] &&
                           ~sfp_2_tx_fault_sync[1];

    assign led_g = ~sfp_status_ok;
    assign led_r = sfp_status_ok;
    assign sfp_1_led = ~sfp_1_present;
    assign sfp_2_led = ~sfp_2_present;

endmodule
