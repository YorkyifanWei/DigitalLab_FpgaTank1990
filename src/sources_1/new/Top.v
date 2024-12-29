`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/11 08:46:25
// Design Name: 
// Module Name: Top
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


module Top(
    input           clk,
    input           rstn,
    input           kclk,
    input           kdata,

    output          hs,
    output          vs,
    output [3:0]    VGA_R,
    output [3:0]    VGA_G,
    output [3:0]    VGA_B,

    output [7:0]    seg_data,
    output [7:0]    seg_an
);
wire [11:0] rdata;
wire [14:0] raddr;
wire [7:0] key_data;
wire key_valid;
wire key_sp;
reg [7:0] key_data_reg;
pclk_generator pCLK (
    .reset(~rstn),
    .clk_in1(clk),
    .pclk(pclk),
    .locked()
);
DU #(15, 200, 150) du(
    .pclk(pclk),
    .rstn(rstn),
    .rdata(rdata),
    .raddr(raddr),
    .rgb({VGA_R, VGA_G, VGA_B}),
    .hs(hs),
    .vs(vs)
);
VRAM #(15) vram(
    .clk(clk),
    .rstn(rstn),

    .key_data(key_data),
    .key_valid(key_valid),
    .key_sp(key_sp),

    .pclk(pclk),
    .raddr(raddr),
    .rdata(rdata)
);
Keyboard keyboard(
    .clk(clk),
    .rstn(rstn),
    .kclk(kclk),
    .kdata(kdata),

    .key_data(key_data),
    .key_valid(key_valid),
    .key_sp(key_sp)
);
SegmentMask segmentMask(
    .clk(clk),
    .rst(!rstn),
    .output_data({24'b0, key_data_reg}),
    .output_valid(8'b0000_0011),
    .seg_data(seg_data),
    .seg_an(seg_an)
);
always @(posedge clk) begin
    if (!rstn) begin
        key_data_reg <= 8'b0;
    end
    else if (key_valid) begin
        key_data_reg <= key_data;
    end
end
endmodule
