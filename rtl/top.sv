`timescale 1ns/1ps

module top (
    input  wire       clk_100mhz_p,
    input  wire       clk_100mhz_n,

    input  wire       sfp_mgt_clk_p,
    input  wire       sfp_mgt_clk_n,

    output wire       sfp_1_txp,
    output wire       sfp_1_txn,
    input  wire       sfp_1_rxp,
    input  wire       sfp_1_rxn,

    output wire       sfp_2_txp,
    output wire       sfp_2_txn,
    input  wire       sfp_2_rxp,
    input  wire       sfp_2_rxn,

    input  wire       SFP_1_MOD_DEF_0,
    input  wire       SFP_1_TX_FAULT,
    input  wire       SFP_1_LOS,
    output wire       SFP_1_LED,

    input  wire       SFP_2_MOD_DEF_0,
    input  wire       SFP_2_TX_FAULT,
    input  wire       SFP_2_LOS,
    output wire       SFP_2_LED,

    output wire [1:0] led
);
    wire clk_ibuf;
    wire clk;
    wire sfp_1_link_ok;
    wire sfp_2_link_ok;
    wire sfp_1_present;
    wire sfp_2_present;
    wire sfp_1_local_fault;
    wire sfp_2_local_fault;
    wire sfp_1_good;
    wire sfp_2_good;
    wire any_sfp_present;
    wire both_sfp_good;
    wire any_sfp_bad;
    wire [1:0] rx_prbs_locked;
    wire [1:0] rx_prbs_error_latched;
    wire tx_reset_done;
    wire rx_reset_done;
    logic [23:0] startup_reset_counter = '0;
    logic startup_reset = 1'b1;

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
        if (!startup_reset_counter[23]) begin
            startup_reset_counter <= startup_reset_counter + 1'b1;
        end
        startup_reset <= !startup_reset_counter[23];
    end

    sfp_prbs_test u_sfp_prbs_test (
        .clk_100mhz(clk),
        .reset(startup_reset),
        .sfp_mgt_clk_p(sfp_mgt_clk_p),
        .sfp_mgt_clk_n(sfp_mgt_clk_n),
        .sfp_1_txp(sfp_1_txp),
        .sfp_1_txn(sfp_1_txn),
        .sfp_1_rxp(sfp_1_rxp),
        .sfp_1_rxn(sfp_1_rxn),
        .sfp_2_txp(sfp_2_txp),
        .sfp_2_txn(sfp_2_txn),
        .sfp_2_rxp(sfp_2_rxp),
        .sfp_2_rxn(sfp_2_rxn),
        .sfp_1_link_ok(sfp_1_link_ok),
        .sfp_2_link_ok(sfp_2_link_ok),
        .rx_prbs_locked(rx_prbs_locked),
        .rx_prbs_error_latched(rx_prbs_error_latched),
        .tx_reset_done(tx_reset_done),
        .rx_reset_done(rx_reset_done)
    );

    assign sfp_1_present = !SFP_1_MOD_DEF_0;
    assign sfp_2_present = !SFP_2_MOD_DEF_0;
    assign sfp_1_local_fault = SFP_1_TX_FAULT || SFP_1_LOS;
    assign sfp_2_local_fault = SFP_2_TX_FAULT || SFP_2_LOS;

    assign sfp_1_good = sfp_1_present && !sfp_1_local_fault && sfp_1_link_ok;
    assign sfp_2_good = sfp_2_present && !sfp_2_local_fault && sfp_2_link_ok;
    assign any_sfp_present = sfp_1_present || sfp_2_present;
    assign both_sfp_good = sfp_1_good && sfp_2_good;
    assign any_sfp_bad = any_sfp_present && !both_sfp_good;

    assign SFP_1_LED = !sfp_1_good;
    assign SFP_2_LED = !sfp_2_good;

    assign led[0] = !any_sfp_bad;
    assign led[1] = !both_sfp_good;

    wire unused_status = |{rx_prbs_locked, rx_prbs_error_latched, tx_reset_done, rx_reset_done};

endmodule
