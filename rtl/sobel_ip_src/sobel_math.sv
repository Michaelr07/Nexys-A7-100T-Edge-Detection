`timescale 1ns / 1ps
import video_pkg::*;

module sobel_math
(
    input logic         clk,
    input logic         rst_n,
    input logic         en,
    
    input logic [7:0]   i_window [0:2][0:2],
    input pixel_t       i_pixel_meta,
    input logic [7:0]   threshold,
    input logic         i_valid,
    output pixel_t      o_pixel,
    output logic        o_valid
    );
    
    
    logic [7:0] y_padded [0:2][0:2];
    logic [7:0] x_padded [0:2][0:2];
    logic is_top, is_bottom, is_left, is_right;
    logic [11:0] ts_scaled;
    pixel_t meta_pipe [0:1];
    
    logic valid_d, valid_dd; 
    
    assign ts_scaled = {1'b0, threshold, 3'b000};
    
    // Stage 1 & 2 Metadata Delay
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            meta_pipe[0] <= '0;
            meta_pipe[1] <= '0;
            valid_d      <= 1'b0;
        end else if (en) begin
            meta_pipe[0] <= i_pixel_meta; // Matches Clock 1 (r_sum, l_sum)
            meta_pipe[1] <= meta_pipe[0]; // Matches Clock 2 (Gx, Gy)
            valid_d      <= i_valid;
        end
    end
    
    // Matrix padding
    assign is_top    = (i_pixel_meta.y == 0);
    assign is_bottom = (i_pixel_meta.y == TIMING_VGA_640x480.V_ACTIVE-1);
    assign is_left   = (i_pixel_meta.x == 0);
    assign is_right  = (i_pixel_meta.x == TIMING_VGA_640x480.H_ACTIVE-1);
    
    always_comb begin
        //vertical padding
        y_padded[0][0] = is_top? i_window[1][0]: i_window[0][0];
        y_padded[0][1] = is_top? i_window[1][1]: i_window[0][1];
        y_padded[0][2] = is_top? i_window[1][2]: i_window[0][2];
        
        y_padded[1][0] = i_window[1][0];
        y_padded[1][1] = i_window[1][1];
        y_padded[1][2] = i_window[1][2];
        
        y_padded[2][0] = is_bottom? i_window[1][0]: i_window[2][0];
        y_padded[2][1] = is_bottom? i_window[1][1]: i_window[2][1];
        y_padded[2][2] = is_bottom? i_window[1][2]: i_window[2][2];
        
        // horiozntal padding
        x_padded[0][0] = is_left? y_padded[0][1]: y_padded[0][0];
        x_padded[1][0] = is_left? y_padded[1][1]: y_padded[1][0];
        x_padded[2][0] = is_left? y_padded[2][1]: y_padded[2][0];
        
        x_padded[0][1] = y_padded[0][1];
        x_padded[1][1] = y_padded[1][1];
        x_padded[2][1] = y_padded[2][1];
        
        x_padded[0][2] = is_right? y_padded[0][1]: y_padded[0][2];
        x_padded[1][2] = is_right? y_padded[1][1]: y_padded[1][2];
        x_padded[2][2] = is_right? y_padded[2][1]: y_padded[2][2];
    end
    
    
    //Sobel Adder
    
    logic [9:0]     r_sum, l_sum;
    logic [9:0]     t_sum, b_sum;
    logic [10:0]    Gx, Gy;
    logic [10:0]    abs_Gx, abs_Gy;
    logic [11:0]    G_total;
    
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            r_sum   <= '0;
            l_sum   <= '0;
            t_sum   <= '0;
            b_sum   <= '0;
            valid_dd <= 0;
        end
        else if (en) begin
            r_sum   <= x_padded[0][2] + (x_padded[1][2] << 1) + x_padded[2][2];
            l_sum   <= x_padded[0][0] + (x_padded[1][0] << 1) + x_padded[2][0];
            t_sum   <= x_padded[0][0] + (x_padded[0][1] << 1) + x_padded[0][2];
            b_sum   <= x_padded[2][0] + (x_padded[2][1] << 1) + x_padded[2][2];
            valid_dd <= valid_d;
        end
    end
    
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            Gx  <= '0;
            Gy  <= '0;
        end
        else if (en) begin
            Gx  <= r_sum - l_sum;
            Gy  <= t_sum - b_sum;
        end
    end
    

    assign abs_Gx   = (Gx[10])? -Gx : Gx;
    assign abs_Gy   = (Gy[10])? -Gy : Gy;
    assign G_total  = abs_Gx + abs_Gy;
    
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            o_pixel     <= '0;
            o_valid     <= 1'b0;
        end
        else if (en) begin
            o_pixel     <= meta_pipe[1];
            
            o_pixel.r   <= (G_total > ts_scaled)? 4'h0 : meta_pipe[1].r;
            o_pixel.g   <= (G_total > ts_scaled)? 4'hf : meta_pipe[1].g;
            o_pixel.b   <= (G_total > ts_scaled)? 4'h0 : meta_pipe[1].b;
            
            o_valid     <= valid_dd;
        end
    
    end
    
    

    
endmodule
