`timescale 1ns/1ps

module ibert_top (
    input  wire clk_100mhz_p,
    input  wire clk_100mhz_n,

    input  wire sfp_mgt_clk_p,
    input  wire sfp_mgt_clk_n,

    output wire sfp_1_txp,
    output wire sfp_1_txn,
    input  wire sfp_1_rxp,
    input  wire sfp_1_rxn,

    output wire sfp_2_txp,
    output wire sfp_2_txn,
    input  wire sfp_2_rxp,
    input  wire sfp_2_rxn
);
    wire sysclk_ibuf;
    wire sysclk;
    wire sfp_mgt_refclk;
    wire sfp_mgt_refclk_odiv2;

    wire [3:0] ibert_txp;
    wire [3:0] ibert_txn;
    wire [3:0] ibert_rxp;
    wire [3:0] ibert_rxn;

    IBUFDS #(
        .DIFF_TERM("TRUE"),
        .IOSTANDARD("LVDS")
    ) u_sysclk_ibufds (
        .I(clk_100mhz_p),
        .IB(clk_100mhz_n),
        .O(sysclk_ibuf)
    );

    BUFG u_sysclk_bufg (
        .I(sysclk_ibuf),
        .O(sysclk)
    );

    IBUFDS_GTE4 u_sfp_mgt_refclk_ibufds (
        .I(sfp_mgt_clk_p),
        .IB(sfp_mgt_clk_n),
        .CEB(1'b0),
        .O(sfp_mgt_refclk),
        .ODIV2(sfp_mgt_refclk_odiv2)
    );

    assign sfp_1_txp = ibert_txp[3];
    assign sfp_1_txn = ibert_txn[3];
    assign sfp_2_txp = ibert_txp[2];
    assign sfp_2_txn = ibert_txn[2];

    assign ibert_rxp = {sfp_1_rxp, sfp_2_rxp, 2'b00};
    assign ibert_rxn = {sfp_1_rxn, sfp_2_rxn, 2'b00};

    ibert_ultrascale_gty_1 u_ibert (
        .txn_o(ibert_txn),
        .txp_o(ibert_txp),
        .rxn_i(ibert_rxn),
        .rxp_i(ibert_rxp),
        .gtrefclk0_i(sfp_mgt_refclk),
        .gtrefclk1_i(1'b0),
        .gtnorthrefclk0_i(1'b0),
        .gtnorthrefclk1_i(1'b0),
        .gtsouthrefclk0_i(1'b0),
        .gtsouthrefclk1_i(1'b0),
        .gtrefclk00_i(sfp_mgt_refclk),
        .gtrefclk10_i(1'b0),
        .gtrefclk01_i(1'b0),
        .gtrefclk11_i(1'b0),
        .gtnorthrefclk00_i(1'b0),
        .gtnorthrefclk10_i(1'b0),
        .gtnorthrefclk01_i(1'b0),
        .gtnorthrefclk11_i(1'b0),
        .gtsouthrefclk00_i(1'b0),
        .gtsouthrefclk10_i(1'b0),
        .gtsouthrefclk01_i(1'b0),
        .gtsouthrefclk11_i(1'b0),
        .clk(sysclk)
    );

endmodule
