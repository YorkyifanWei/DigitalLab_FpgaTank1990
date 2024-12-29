`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/28 13:38:24
// Design Name: 
// Module Name: Counter
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


// 定义一个可参数化的计数器模块
// 该模块的计数范围可以通过MAX_VALUE参数进行配置
// 模块的频率默认为1Hz(当MAX_VALUE==32'd100_000_000时)
module Counter #(
    parameter   MAX_VALUE = 32'd100_000_000  // 计数器的最大值，默认为100,000,000
)(
    input   clk,  // 系统时钟
    input   rst,  // 复位信号，高电平有效
    output  pulse   // 输出信号，当计数器达到最大值时置高
);
// 定义一个32位的计数器寄存器，以支持最大的计数值
reg [31:0] cnt;
// 在每个时钟的上升沿执行计数逻辑
always @(posedge clk) begin
    // 如果复位信号有效，则将计数器清零
    if (rst)
        cnt <= 0;
    else begin
        // 如果计数器达到最大值，则重新开始计数
        if (cnt >= MAX_VALUE)
            cnt <= 0;
        else
            // 否则，计数器递增
            cnt <= cnt + 32'b1;
    end
end
// 当计数器达到最大值时，输出高电平
assign pulse = (cnt == MAX_VALUE);
endmodule
