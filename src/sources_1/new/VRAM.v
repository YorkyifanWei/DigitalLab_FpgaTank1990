`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/18 16:03:27
// Design Name: 
// Module Name: VRAM
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


module VRAM #(
    parameter DW = 15
) (
    // 全局时钟与复位信号
    input           clk,
    input           rstn,

    // 来自键盘的输入
    input [ 7 : 0 ] key_data,
    input           key_valid,
    input           key_sp,

    // 与DU交互的画面信号
    input           pclk,
    input  [DW-1:0] raddr,
    output reg [  11:0] rdata
);
// VRAM中的全局变量
// 0:开始 1:游戏中 2:游戏暂停 3:胜利结算
reg [1:0] game_state;
// 0:空地 1:红墙 2:绿墙 3:白墙 4:ytank 5:jtank 6:子弹 7:生命
reg [2:0] game_board [0:18][0:24];
// <=3:无子弹 4:↑ 5:← 6:↓ 7:→
reg [2:0] bullet_board [0:18][0:24];
// 0:↑ 1:← 2:↓ 3:→
reg [1:0] direct_ytank;
reg [1:0] direct_jtank;
reg [5:0] score_ytank;
reg [5:0] score_jtank;

// 游戏逻辑部分
// 游戏状态参数
// 0:开始 1:游戏中 2:游戏暂停 3:胜利结算
localparam START   = 2'b00;
localparam RUNNING = 2'b01;
localparam PAUSE   = 2'b10;
localparam WINNING = 2'b11;
// 选取的游戏棋盘序号(1~8)
reg [2:0] game_board_serial;
// 分数上限
localparam SCORE_LIMIT = 6'd8;
// ytank与jtank的位置
reg [4:0] ytank_x;
reg [4:0] ytank_y;
reg [4:0] jtank_x;
reg [4:0] jtank_y;
// 子弹飞行后的状态
reg [2:0] bullet_board_temp [0:18][0:24];
// 是否处理按键输入
reg key_flag;

// 制造在Game逻辑模块中使用的时钟信号gclk
// gclk的频率为100Hz
wire pulse;
reg gclk;
Counter #(32'd5_000_000) gclk_generator(
    .clk(clk),
    .rst(~rstn),
    .pulse(pulse)
);
always @(posedge clk) begin
    if (!rstn) begin
        gclk <= 0;
    end else begin
        gclk <= pulse ^ gclk;
    end
end

integer i, j;
reg [2:0] game_board_1 [0:18][0:24];
// reg [1425:0] game_board_1_data = {
//     75'o0001111111111111111111000,
//     75'o0001001000222000033001000,
//     75'o0001000000220000000001000,
//     75'o0001000033000000001001000,
//     75'o0001001000111000222001000,
//     75'o0001111000000000031001000,
//     75'o0001001111000000033001000,
//     75'o0001000000000000000001000,
//     75'o0001000000000000000001000,
//     75'o0001222222220000000001000,
//     75'o0001003300000000000001000,
//     75'o0001000000000000000001000,
//     75'o0001000000000000000001000,
//     75'o0001000000220000111131000,
//     75'o0001000000220000000001000,
//     75'o0001222000000000000001000,
//     75'o0001000110000033332221000,
//     75'o0001000000000000000001000,
//     75'o0001111111111111111111000
// };
reg [2:0] game_board_2 [0:18][0:24];
// reg [1425:0] game_board_2_data = {
//     75'o0001111111111111111111000,
//     75'o0001000000100012200041000,
//     75'o0001010301000012001121000,
//     75'o0001010301010012001121000,
//     75'o0001010001030112000121000,
//     75'o0001000013010013000221000,
//     75'o0001111000212000001111000,
//     75'o0001000001222100000001000,
//     75'o0001311001222100101131000,
//     75'o0001333000222001110031000,
//     75'o0001000001020100000001000,
//     75'o0001010001000100000001000,
//     75'o0001011050101000001121000,
//     75'o0001001000111000022221000,
//     75'o0001001000121000012221000,
//     75'o0001001000121000000221000,
//     75'o0001222330113002300021000,
//     75'o0001113322200022220011000,
//     75'o0001111111111111111111000
// }
always @(posedge gclk or negedge rstn) begin
    // 在复位时执行初始化
    if (!rstn) begin
        game_state <= 2'b0;
        direct_ytank <= 2'b0;
        direct_jtank <= 2'b0;
        score_ytank <= 6'b0;
        score_jtank <= 6'b0;
        game_board_serial <= 3'b0;
        ytank_x <= 0;
        ytank_y <= 0;
        jtank_x <= 0;
        jtank_y <= 0;
        key_flag <= 0;
        for (i = 0; i < 19; i = i + 1) begin
            for (j = 0; j < 25; j = j + 1) begin
                if ((i == 0 || i == 18) && (3 < j && j < 21)) begin
                    game_board_1[i][j] = 1;
                    game_board_2[i][j] = 1;
                end
                else if (j == 21 || j == 3) begin
                    game_board_1[i][j] = 1;
                    game_board_2[i][j] = 1;
                end
                else begin
                    game_board_1[i][j] = 0;
                    game_board_2[i][j] = 0;
                end
                game_board[i][j] <= 3'b0;
                bullet_board[i][j] <= 3'b0;
            end
        end
        //*****图一*****//
        game_board_1[ 1][ 3] = 1;
        game_board_1[ 1][ 4] = 1;
        game_board_1[ 1][ 7] = 2;
        game_board_1[ 1][ 8] = 2;
        game_board_1[ 1][ 9] = 2;
        game_board_1[ 1][20] = 3;
        game_board_1[ 2][ 3] = 1;
        game_board_1[ 2][ 7] = 2;
        game_board_1[ 2][ 8] = 2;
        game_board_1[ 2][19] = 3;
        game_board_1[ 3][ 3] = 1;
        game_board_1[ 3][ 7] = 2;
        game_board_1[ 3][ 8] = 2;
        game_board_1[ 4][ 4] = 1;
        game_board_1[ 4][ 7] = 2;
        game_board_1[ 4][ 8] = 2;
        game_board_1[ 4][12] = 4;
        game_board_1[ 4][15] = 3;
        game_board_1[ 4][16] = 3;
        game_board_1[ 5][15] = 3;
        game_board_1[ 5][16] = 3;
        game_board_1[ 6][ 8] = 2;
        game_board_1[ 6][ 9] = 3;
        game_board_1[ 6][10] = 3;
        game_board_1[ 7][ 3] = 1;
        game_board_1[ 7][ 4] = 1;
        game_board_1[ 7][13] = 2;
        game_board_1[ 7][14] = 2;
        game_board_1[ 8][13] = 2;
        game_board_1[ 8][14] = 2;
        game_board_1[12][ 4] = 3;
        game_board_1[12][ 5] = 3;
        game_board_1[13][ 4] = 3;
        game_board_1[13][ 5] = 3;
        game_board_1[14][16] = 5;
        game_board_1[15][ 7] = 2;
        game_board_1[15][ 8] = 2;
        game_board_1[15][18] = 1;
        game_board_1[15][19] = 1;
        game_board_1[15][20] = 1;
        game_board_1[16][14] = 3;
        game_board_1[16][15] = 3;
        game_board_1[17][15] = 3;
        game_board_1[17][16] = 3;
        //*****图二*****//
        game_board_2[ 1][10] = 1;
        game_board_2[ 1][14] = 1;
        game_board_2[ 1][15] = 2;
        game_board_2[ 1][16] = 2;
        game_board_2[ 1][20] = 4;
        game_board_2[ 2][ 5] = 1;
        game_board_2[ 2][ 7] = 3;
        game_board_2[ 2][ 9] = 1;
        game_board_2[ 2][14] = 1;
        game_board_2[ 2][15] = 2;
        game_board_2[ 2][18] = 1;
        game_board_2[ 2][19] = 1;
        game_board_2[ 2][20] = 2;
        game_board_2[ 3][ 5] = 1;
        game_board_2[ 3][ 7] = 3;
        game_board_2[ 3][ 9] = 1;
        game_board_2[ 3][11] = 1;
        game_board_2[ 3][14] = 1;
        game_board_2[ 3][15] = 2;
        game_board_2[ 3][18] = 1;
        game_board_2[ 3][19] = 1;
        game_board_2[ 3][20] = 2;
        game_board_2[ 4][ 5] = 1;
        game_board_2[ 4][ 9] = 1;
        game_board_2[ 4][11] = 3;
        game_board_2[ 4][13] = 1;
        game_board_2[ 4][14] = 1;
        game_board_2[ 4][15] = 2;
        game_board_2[ 4][19] = 1;
        game_board_2[ 4][20] = 2;
        game_board_2[ 5][ 8] = 1;
        game_board_2[ 5][ 9] = 3;
        game_board_2[ 5][11] = 1;
        game_board_2[ 5][14] = 1;
        game_board_2[ 5][15] = 3;
        game_board_2[ 5][19] = 2;
        game_board_2[ 5][20] = 2;
        game_board_2[ 6][ 4] = 1;
        game_board_2[ 6][ 5] = 1;
        game_board_2[ 6][ 6] = 1;
        game_board_2[ 6][10] = 2;
        game_board_2[ 6][11] = 1;
        game_board_2[ 6][12] = 2;
        game_board_2[ 6][18] = 1;
        game_board_2[ 6][19] = 1;
        game_board_2[ 6][20] = 1;
        game_board_2[ 7][ 9] = 1;
        game_board_2[ 7][10] = 2;
        game_board_2[ 7][11] = 2;
        game_board_2[ 7][12] = 2;
        game_board_2[ 7][13] = 1;
        game_board_2[ 8][ 4] = 3;
        game_board_2[ 8][ 5] = 1;
        game_board_2[ 8][ 6] = 1;
        game_board_2[ 8][ 9] = 1;
        game_board_2[ 8][10] = 2;
        game_board_2[ 8][11] = 2;
        game_board_2[ 8][12] = 2;
        game_board_2[ 8][13] = 1;
        game_board_2[ 8][16] = 1;
        game_board_2[ 8][18] = 1;
        game_board_2[ 8][19] = 1;
        game_board_2[ 8][20] = 3;
        game_board_2[ 9][ 4] = 3;
        game_board_2[ 9][ 5] = 3;
        game_board_2[ 9][ 6] = 3;
        game_board_2[ 9][10] = 2;
        game_board_2[ 9][11] = 2;
        game_board_2[ 9][12] = 2;
        game_board_2[ 9][15] = 1;
        game_board_2[ 9][16] = 1;
        game_board_2[ 9][17] = 1;
        game_board_2[ 9][20] = 3;
        game_board_2[10][ 9] = 1;
        game_board_2[10][11] = 2;
        game_board_2[10][13] = 1;
        game_board_2[11][ 5] = 1;
        game_board_2[11][ 9] = 1;
        game_board_2[11][13] = 1;
        game_board_2[12][ 5] = 1;
        game_board_2[12][ 6] = 1;
        game_board_2[12][ 8] = 5;
        game_board_2[12][10] = 1;
        game_board_2[12][12] = 1;
        game_board_2[12][18] = 1;
        game_board_2[12][19] = 1;
        game_board_2[12][20] = 2;
        game_board_2[13][ 6] = 1;
        game_board_2[13][10] = 1;
        game_board_2[13][11] = 1;
        game_board_2[13][12] = 1;
        game_board_2[13][17] = 2;
        game_board_2[13][18] = 2;
        game_board_2[13][19] = 2;
        game_board_2[13][20] = 2;
        game_board_2[14][ 6] = 1;
        game_board_2[14][10] = 1;
        game_board_2[14][11] = 2;
        game_board_2[14][12] = 1;
        game_board_2[14][17] = 1;
        game_board_2[14][18] = 2;
        game_board_2[14][19] = 2;
        game_board_2[14][20] = 2;
        game_board_2[15][ 6] = 1;
        game_board_2[15][10] = 1;
        game_board_2[15][11] = 1;
        game_board_2[15][12] = 1;
        game_board_2[15][19] = 2;
        game_board_2[15][20] = 2;
        game_board_2[16][ 4] = 2;
        game_board_2[16][ 5] = 2;
        game_board_2[16][ 6] = 2;
        game_board_2[16][ 7] = 3;
        game_board_2[16][ 8] = 3;
        game_board_2[16][10] = 1;
        game_board_2[16][11] = 1;
        game_board_2[16][12] = 3;
        game_board_2[16][15] = 2;
        game_board_2[16][16] = 3;
        game_board_2[16][20] = 2;
        game_board_2[17][ 4] = 1;
        game_board_2[17][ 5] = 1;
        game_board_2[17][ 6] = 3;
        game_board_2[17][ 7] = 3;
        game_board_2[17][ 8] = 2;
        game_board_2[17][ 9] = 2;
        game_board_2[17][10] = 2;
        game_board_2[17][14] = 2;
        game_board_2[17][15] = 2;
        game_board_2[17][16] = 2;
        game_board_2[17][17] = 2;
        game_board_2[17][20] = 1;
    end else begin
        case (game_state)


// 在游戏开始时执行初始化
START: begin
    game_state <= START;
    score_ytank <= 6'b0;
    score_jtank <= 6'b0;
    key_flag <= 0;
    if (key_valid) begin
        case (key_data)
            8'hAD: begin
                game_state <= RUNNING;
                case (game_board_serial)
                    // 1
                    3'd0: begin
                        direct_ytank <= 2'd3;
                        direct_jtank <= 2'd2;
                        ytank_x <= 4;
                        ytank_y <= 12;
                        jtank_x <= 14;
                        jtank_y <= 16;
                        for (i = 0; i < 19; i = i + 1) begin
                            for (j = 3; j < 22; j = j + 1) begin
                                game_board[i][j] <= game_board_1[i][j];
                                bullet_board[i][j] <= 3'b0;
                            end
                        end
                        game_board[ 1][1] <= 3'd4;
                        game_board[ 3][1] <= 3'd7;
                        game_board[ 5][1] <= 3'd7;
                        game_board[ 7][1] <= 3'd7;
                        game_board[ 9][1] <= 3'd7;
                        game_board[11][1] <= 3'd7;
                        game_board[13][1] <= 3'd7;
                        game_board[15][1] <= 3'd7;
                        game_board[17][1] <= 3'd7;

                        game_board[ 1][23] <= 3'd5;
                        game_board[ 3][23] <= 3'd7;
                        game_board[ 5][23] <= 3'd7;
                        game_board[ 7][23] <= 3'd7;
                        game_board[ 9][23] <= 3'd7;
                        game_board[11][23] <= 3'd7;
                        game_board[13][23] <= 3'd7;
                        game_board[15][23] <= 3'd7;
                        game_board[17][23] <= 3'd7;
                    end
                    // 2
                    3'd1: begin
                        direct_ytank <= 2'd1;
                        direct_jtank <= 2'd2;
                        ytank_x <= 1;
                        ytank_y <= 20;
                        jtank_x <= 12;
                        jtank_y <= 8;
                        for (i = 0; i < 19; i = i + 1) begin
                            for (j = 3; j < 22; j = j + 1) begin
                                game_board[i][j] <= game_board_1[i][j];
                                bullet_board[i][j] <= 3'b0;
                            end
                        end
                        game_board[ 1][1] <= 3'd4;
                        game_board[ 3][1] <= 3'd7;
                        game_board[ 5][1] <= 3'd7;
                        game_board[ 7][1] <= 3'd7;
                        game_board[ 9][1] <= 3'd7;
                        game_board[11][1] <= 3'd7;
                        game_board[13][1] <= 3'd7;
                        game_board[15][1] <= 3'd7;
                        game_board[17][1] <= 3'd7;

                        game_board[ 1][23] <= 3'd5;
                        game_board[ 3][23] <= 3'd7;
                        game_board[ 5][23] <= 3'd7;
                        game_board[ 7][23] <= 3'd7;
                        game_board[ 9][23] <= 3'd7;
                        game_board[11][23] <= 3'd7;
                        game_board[13][23] <= 3'd7;
                        game_board[15][23] <= 3'd7;
                        game_board[17][23] <= 3'd7;
                    end
                    default: begin
                        direct_ytank <= 2'd3;
                        direct_jtank <= 2'd2;
                        ytank_x <= 4;
                        ytank_y <= 12;
                        jtank_x <= 14;
                        jtank_y <= 16;
                        for (i = 0; i < 19; i = i + 1) begin
                            for (j = 3; j < 22; j = j + 1) begin
                                game_board[i][j] <= game_board_1[i][j];
                                bullet_board[i][j] <= 3'b0;
                            end
                        end
                        game_board[ 1][1] <= 3'd4;
                        game_board[ 3][1] <= 3'd7;
                        game_board[ 5][1] <= 3'd7;
                        game_board[ 7][1] <= 3'd7;
                        game_board[ 9][1] <= 3'd7;
                        game_board[11][1] <= 3'd7;
                        game_board[13][1] <= 3'd7;
                        game_board[15][1] <= 3'd7;
                        game_board[17][1] <= 3'd7;

                        game_board[ 1][23] <= 3'd5;
                        game_board[ 3][23] <= 3'd7;
                        game_board[ 5][23] <= 3'd7;
                        game_board[ 7][23] <= 3'd7;
                        game_board[ 9][23] <= 3'd7;
                        game_board[11][23] <= 3'd7;
                        game_board[13][23] <= 3'd7;
                        game_board[15][23] <= 3'd7;
                        game_board[17][23] <= 3'd7;
                    end
                endcase
            end
            // 1
            8'hB4: game_board_serial <= 3'd0;
            // 2
            8'hB9: game_board_serial <= 3'd1;
            default: ;
        endcase
    end
end
// 游戏运行中
RUNNING: begin
    // 处理坦克射击和移动、游戏的暂停
    if (key_flag) begin

key_flag <= 1'b0;
game_state <= RUNNING;
if (key_valid) begin
    case (key_data)
        // W
        8'h8E: begin
            direct_ytank <= 2'd0;
            if (game_board[ytank_x - 1][ytank_y] == 0) begin
                game_board[ytank_x - 1][ytank_y] <= 3'd4;
                game_board[ytank_x][ytank_y] <= 3'd0;
                ytank_x <= ytank_x - 1;
            end
        end
        // A
        8'h0E: begin
            direct_ytank <= 2'd1;
            if (game_board[ytank_x][ytank_y - 1] == 0) begin
                game_board[ytank_x][ytank_y - 1] <= 3'd4;
                game_board[ytank_x][ytank_y] <= 3'd0;
                ytank_y <= ytank_y - 1;
            end
        end
        // S
        8'h8D: begin
            direct_ytank <= 2'd2;
            if (game_board[ytank_x + 1][ytank_y] == 0) begin
                game_board[ytank_x + 1][ytank_y] <= 3'd4;
                game_board[ytank_x][ytank_y] <= 3'd0;
                ytank_x <= ytank_x + 1;
            end
        end
        // D
        8'h11: begin
            direct_ytank <= 2'd3;
            if (game_board[ytank_x][ytank_y + 1] == 0) begin
                game_board[ytank_x][ytank_y + 1] <= 3'd4;
                game_board[ytank_x][ytank_y] <= 3'd0;
                ytank_y <= ytank_y + 1;
            end
        end
        // J
        8'h1D: begin
            case (direct_ytank)
                // ↑
                2'd0: begin
                    if (game_board[ytank_x - 1][ytank_y] == 0 || game_board[ytank_x - 1][ytank_y] >= 3'd4) begin
                        bullet_board[ytank_x - 1][ytank_y] <= 3'd4;
                    end else if (game_board[ytank_x - 1][ytank_y] == 3'd2) begin
                        game_board[ytank_x - 1][ytank_y] <= 3'd0;
                    end
                end
                // ←
                2'd1: begin
                    if (game_board[ytank_x][ytank_y - 1] == 0 || game_board[ytank_x][ytank_y - 1] >= 3'd4) begin
                        bullet_board[ytank_x][ytank_y - 1] <= 3'd5;
                    end else if (game_board[ytank_x][ytank_y - 1] == 3'd2) begin
                        game_board[ytank_x][ytank_y - 1] <= 3'd0;
                    end
                end
                // ↓
                2'd2: begin
                    if (game_board[ytank_x + 1][ytank_y] == 0 || game_board[ytank_x + 1][ytank_y] >= 3'd4) begin
                        bullet_board[ytank_x + 1][ytank_y] <= 3'd6;
                    end else if (game_board[ytank_x + 1][ytank_y] == 3'd2) begin
                        game_board[ytank_x + 1][ytank_y] <= 3'd0;
                    end
                end
                // →
                2'd3: begin
                    if (game_board[ytank_x][ytank_y + 1] == 0 || game_board[ytank_x][ytank_y + 1] >= 3'd4) begin
                        bullet_board[ytank_x][ytank_y + 1] <= 3'd7;
                    end else if (game_board[ytank_x][ytank_y + 1] == 3'd2) begin
                        game_board[ytank_x][ytank_y + 1] <= 3'd0;
                    end
                end
            endcase
        end
        // ↑
        8'h3A: begin
            direct_jtank <= 2'd0;
            if (game_board[jtank_x - 1][jtank_y] == 0) begin
                game_board[jtank_x - 1][jtank_y] <= 3'd5;
                game_board[jtank_x][jtank_y] <= 3'd0;
                jtank_x <= jtank_x - 1;
            end
        end
        // ←
        8'h35: begin
            direct_jtank <= 2'd1;
            if (game_board[jtank_x][jtank_y - 1] == 0) begin
                game_board[jtank_x][jtank_y - 1] <= 3'd5;
                game_board[jtank_x][jtank_y] <= 3'd0;
                jtank_y <= jtank_y - 1;
            end
        end
        // ↓
        8'hB9: begin
            direct_jtank <= 2'd2;
            if (game_board[jtank_x + 1][jtank_y] == 0) begin
                game_board[jtank_x + 1][jtank_y] <= 3'd5;
                game_board[jtank_x][jtank_y] <= 3'd0;
                jtank_x <= jtank_x + 1;
            end
        end
        // →
        8'hBA: begin
            direct_jtank <= 2'd3;
            if (game_board[jtank_x][jtank_y + 1] == 0) begin
                game_board[jtank_x][jtank_y + 1] <= 3'd5;
                game_board[jtank_x][jtank_y] <= 3'd0;
                jtank_y <= jtank_y + 1;
            end
        end
        // 1
        8'hB4: begin
            case (direct_jtank)
                // ↑
                2'd0: begin
                    if (game_board[jtank_x - 1][jtank_y] == 0 || game_board[jtank_x - 1][jtank_y] >= 3'd4) begin
                        bullet_board[jtank_x - 1][jtank_y] <= 3'd4;
                    end else if (game_board[jtank_x - 1][jtank_y] == 3'd2) begin
                        game_board[jtank_x - 1][jtank_y] <= 3'd0;
                    end
                end
                // ←
                2'd1: begin
                    if (game_board[jtank_x][jtank_y - 1] == 0 || game_board[jtank_x][jtank_y - 1] >= 3'd4) begin
                        bullet_board[jtank_x][jtank_y - 1] <= 3'd5;
                    end else if (game_board[jtank_x][jtank_y - 1] == 3'd2) begin
                        game_board[jtank_x][jtank_y - 1] <= 3'd0;
                    end
                end
                // ↓
                2'd2: begin
                    if (game_board[jtank_x + 1][jtank_y] == 0 || game_board[jtank_x + 1][jtank_y] >= 3'd4) begin
                        bullet_board[jtank_x + 1][jtank_y] <= 3'd6;
                    end else if (game_board[jtank_x + 1][jtank_y] == 3'd2) begin
                        game_board[jtank_x + 1][jtank_y] <= 3'd0;
                    end
                end
                // →
                2'd3: begin
                    if (game_board[jtank_x][jtank_y + 1] == 0 || game_board[jtank_x][jtank_y + 1] >= 3'd4) begin
                        bullet_board[jtank_x][jtank_y + 1] <= 3'd7;
                    end else if (game_board[jtank_x][jtank_y + 1] == 3'd2) begin
                        game_board[jtank_x][jtank_y + 1] <= 3'd0;
                    end
                end
            endcase
        end
        // P
        8'hA6: begin
            game_state <= PAUSE;
        end
    endcase
end

    end // if (key_flag)

    // 状态检测，决定游戏状态改变
    else begin

key_flag <= 1'b1;
game_state <= RUNNING;
if (score_ytank >= SCORE_LIMIT || score_jtank >= SCORE_LIMIT) begin
    game_state <= WINNING;
end else begin
    // 碰撞检测
    for (i = 0; i < 19; i = i + 1) begin
        for (j = 0; j < 25; j = j + 1) begin
            if (bullet_board_temp[i][j] >= 3'd4) begin
                if (game_board[i][j] == 3'd1 || game_board[i][j] == 3'd3) begin
                    bullet_board[i][j] <= 3'd0;
                end
                else if (game_board[i][j] == 3'd2) begin
                    game_board[i][j] <= 3'd0;
                    bullet_board[i][j] <= 3'd0;
                end
                else if (game_board[i][j] == 3'd4) begin
                    bullet_board[i][j] <= 3'd0;
                    score_jtank <= score_jtank + 1;
                    game_board[(SCORE_LIMIT - score_jtank) * 2 + 1][1] <= 3'd0;
                end
                else if (game_board[i][j] == 3'd5) begin
                    bullet_board[i][j] <= 3'd0;
                    score_ytank <= score_ytank + 1;
                    game_board[(SCORE_LIMIT - score_ytank) * 2 + 1][23] <= 3'd0;
                end
                else begin
                    bullet_board[i][j] <= bullet_board_temp[i][j];
                end
            end
            else begin
                bullet_board[i][j] <= 3'd0;
            end
        end
    end
end

    end
end
// 游戏暂停
PAUSE: begin
    game_state <= PAUSE;
    if (key_valid) begin
        case (key_data)
            // BackSpace
            8'hB3: begin
                game_state <= RUNNING;
            end
            // Esc
            8'h3B: begin
                game_state <= WINNING;
            end
            default: ;
        endcase
    end
end
// 胜利结算
WINNING: begin
    game_state <= WINNING;
    if (key_valid) begin
        case (key_data)
            // R
            8'h96: begin
                game_state <= START;
            end
            default: ;
        endcase
    end
end


        endcase
    end // else // if (!pause_flag)
end // END always

// 子弹移动
always @(*) begin
    // 清空所有位置的访问记录
    for (i = 0; i < 19; i = i + 1) begin
        for (j = 0; j < 25; j = j + 1) begin
            bullet_board_temp[i][j] = 1'b0;
        end
    end
    for (i = 0; i < 19; i = i + 1) begin
        for (j = 0; j < 25; j = j + 1) begin
            if (bullet_board[i][j] >= 3'd4) begin
                case (bullet_board[i][j])
                    3'd4: bullet_board_temp[i - 1][j] = 3'd4;
                    3'd5: bullet_board_temp[i][j - 1] = 3'd5;
                    3'd6: bullet_board_temp[i + 1][j] = 3'd6;
                    3'd7: bullet_board_temp[i][j + 1] = 3'd7;
                    default: ;
                endcase
            end
        end
    end
end



// 控制画布部分
wire [11:0] rdata_red;
wire [11:0] rdata_green;
wire [11:0] rdata_white;
wire [11:0] rdata_ytank;
wire [11:0] rdata_jtank;
wire [11:0] rdata_start;
wire [11:0] rdata_pause;
wire [11:0] rdata_ytank_win;
wire [11:0] rdata_jtank_win;
wire [11:0] rdata_bullet;
wire [11:0] rdata_heart;
wire [11:0] rdata_arrow;
reg [2:0] rdata_matrix [0:18][0:24];

// 计算矩阵坐标
reg [4:0] x;
reg [4:0] y;
reg [7:0] x_temp;
reg [7:0] y_temp;
// 计算相对坐标
reg [2:0] x_relative;
reg [2:0] y_relative;
reg [5:0] raddr_temp;
reg [5:0] raddr_ytank;
reg [5:0] raddr_jtank;
reg [5:0] raddr_arrow;

always @(*) begin
    x_temp = raddr / 200;//算出来上面有几行
    y_temp = raddr % 200;//计算到每行的第几个像素（取余）
end
always @(*) begin
    x_relative = x_temp % 8;
    y_relative = y_temp % 8;
end
always @(*) begin
    raddr_temp = x_relative * 8 + y_relative;
    case (direct_ytank)
        // ↑
        2'd0: raddr_ytank = x_relative * 8 + y_relative;
        // ←
        2'd1: raddr_ytank = y_relative * 8 + (7 - x_relative);
        // ↓
        2'd2: raddr_ytank = (7 - x_relative) * 8 + (7 - y_relative);
        // →
        2'd3: raddr_ytank = (7 - y_relative) * 8 + x_relative;
    endcase
    case (direct_jtank)
        // ↑
        2'd0: raddr_jtank = x_relative * 8 + y_relative;
        // ←
        2'd1: raddr_jtank = y_relative * 8 + (7 - x_relative);
        // ↓
        2'd2: raddr_jtank = (7 - x_relative) * 8 + (7 - y_relative);
        // →
        2'd3: raddr_jtank = (7 - y_relative) * 8 + x_relative;
    endcase
    case (game_board_serial)
        // ↖
        3'd0: raddr_arrow = x_relative * 8 + y_relative;
        // ↗
        3'd1: raddr_arrow = (7 - y_relative) * 8 + x_relative;
        // ↙
        3'd2: raddr_arrow = y_relative * 8 + (7 - x_relative);
        // ↘
        3'd3: raddr_arrow = (7 - x_relative) * 8 + (7 - y_relative);
        default: raddr_arrow = x_relative * 8 + y_relative;
    endcase
end
always @(*) begin
    x = x_temp / 8;
    y = y_temp / 8;
end

// 红墙，矩阵里用1表示
red RED(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr_temp),
    .doutb(rdata_red)
);
// 绿草，矩阵里用2表示
grass GRASS(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr_temp),
    .doutb(rdata_green)
);
// 白墙，矩阵里用3表示
white WHITE(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr_temp),
    .doutb(rdata_white)
);
// 银坦克，矩阵里用4表示
ytank YTANK(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr_ytank),
    .doutb(rdata_ytank)
);
// 金坦克，矩阵里用5表示
jtank JTANK(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr_jtank),
    .doutb(rdata_jtank)
);
// 子弹，矩阵里用6表示
bullet BULLET(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr_temp),
    .doutb(rdata_bullet)
);
// 生命，矩阵里用7表示
heart HEART(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr_temp),
    .doutb(rdata_heart)
);
// 开始界面
start START_SCREEN(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr),
    .doutb(rdata_start)
);
// 开始界面的箭头
arrow ARROW(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr_arrow),
    .doutb(rdata_arrow)
);
// 菜单（暂停界面）
pause PAUSE_SCREEN(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr),
    .doutb(rdata_pause)
);
// 银坦克胜利
ytank_win YTANK_WIN(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr),
    .doutb(rdata_ytank_win)
);
// 金坦克胜利
jtank_win JTANK_WIN(
    .clka(clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(15'b0),
    .dina(12'b0),
    .clkb(pclk),
    .enb(1'b1),
    .addrb(raddr),
    .doutb(rdata_jtank_win)
);

// 存数组
always @(*) begin
    for (i = 0; i < 19; i = i + 1) begin
        for (j = 0; j < 25; j = j + 1) begin
            rdata_matrix[i][j] = game_board[i][j];
            if (rdata_matrix[i][j] == 0 && bullet_board[i][j] >= 4) begin
                rdata_matrix[i][j] = 6;
            end
        end
    end
end

// 根据矩阵坐标涂色形成背景
always @(*) begin
    if (!rstn) begin
        rdata = 12'b0;
    end
    else begin
        case (game_state)
            2'd0: begin
                if (x == 14 && y == 12) begin
                    rdata = rdata_arrow;
                end else begin
                    rdata = rdata_start;
                end
            end
            2'd1: begin
                case (rdata_matrix[x][y])
                    0: rdata = 12'b0;
                    1: rdata = rdata_red;
                    2: rdata = rdata_green;
                    3: rdata = rdata_white;
                    4: rdata = rdata_ytank;
                    5: rdata = rdata_jtank;
                    6: rdata = rdata_bullet;
                    7: rdata = rdata_heart;
                endcase
            end
            2'd2: rdata = rdata_pause;
            2'd3: begin
                if (score_jtank >= score_ytank) begin
                    rdata = rdata_jtank_win;
                end else begin
                    rdata = rdata_ytank_win;
                end
            end
        endcase
    end
end
endmodule
