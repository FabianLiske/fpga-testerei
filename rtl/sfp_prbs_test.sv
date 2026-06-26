`timescale 1ns/1ps

module sfp_prbs_test (
    input  wire       clk_100mhz,
    input  wire       reset,

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

    output wire       sfp_1_link_ok,
    output wire       sfp_2_link_ok,
    output wire [1:0] rx_prbs_locked,
    output wire [1:0] rx_prbs_error_latched,
    output wire       tx_reset_done,
    output wire       rx_reset_done
);
    localparam [3:0] PRBS31 = 4'b0101;

    wire       gtrefclk00;
    wire       gtrefclk00_odiv2;
    wire [0:0] gtwiz_userclk_tx_reset;
    wire [0:0] gtwiz_userclk_rx_reset;
    wire [0:0] gtwiz_userclk_tx_usrclk2;
    wire [0:0] gtwiz_userclk_rx_usrclk2;
    wire [0:0] gtwiz_userclk_tx_active;
    wire [0:0] gtwiz_userclk_rx_active;
    wire [0:0] gtwiz_reset_tx_done;
    wire [0:0] gtwiz_reset_rx_done;
    wire [1:0] gtpowergood;
    wire [1:0] rxpmaresetdone;
    wire [1:0] txpmaresetdone;
    wire [1:0] rxprbserr;
    wire [1:0] rxprbslocked;
    wire [1:0] rx_error_latched_rxclk;
    wire [1:0] rx_error_latched_clk;
    wire [1:0] rxprbslocked_clk;
    wire [1:0] gtpowergood_clk;
    wire [1:0] rxpmaresetdone_clk;
    wire [1:0] txpmaresetdone_clk;
    wire       tx_userclk_active_clk;
    wire       rx_userclk_active_clk;
    wire [1:0] gtyrxp;
    wire [1:0] gtyrxn;
    wire [1:0] gtytxp;
    wire [1:0] gtytxn;

    logic [1:0] rx_error_latched = 2'b00;
    logic [1:0] rx_error_sync_0 = 2'b00;
    logic [1:0] rx_error_sync_1 = 2'b00;
    logic [1:0] rx_lock_sync_0 = 2'b00;
    logic [1:0] rx_lock_sync_1 = 2'b00;
    logic [1:0] powergood_sync_0 = 2'b00;
    logic [1:0] powergood_sync_1 = 2'b00;
    logic [1:0] rxpmaresetdone_sync_0 = 2'b00;
    logic [1:0] rxpmaresetdone_sync_1 = 2'b00;
    logic [1:0] txpmaresetdone_sync_0 = 2'b00;
    logic [1:0] txpmaresetdone_sync_1 = 2'b00;
    logic       tx_done_sync_0 = 1'b0;
    logic       tx_done_sync_1 = 1'b0;
    logic       rx_done_sync_0 = 1'b0;
    logic       rx_done_sync_1 = 1'b0;
    logic       tx_active_sync_0 = 1'b0;
    logic       tx_active_sync_1 = 1'b0;
    logic       rx_active_sync_0 = 1'b0;
    logic       rx_active_sync_1 = 1'b0;

    IBUFDS_GTE4 #(
        .REFCLK_EN_TX_PATH(1'b0),
        .REFCLK_HROW_CK_SEL(2'b00),
        .REFCLK_ICNTL_RX(2'b00)
    ) u_sfp_mgt_refclk (
        .I(sfp_mgt_clk_p),
        .IB(sfp_mgt_clk_n),
        .CEB(1'b0),
        .O(gtrefclk00),
        .ODIV2(gtrefclk00_odiv2)
    );

    assign gtwiz_userclk_tx_reset = {reset};
    assign gtwiz_userclk_rx_reset = {reset};

    // Wizard lane 0 is GTYE4_CHANNEL_X0Y14 (SFP2), lane 1 is X0Y15 (SFP1).
    assign gtyrxp = {sfp_1_rxp, sfp_2_rxp};
    assign gtyrxn = {sfp_1_rxn, sfp_2_rxn};
    assign sfp_2_txp = gtytxp[0];
    assign sfp_2_txn = gtytxn[0];
    assign sfp_1_txp = gtytxp[1];
    assign sfp_1_txn = gtytxn[1];

    sfp_gty_10g_prbs u_gt (
        .gtwiz_userclk_tx_reset_in(gtwiz_userclk_tx_reset),
        .gtwiz_userclk_tx_srcclk_out(),
        .gtwiz_userclk_tx_usrclk_out(),
        .gtwiz_userclk_tx_usrclk2_out(gtwiz_userclk_tx_usrclk2),
        .gtwiz_userclk_tx_active_out(gtwiz_userclk_tx_active),
        .gtwiz_userclk_rx_reset_in(gtwiz_userclk_rx_reset),
        .gtwiz_userclk_rx_srcclk_out(),
        .gtwiz_userclk_rx_usrclk_out(),
        .gtwiz_userclk_rx_usrclk2_out(gtwiz_userclk_rx_usrclk2),
        .gtwiz_userclk_rx_active_out(gtwiz_userclk_rx_active),
        .gtwiz_reset_clk_freerun_in({clk_100mhz}),
        .gtwiz_reset_all_in({reset}),
        .gtwiz_reset_tx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_tx_datapath_in(1'b0),
        .gtwiz_reset_rx_pll_and_datapath_in(1'b0),
        .gtwiz_reset_rx_datapath_in(1'b0),
        .gtwiz_reset_rx_cdr_stable_out(),
        .gtwiz_reset_tx_done_out(gtwiz_reset_tx_done),
        .gtwiz_reset_rx_done_out(gtwiz_reset_rx_done),
        .gtwiz_userdata_tx_in(64'h0),
        .gtwiz_userdata_rx_out(),
        .gtrefclk00_in({gtrefclk00}),
        .qpll0outclk_out(),
        .qpll0outrefclk_out(),
        .gtyrxn_in(gtyrxn),
        .gtyrxp_in(gtyrxp),
        .loopback_in(6'b000000),
        .rxprbscntreset_in(reset ? 2'b11 : 2'b00),
        .rxprbssel_in({PRBS31, PRBS31}),
        .txprbsforceerr_in(2'b00),
        .txprbssel_in({PRBS31, PRBS31}),
        .gtpowergood_out(gtpowergood),
        .gtytxn_out(gtytxn),
        .gtytxp_out(gtytxp),
        .rxpmaresetdone_out(rxpmaresetdone),
        .rxprbserr_out(rxprbserr),
        .rxprbslocked_out(rxprbslocked),
        .txpmaresetdone_out(txpmaresetdone)
    );

    always_ff @(posedge gtwiz_userclk_rx_usrclk2[0] or posedge reset) begin
        if (reset) begin
            rx_error_latched <= 2'b00;
        end else begin
            rx_error_latched <= rx_error_latched | rxprbserr;
        end
    end

    always_ff @(posedge clk_100mhz) begin
        rx_error_sync_0 <= rx_error_latched_rxclk;
        rx_error_sync_1 <= rx_error_sync_0;

        rx_lock_sync_0 <= rxprbslocked;
        rx_lock_sync_1 <= rx_lock_sync_0;

        powergood_sync_0 <= gtpowergood;
        powergood_sync_1 <= powergood_sync_0;

        rxpmaresetdone_sync_0 <= rxpmaresetdone;
        rxpmaresetdone_sync_1 <= rxpmaresetdone_sync_0;

        txpmaresetdone_sync_0 <= txpmaresetdone;
        txpmaresetdone_sync_1 <= txpmaresetdone_sync_0;

        tx_done_sync_0 <= gtwiz_reset_tx_done[0];
        tx_done_sync_1 <= tx_done_sync_0;

        rx_done_sync_0 <= gtwiz_reset_rx_done[0];
        rx_done_sync_1 <= rx_done_sync_0;

        tx_active_sync_0 <= gtwiz_userclk_tx_active[0];
        tx_active_sync_1 <= tx_active_sync_0;

        rx_active_sync_0 <= gtwiz_userclk_rx_active[0];
        rx_active_sync_1 <= rx_active_sync_0;
    end

    assign rx_error_latched_rxclk = rx_error_latched;
    assign rx_error_latched_clk = rx_error_sync_1;
    assign rxprbslocked_clk = rx_lock_sync_1;
    assign gtpowergood_clk = powergood_sync_1;
    assign rxpmaresetdone_clk = rxpmaresetdone_sync_1;
    assign txpmaresetdone_clk = txpmaresetdone_sync_1;

    assign tx_reset_done = tx_done_sync_1;
    assign rx_reset_done = rx_done_sync_1;
    assign tx_userclk_active_clk = tx_active_sync_1;
    assign rx_userclk_active_clk = rx_active_sync_1;
    assign rx_prbs_locked = rxprbslocked_clk;
    assign rx_prbs_error_latched = rx_error_latched_clk;

    assign sfp_2_link_ok = tx_reset_done &&
                           rx_reset_done &&
                           tx_userclk_active_clk &&
                           rx_userclk_active_clk &&
                           gtpowergood_clk[0] &&
                           txpmaresetdone_clk[0] &&
                           rxpmaresetdone_clk[0] &&
                           rxprbslocked_clk[0] &&
                           !rx_error_latched_clk[0];

    assign sfp_1_link_ok = tx_reset_done &&
                           rx_reset_done &&
                           tx_userclk_active_clk &&
                           rx_userclk_active_clk &&
                           gtpowergood_clk[1] &&
                           txpmaresetdone_clk[1] &&
                           rxpmaresetdone_clk[1] &&
                           rxprbslocked_clk[1] &&
                           !rx_error_latched_clk[1];

    wire unused_gtrefclk00_odiv2 = gtrefclk00_odiv2;

endmodule
