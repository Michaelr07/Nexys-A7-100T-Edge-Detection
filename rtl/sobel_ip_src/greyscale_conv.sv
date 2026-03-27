import video_pkg::*;

module greyscale_conv 
(
    input   logic           clk,
    input   logic           rst_n,
    input   logic           en,
    input   pixel_t         i_pixel,
    input   logic           i_valid,
    output  logic           o_valid,
    output  pixel_t         o_pixel,
    output  logic [7:0]     o_grayscale
);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
           o_grayscale  <= '0; 
           o_pixel      <= '0;
           o_valid      <= 1'b0;
        end
        else if (en) begin
            o_grayscale <= ({i_pixel.r,4'h0} >> 2) + ({i_pixel.g,4'h0} >> 1) + ({i_pixel.b,4'h0} >> 2);
            o_pixel     <= i_pixel;
            o_valid     <= i_valid;
        end
    end

endmodule