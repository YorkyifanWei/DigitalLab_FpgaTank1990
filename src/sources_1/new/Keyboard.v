`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/27 09:28:30
// Design Name: 
// Module Name: Keyboard
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


module Keyboard(
    input           clk,
    input           rstn,
    input           kclk,
    input           kdata,

    output [7:0]    key_data,
    output          key_valid,
    output          key_sp
);
reg [3:0] kclk_filter, kdata_filter;
reg kclk_high, kdata_high;
reg [9:0] buffer;
reg [3:0] counter;
reg is_special;
reg is_free;
reg is_valid;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        kclk_filter <= 4'b1111;
        kdata_filter <= 4'b1111;
        kclk_high <= 1;
        kdata_high <= 1;
    end
    else begin
        kclk_filter <= {kclk, kclk_filter[3:1]};
        kdata_filter <= {kdata, kdata_filter[3:1]};
        if (kclk_filter == 4'b1111)
            kclk_high <= 1;
        else if (kclk_filter == 4'b0000)
            kclk_high <= 0;
        if (kdata_filter == 4'b1111)
            kdata_high <= 1;
        else if (kdata_filter == 4'b0000)
            kdata_high <= 0;
    end
end

always @(negedge kclk_high or negedge rstn) begin
    if (!rstn) begin
        buffer <= 8'b0;
        counter <= 4'b0;
        is_free <= 0;
        is_special <= 0;
        is_valid <= 0;
    end
    else begin
        buffer <= {kdata_high, buffer[9:1]};
        if (counter == 10) begin
            case (buffer[8:1])
                8'hF0: is_free <= 1;
                8'hE0: is_special <= 1;
                default: is_valid <= 1;
            endcase
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
            if (is_valid) begin
                is_free <= 0;
                is_special <= 0;
                is_valid <= 0;
            end
        end
    end
end

assign key_data = buffer[8:1];
assign key_valid = is_valid & ~is_free;
assign key_sp = is_special;

endmodule
