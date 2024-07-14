`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2024 01:02:27 PM
// Design Name: 
// Module Name: spi-core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi (
    input logic clk, reset,
    input logic [7:0] din,
    input logic [15:0] dvsr,                        // clock divisor
    input logic start, cpol, cpha,
    output logic [7:0] dout,
    output logic spi_done_tick, ready,
    output logic sclk,
    input logic miso,
    output logic mosi
);

// FSM state type
typedef enum {idle, cpha_delay, p0, p1} state_type;

// declaration
state_type state_reg, state_next;
logic p_clk;
logic [15:0] c_reg, c_next;
logic spi_clk_reg, ready_i, spi_done_tick_i;
logic spi_clk_next;
logic [2:0] n_reg, n_next;
logic [7:0] si_reg, si_next;
logic [7:0] so_reg, so_next;

// body
// FSMD for transmitting one byte
// register

always_ff @(posedge clk or posedge reset)
    if (reset) begin
        state_reg <= idle;
        si_reg <= 0;
        so_reg <= 0;
        n_reg <= 0;
        c_reg <= 0;
        spi_clk_reg <= 0;
    end
    else begin
        state_reg <= state_reg;
        ready_i <= 0;
        spi_done_tick_i <= 0;
        si_reg <= si_next;
        so_reg <= so_next;
        n_reg <= n_next;
        c_reg <= c_next;
        spi_clk_reg <= spi_clk_next;
    end

// Next state logic

always_comb
begin
    state_next = state_reg; //default state: the same
    ready_i = 0;
    spi_done_tick_i = 0;
    si_next = si_reg;
    n_next = n_reg;
    c_next = c_reg;

    case(state_reg)
        idle: begin
            ready_i = 1;
            if (start) begin
                so_next = din;
                n_next = 0;
                c_next = 0;
                if (cpha)
                    state_next = cpha_delay;
                else
                    state_next = p0;
            end
        end

        cpha_delay: begin
            if (c_reg == dvsr) begin
                state_next = p0;
                c_next = 0;
            end
        end
        
        p0: begin
            if (c_reg == dvsr) begin    // slck 0-to-1
                state_next = p1;
                si_next = {si_reg[6:0], miso};
                c_next = 0;
            end
            else
                c_next = c_reg + 1;
        end

        p1: begin
            if (c_reg == dvsr)
                if (n_reg == 7) begin
                    spi_done_tick_i = 1;
                    state_next = idle;
                end
                else begin
                    so_next = {so_reg[6:0], 1'b0};
                    state_next = p0;
                    n_next = n_reg + 1;
                    c_next = 0;
                end
            else
                c_next = c_reg + 1;
        end
    endcase
end

assign ready = ready_i;
assign spi_done_tick = spi_done_tick_i;

// lookahead output decoding
assign p_clk = (state_next == p1 && ~cpha) || (state_next == p0 && cpha);
assign spi_clk_next = (cpol) ? ~p_clk : p_clk;

// output
assign dout = si_reg;
assign mosi = so_reg[7];
assign sclk = spi_clk_reg;

endmodule

