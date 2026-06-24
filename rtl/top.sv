`timescale 1ns/1ps

module top (
    input  wire       clk_100mhz_p,
    input  wire       clk_100mhz_n,
    output wire [1:0] led
);
    wire clk_ibuf;
    wire clk;
    wire [1:0] led_on;
    logic [7:0] pwm_counter = '0;
    logic [7:0] brightness = '0;
    logic [19:0] fade_counter = '0;
    logic fade_up = 1'b1;

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
        pwm_counter <= pwm_counter + 1'b1;

        fade_counter <= fade_counter + 1'b1;
        if (fade_counter == '0) begin
            if (fade_up) begin
                brightness <= brightness + 1'b1;
                if (brightness == 8'hFE) begin
                    fade_up <= 1'b0;
                end
            end else begin
                brightness <= brightness - 1'b1;
                if (brightness == 8'h01) begin
                    fade_up <= 1'b1;
                end
            end
        end
    end

    assign led_on[0] = pwm_counter < brightness;
    assign led_on[1] = pwm_counter < ~brightness;

    assign led = ~led_on;

endmodule
