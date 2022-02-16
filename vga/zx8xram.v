/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module zx8x_vram(q, addr_in, addr_out, d, we, clk1, clk2);
  parameter RAMSIZE = 12'h700;
	parameter RAMSIZE_1 = RAMSIZE-1;
   output[7:0] q;
   input [7:0] d;
   input [12:0] addr_in;
   input [12:0] addr_out;
   input we, clk1, clk2;

   reg [12:0] addr_out_reg;
   reg [7:0] q;
   reg [7:0] mem [0:RAMSIZE_1] /* synthesis ramstyle = "M144K" */;

   initial begin
     $readmemh("zx8xcharset-test.hex", mem);
//     $readmemh("zx8xcharset.hex", mem);
   end

   always @(posedge clk1) begin
      if (we)
         mem[addr_in] <= d;
   end

   always @(posedge clk2) begin
      q <= mem[addr_out];
   end

endmodule
