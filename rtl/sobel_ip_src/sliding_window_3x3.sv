import video_pkg::*;

module sliding_window_3x3
    (
        input logic         clk,
        input logic         rst_n,
        input logic         en,
        input pixel_t       i_pixel,
        input logic [7:0]   i_gs_data,
        input logic         i_valid,
        output logic        o_valid,
        output pixel_t      o_pixel,
        output logic [7:0]  o_window [0:2][0:2]
    );
    
    localparam X_BITS = $bits(i_pixel.x);
    localparam DATA_BITS = $bits(i_gs_data);
    
    logic valid_d, valid_dd;
    pixel_t pixel_d, pixel_dd;
    logic [DATA_BITS-1:0]  line0, line1, line2;
    logic [DATA_BITS-1:0] lb0_d, lb0_dd, lb1_d;
    
    logic [DATA_BITS-1:0] window [0:2][0:2];
    
    
    assign line0 = i_gs_data;
   
   always_ff @(posedge clk) begin
    if (!rst_n) begin
        valid_d     <= 1'b0;
        valid_dd    <= 1'b0;
    end
    else if (en) begin
        valid_d  <= i_valid;
        valid_dd <= valid_d;
    end   
   end
   
   assign o_valid = valid_dd;
   
   
    always_ff @(posedge clk) begin
        if (!rst_n) begin  
            pixel_d  <= '0;
            pixel_dd <= '0; 
            lb0_d    <= '0;
            lb0_dd   <= '0; 
            lb1_d    <= '0;
        end
        else if (en) begin
            pixel_d  <= i_pixel;
            pixel_dd <= pixel_d;
            
            lb0_d    <= line0;
            lb0_dd   <= lb0_d;
            
            lb1_d    <= line1;
        end
    end
    
    
    line_buffer #(
        .DATA_BITS(8),
        .ADDR_W(X_BITS)
    ) lb0 (
        .clk(clk),
        .en(en),
        .addr(i_pixel.x),
        .wr(i_pixel.de), .rd(i_pixel.de),
        .wr_data(line0), .rd_data(line1)
    );
    
    
    line_buffer #(
        .DATA_BITS(8),
        .ADDR_W(X_BITS)
    ) lb1 (
        .clk(clk),
        .en(en),
        .addr(pixel_d.x),
        .wr(pixel_d.de), .rd(pixel_d.de),
        .wr_data(line1), .rd_data(line2)
    );
    
    always_ff @(posedge clk) begin
        if(!rst_n) begin
           for (int r = 0; r < 3; r++) begin
                for (int c = 0; c < 3; c++) begin
                    window[r][c] <= '0; 
                end
            end
        end
        else if (en) begin
            if (pixel_dd.de) begin
                window[0][0]    <= lb0_dd;
                window[0][1]    <= window[0][0];
                window[0][2]    <= window[0][1];
                
                window[1][0]    <= lb1_d;
                window[1][1]    <= window[1][0];
                window[1][2]    <= window[1][1];
                
                window[2][0]    <= line2;
                window[2][1]    <= window[2][0];
                window[2][2]    <= window[2][1];
            end
        end
    end
    
    assign o_pixel = pixel_dd;
    assign o_window = window;
    
endmodule