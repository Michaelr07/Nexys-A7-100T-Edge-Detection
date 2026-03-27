`timescale 1ns / 1ps

module line_buffer
    #(
        parameter DATA_BITS = 8,
        parameter ADDR_W = 640
    )(
        input logic                         clk,
        input logic                         en,
        input logic [ADDR_W-1:0]            addr,
        input logic                         wr, rd,
        input logic  [DATA_BITS-1:0]        wr_data, 
        output logic [DATA_BITS-1:0]        rd_data
    );
    
    (* ram_style = "block" *) logic [DATA_BITS-1:0] mem [0:(1<<ADDR_W)-1];
    
    always_ff @(posedge clk) begin
        if (rd && en)     rd_data     <= mem[addr];
        if (wr && en)     mem[addr]   <= wr_data;
        
    end
    
endmodule
