`timescale 1ns / 1ps

import video_pkg::*;

module sobel_top
(
    input logic         clk,
    input logic         rst_n,
    input logic         en,
    input logic [7:0]   threshold,
    
    input pixel_t       i_pixel,
    input logic         i_valid,
    
    output pixel_t      o_pixel,
    output logic        o_valid
);
    logic [7:0] gs_rgb;
    logic [7:0] window [0:2][0:2];
    logic valid_1, valid_2;
    
    pixel_t gs_pixel, wnd_pixel;
    
    greyscale_conv 
        gs_converter (
            .clk(clk), .rst_n(rst_n), .en(en), .i_pixel(i_pixel), .i_valid(i_valid), .o_valid(valid_1), .o_pixel(gs_pixel), .o_grayscale(gs_rgb)
        );
    
    
    sliding_window_3x3
        wnd_3x3 (
            .clk(clk), .rst_n(rst_n), .en(en), .i_pixel(gs_pixel), .i_gs_data(gs_rgb), .i_valid(valid_1), .o_valid(valid_2), .o_pixel(wnd_pixel), .o_window(window)
        );
    
    
    sobel_math
        sobel_block (
            .clk(clk), .rst_n(rst_n), .en(en), .i_window(window), .i_pixel_meta(wnd_pixel), .threshold(threshold), .o_pixel(o_pixel), .i_valid(valid_2), .o_valid(o_valid)
        );
    
endmodule
