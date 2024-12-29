`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/05 15:21:06
// Design Name: 
// Module Name: DST
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


//任意数循环计数
module CntS #(
    parameter               WIDTH               = 16,
    parameter               RST_VLU             = 0
)(
    input                   [ 0 : 0]            clk,    // 时钟信号
    input                   [ 0 : 0]            rstn,   // 复位信号，低电平有效
    input                   [WIDTH-1:0]         d,      // 计数值（data）
    input                   [ 0 : 0]            ce,     // 计数使能信号（counter enable）

    output      reg         [WIDTH-1:0]         q       // 计数器输出
);
always @(posedge clk) begin
    if (!rstn)
        q <= RST_VLU;
    else if (ce) begin
        if (q == 0)
            q <= d;
        else
            q <= q - 1;
    end
    else
        q <= q;
end
endmodule


module DST (
    input       rstn,   // 复位信号，低电平有效
    input       pclk,   // 时钟信号

    output reg  hen,    // 水平显示有效（horizontal enable）
    output reg  ven,    // 垂直显示有效（vertical enable）
    output reg  hs,     // 行同步（horizontal sync）
    output reg  vs      // 场同步（vertical sync）
);

// 大小均为周期长度-1，因为计数器从0开始计数
localparam HSW_t = 119; // 行同步宽度（horizontal sync width）
localparam HBP_t = 63;  // 行开始前空白宽度（horizontal back porch width）
localparam HEN_t = 799; // 行显示有效宽度（horizontal enable width）
localparam HFP_t = 55;  // 行结束前空白宽度（horizontal front porch width）

localparam VSW_t = 5;   // 场同步宽度（vertical sync width）
localparam VBP_t = 22;  // 场开始前空白宽度（vertical back period width）
localparam VEN_t = 599; // 场显示有效宽度（vertical enable width）
localparam VFP_t = 36;  // 场结束前空白宽度（vertical front porch width）

// 行同步信号或场同步信号状态
localparam SW = 2'b00;  // 同步信号宽度（sync width）
localparam BP = 2'b01;  // 同步信号结束到有效数据的间隔（back porch width）
localparam EN = 2'b10;  // 显示有效区域（enable width）
localparam FP = 2'b11;  // 有效数据结束到下一同步信号的间隔（front porch width）

reg     [ 0 : 0]    ce_v;   // 场信号计数使能（counter enable__vertical）

reg     [ 1 : 0]    h_state;// 行同步信号状态（horizontal sync state）
reg     [ 1 : 0]    v_state;// 场同步信号状态（vertical sync state)

reg     [15 : 0]    d_h;    // 行计数器数据（horizontal counter data）
reg     [15 : 0]    d_v;    // 场计数器数据（vertical counter data*/)

wire    [15 : 0]    q_h;    // 行计数器输出（horizontal counter output）
wire    [15 : 0]    q_v;    // 场计数器输出（vertical counter output）

// 每个时钟周期计数器增加1，表示扫描一个像素
CntS #(16, HSW_t) hcnt(
    .clk    (pclk),
    .rstn   (rstn),
    .d      (d_h),
    .ce     (1'b1),

    .q      (q_h)
);

// 每行扫描完计数器增加1，表示切换到扫描下一行
CntS #(16, VSW_t) vcnt(
    .clk    (pclk),
    .rstn   (rstn),
    .d      (d_v),
    .ce     (ce_v),

    .q      (q_v)
);

// 根据状态分配计数器数据
always @(*) begin
    case (h_state)
        SW: begin
            d_h = HBP_t;  hs = 1; hen = 0;
        end
        BP: begin
            d_h = HEN_t;  hs = 0; hen = 0;
        end
        EN: begin
            d_h = HFP_t;  hs = 0; hen = 1;
        end
        FP: begin
            d_h = HSW_t;  hs = 0; hen = 0;
        end
    endcase
    case (v_state)
        SW: begin
            d_v = VBP_t;  vs = 1; ven = 0;
        end
        BP: begin
            d_v = VEN_t;  vs = 0; ven = 0;
        end
        EN: begin
            d_v = VFP_t;  vs = 0; ven = 1;
        end
        FP: begin
            d_v = VSW_t;  vs = 0; ven = 0;
        end
    endcase
end

always @(posedge pclk) begin
    if (!rstn) begin
        h_state <= SW; v_state <= SW; ce_v <= 1'b0;
    end
    else begin
        if (q_h == 0) begin
            h_state <= h_state + 2'b01;
            if (h_state == FP) begin
                ce_v <= 0;
                if (q_v == 0)
                    v_state <= v_state + 2'b01;
            end
            else
                ce_v <= 0;
        end
        else if (q_h == 1) begin
            if(h_state == FP)
                ce_v <= 1;
            else
                ce_v <= 0;
        end
        else ce_v <= 0;
    end
end
endmodule
