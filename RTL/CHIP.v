//============================================================//
// Digital IC Design 2025                                   //                                                        
// Final Project: FP_MUL                                    //
//============================================================//
`timescale 1ns/1ps

`include "/usr/chipware/CW_mult_pipe.v"
`include "/usr/chipware/CW_mult_seq.v"
`include "/usr/chipware/CW_mult.v"

module CHIP(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    input wire [7:0] DATA_IN,
    output reg [7:0] DATA_OUT,
    output reg READY
);

parameter latency = 47;

//==============================//
// Load Data
//==============================//

reg [3:0] indx_i;

always @(posedge CLK) begin
    if (RESET)
        indx_i <= 4'd0;
    else if (indx_i == 4'd15)
        indx_i <= 4'd0;
    else if (ENABLE)
        indx_i <= indx_i + 4'd1;
    else
        indx_i <= indx_i;
end

integer i, j;
reg [127:0] IMEM;

always @(posedge CLK) begin
    if (RESET) begin
        for (j = 0; j < 128; j = j + 1)
            IMEM[j] <= 0;
    end
    else if (ENABLE) begin
        for (i = 0; i < 8; i = i + 1)
            IMEM[8 * indx_i + i] <= DATA_IN[i];
    end
end

wire [63:0] in_1, in_2;

assign in_1 = IMEM[63:0];
assign in_2 = IMEM[127:64];

//==============================//
// Multiply
//==============================//
wire [63:0] OMEM;

// Signed
assign OMEM[63] = in_1[63] ^ in_2[63];

// Exponential
wire signed [12:0] e1, e2;

assign e1 = {2'd0, in_1[62:52]} + {2'd0, in_2[62:52]};
assign e2 = e1 - 13'd1023;

// Mantissa
reg start;
reg [10:0] count;
wire [105:0] m1;

always @(posedge CLK) begin
    if (RESET)
        start <= 1'b0;
    else if (count == 11'd1)
        start <= 1'b1;
    else
        start <= 1'b0;
end

CW_mult_seq #(
    .a_width(53),
    .b_width(53),
    .num_cyc(5'd5),
    .rst_mode('d1),
    .input_mode('d0),
    .output_mode('d1),
    .early_start('d0)
) C1 (
    .clk(CLK),
    .rst_n(!RESET),
    .hold(1'b0),
    .start(start),
    .a({1'b1, in_1[51:0]}),
    .b({1'b1, in_2[51:0]}),
    .product(m1)
);

assign OMEM[62:52] = (m1[105] && m1[52]) ? e2[10:0]+1 : e2[10:0];
assign OMEM[51:0]  = (m1[105] && m1[52]) ? m1[104:53] :
                     (!m1[105] && m1[51]) ? m1[103:52] :
                     m1[103:52];

//==============================//
// Output
//==============================//

always @(posedge CLK) begin
  if (RESET)
    count <= 'd0;
  else if (ENABLE)
    count <= 'd0;
  else if (count == (latency + 1))
    count <= count;
  else
    count <= count + 'd1;
end

reg [2:0] indx_o;
always @(posedge CLK) begin
  if (RESET)
    indx_o <= 'd0;
  else if (indx_o == 'd7)
    indx_o <= 'd0;
  else if (count < latency)
    indx_o <= 'd0;
  else
    indx_o <= indx_o + 'd1;
end

integer k;
always @(posedge CLK) begin
  if (RESET) begin
    DATA_OUT <= 'd0;
    READY <= 'd0;
  end
  else if (!ENABLE && (count >= latency)) begin
    for (k = 0; k < 8; k = k + 1)
      DATA_OUT[k] <= OMEM[indx_o * 8 + k];
    READY <= 'd1;
  end
  else
    READY <= 'd0;
end
