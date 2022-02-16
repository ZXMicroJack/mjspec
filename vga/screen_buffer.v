/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
`define BUFFER_SIZE 6912

/* To test screen rendering with a static screen, place into screendump.hex
* and uncomment the readmemh lines to read into memory.  This will place
* a screenshot into memory, and allow shorter dev cycle. */
module screen_buffer(read_data, addr_in, addr_out, write_data, we, clk1, clk2);
   output[7:0] read_data;
   input [7:0] write_data;
   input [12:0] addr_in;
   input [12:0] addr_out;
   input we, clk1, clk2;

   //reg [12:0] addr_out_reg;
   reg [7:0] read_data;
   reg [7:0] mem [0:`BUFFER_SIZE-1] /* synthesis ramstyle = "M144K" */;
   initial begin
     $readmemh("screendump.hex", mem);
   end

   always @(posedge clk1) begin
      if (we)
         mem[addr_in] <= write_data;
   end

   always @(posedge clk2) begin
      //addr_out_reg <= addr_out;
      //read_data <= mem[addr_out_reg];
      read_data <= mem[addr_out];
   end

endmodule
