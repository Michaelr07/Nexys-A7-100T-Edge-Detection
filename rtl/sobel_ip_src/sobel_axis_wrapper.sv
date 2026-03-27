`timescale 1ns / 1ps
import video_pkg::*;

module sobel_axis_wrapper
#(
    parameter int TDATA_W = 16,
    parameter int H_ACTIVE = 640,
    parameter int V_ACTIVE = 480
)
(
    input  logic               clk,
    input  logic               rst_n,
    input  logic [7:0]         THRESHOLD,

    input  logic [TDATA_W-1:0] s_axis_tdata,
    input  logic               s_axis_tvalid,
    output logic               s_axis_tready, 
    input  logic               s_axis_tuser,  
    input  logic               s_axis_tlast,  

    output logic [TDATA_W-1:0] m_axis_tdata,
    output logic               m_axis_tvalid,
    input  logic               m_axis_tready, 
    output logic               m_axis_tuser,
    output logic               m_axis_tlast
);

    pixel_t i_pixel, o_pixel;
    logic o_valid;
    logic [$clog2(V_ACTIVE)-1:0] x_cnt;
    logic [$clog2(H_ACTIVE)-1:0] y_cnt;
    
    logic en;
    assign en = m_axis_tready; // Freeze the pipeline if VDMA is busy
    assign s_axis_tready = en; // Tell upstream FIFO to pause if we freeze
    
    // 1. Dynamic Coordinate Generator
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            x_cnt   <= '0;
            y_cnt   <= '0;
        end
        else if (s_axis_tvalid && en) begin
            if (s_axis_tuser) begin
                x_cnt   <= 1;
                y_cnt   <= '0;
            end else if (s_axis_tlast) begin
                x_cnt   <= '0;
                y_cnt   <= y_cnt + 1;
            end else begin
                x_cnt   <= x_cnt + 1;
            end
        end
    end
    
    // 2. Pack the Input Struct (Extract exactly 12 bits from the 16-bit bus)
    always_comb begin
        i_pixel.r   = s_axis_tdata[11:8];
        i_pixel.g   = s_axis_tdata[7:4];
        i_pixel.b   = s_axis_tdata[3:0];
        
        i_pixel.x   = (s_axis_tuser) ? '0 : x_cnt;
        i_pixel.y   = (s_axis_tuser) ? '0 : y_cnt;
        
        i_pixel.sof = s_axis_tuser;
        i_pixel.eol = s_axis_tlast;
        i_pixel.de  = s_axis_tvalid; 
    end
    
    // 3. Core Math Engine (We pass 12 to RGBW here since the math is still 12-bit)
    sobel_top sobel_filter (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .threshold(THRESHOLD),
        .i_pixel(i_pixel),
        .i_valid(s_axis_tvalid),
        .o_pixel(o_pixel),
        .o_valid(o_valid)
    );
        
    // 4. Unpack to AXI Master (Pad back to 16 bits)
    //assign s_axis_tready = o_ready;   
    assign m_axis_tdata  = {4'b0000, o_pixel.r, o_pixel.g, o_pixel.b}; 
    assign m_axis_tvalid = o_valid;
    assign m_axis_tuser  = o_pixel.sof;
    assign m_axis_tlast  = o_pixel.eol;
        
endmodule