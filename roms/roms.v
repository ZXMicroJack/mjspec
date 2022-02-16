/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module roms(q, a, clk);
   output reg[7:0] q;
   input [15:0] a;
   input clk;
   reg [7:0] mem [0:57343] /* synthesis ramstyle = "M144K" */;
   initial begin
     $readmemh("roms/roms.hex", mem);
   end

   always @(posedge clk) begin
     q <= mem[a];
   end
endmodule
