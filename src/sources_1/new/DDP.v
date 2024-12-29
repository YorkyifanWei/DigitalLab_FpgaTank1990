`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/06 15:14:58
// Design Name: 
// Module Name: DDP
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


module PS#(
    parameter  WIDTH = 1
) (
    input   s,
    input   clk,
    output  p
);
reg temp1;
reg temp2;
always @(posedge clk) begin
    temp1 <= s;
    temp2 <= s & ~temp1;   // 上升沿检测
end
assign p = temp2;
endmodule
//实现DDP功能，将画布与显示屏适配，从而产生色彩信息。
//DDP和DST共同称为DU即显示单元
module DDP #(
    parameter DW    = 15,
    parameter H_LEN = 200,
    parameter V_LEN = 150
) (
    input               hen,    // 水平显示有效（horizontal enable）
    input               ven,    // 垂直显示有效（vertical enable）
    input               rstn,   // 复位信号，低电平有效
    input               pclk,   // 时钟信号
    input      [  11:0] rdata,  // 上一个像素对应的rgb数据。由查询画布VRAM得到。

    output reg [  11:0] rgb,    // 向DU模块输出的当前像素的rgb信息。
    output reg [DW-1:0] raddr   // 当前的像素在画布 VRAM 中的查询地址。
);

// 这四个变量仅用于计时，不表示实际的坐标。
reg [1:0] sx;   // 用于每4个pclk更新一次显示位置
reg [1:0] sy;
reg [1:0] nsx;
reg [1:0] nsy;


always @(*) begin
    sx = nsx;
    sy = nsy;
end

wire p;

// 取(hen&ven)的下降沿
PS #(1) ps(
    .s      (~(hen & ven)),
    .clk    (pclk),
    .p      (p)
);

always @(posedge pclk) begin
    if (!rstn) begin
        nsx   <= 0;
        nsy   <= 3;
        rgb   <= 0;
        raddr <= 0;
    end
    // 每4个pclk，更新一次显示位置
    else if (hen && ven) begin
        rgb <= rdata;
        if (sx == 2'b11) begin
            raddr <= raddr + 1;
        end
        nsx <= sx + 1;
    end
    // 每扫描4行，开始处理下一行地址内存
    else if (p) begin
        rgb <= 0;
        if (sy != 2'b11) begin
            raddr <= raddr - H_LEN;
        end
        else if (raddr == H_LEN * V_LEN) begin
            raddr <= 0;
        end
        nsy <= sy + 1;
    end
    else rgb <= 0;
end
endmodule
