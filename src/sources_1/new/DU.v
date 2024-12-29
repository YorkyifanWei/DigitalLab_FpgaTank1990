`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/06 15:14:40
// Design Name: 
// Module Name: DU
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


module DU #(
    parameter DW    = 15,
    parameter H_LEN = 200,
    parameter V_LEN = 150
) (
    input               pclk,   // 时钟信号
    input               rstn,   // 复位信号，低电平有效
    input      [  11:0] rdata,  // 上一个像素对应的rgb数据。由查询画布VRAM得到。

    output     [DW-1:0] raddr,  // 当前的像素在画布VRAM中的查询地址
    output     [  11:0] rgb,    // 输出当前像素的rgb信息
    output              hs,     // 行同步（horizontal sync）
    output              vs      // 场同步（vertical sync）
);
wire hen, ven;
DDP #(DW, H_LEN, V_LEN) ddp(
    .hen(hen),
    .ven(ven),
    .rstn(rstn),
    .pclk(pclk),
    .rdata(rdata),

    .rgb(rgb),
    .raddr(raddr)
);
DST dst(
    .rstn(rstn),
    .pclk(pclk),

    .hen(hen),
    .ven(ven),
    .hs(hs),
    .vs(vs)
);
endmodule
