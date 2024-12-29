`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/27 21:51:23
// Design Name: 
// Module Name: SegmentMask
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


/**
 * 模块名：SegmentMask
 * 功能描述：根据输出数据和输出有效信号生成数码管显示数据和位选信号
 * 
 * 输入端口：
 * - clk: 时钟信号
 * - rst: 复位信号
 * - output_data: 32位输出数据
 * - output_valid: 8位输出有效信号，指示哪些数码管应该显示
 * 
 * 输出端口：
 * - seg_data: 4位数码管显示数据
 * - seg_an: 3位数码管位选信号
 */
module SegmentMask(
    input               clk,
    input               rst,
    input      [31:0]   output_data,
    input      [ 7:0]   output_valid,
    output reg [ 7:0]   seg_data,
    output reg [ 7:0]   seg_an
);
reg [3:0] seg_data_reg;
reg [2:0] seg_an_reg;
// 计数器，用于产生数码管刷新的定时信号
reg [31:0] cnt;
// 数码管编号，指示当前应该显示的数码管
reg [2:0] seg_id;
// 在时钟上升沿处理数码管的刷新逻辑
always @(posedge clk) begin
    if (rst) begin
        // 复位时，将计数器和数码管编号清零
        cnt <= 0;
        seg_id <= 0;
    end
    else begin
        // 如果计数器达到阈值，切换到下一个数码管
        if (cnt >= 32'd250_000) begin
            if (seg_id == 3'd7)
                // 如果当前是最后一个数码管，回到第一个数码管
                seg_id <= 3'd0;
            else
                // 否则，切换到下一个数码管
                seg_id <= seg_id + 3'd1;
            // 重置计数器
            cnt <= 0;
        end
        else
            // 计数器递增
            cnt <= cnt + 32'b1;
    end
end
// 在时钟上升沿更新数码管显示数据
always @(posedge clk) begin
    // 根据数码管编号和对应的有效信号计算数码管位选信号
    seg_an_reg = seg_id * output_valid[seg_id];
    // 根据数码管位选信号选择相应的显示数据
    case (seg_an_reg)
        3'd0: seg_data_reg <= output_data[3:0];
        3'd1: seg_data_reg <= output_data[7:4];
        3'd2: seg_data_reg <= output_data[11:8];
        3'd3: seg_data_reg <= output_data[15:12];
        3'd4: seg_data_reg <= output_data[19:16];
        3'd5: seg_data_reg <= output_data[23:20];
        3'd6: seg_data_reg <= output_data[27:24];
        3'd7: seg_data_reg <= output_data[31:28];
    endcase
end
always @(*) begin
    case (seg_an_reg)
        3'd0: begin
            seg_an = 8'b1111_1110;
        end
        3'd1: begin
            seg_an = 8'b1111_1101;
        end
        3'd2: begin
            seg_an = 8'b1111_1011;
        end
        3'd3: begin
            seg_an = 8'b1111_0111;
        end
        3'd4: begin
            seg_an = 8'b1110_1111;
        end
        3'd5: begin
            seg_an = 8'b1101_1111;
        end
        3'd6: begin
            seg_an = 8'b1011_1111;
        end
        3'd7: begin
            seg_an = 8'b0111_1111;
        end
    endcase
    case (seg_data_reg)
        4'h0: begin
            seg_data = 8'b0100_0000;
        end
        4'h1: begin
            seg_data = 8'b0111_1001;
        end
        4'h2: begin
            seg_data = 8'b1010_0100;
        end
        4'h3: begin
            seg_data = 8'b0011_0000;
        end
        4'h4: begin
            seg_data = 8'b0001_1001;
        end
        4'h5: begin
            seg_data = 8'b0001_0010;
        end
        4'h6: begin
            seg_data = 8'b0000_0010;
        end
        4'h7: begin
            seg_data = 8'b0111_1000;
        end
        4'h8: begin
            seg_data = 8'b0000_0000;
        end
        4'h9: begin
            seg_data = 8'b0001_0000;
        end
        4'hA: begin
            seg_data = 8'b0000_1000;
        end
        4'hB: begin
            seg_data = 8'b0000_0011;
        end
        4'hC: begin
            seg_data = 8'b0100_0110;
        end
        4'hD: begin
            seg_data = 8'b0010_0001;
        end
        4'hE: begin
            seg_data = 8'b0000_0110;
        end
        4'hF: begin
            seg_data = 8'b0000_1110;
        end
    endcase
end
endmodule
