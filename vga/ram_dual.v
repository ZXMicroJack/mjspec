/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module ram_dual(q, addr_in, addr_out, d, we, clk1, clk2);
  parameter RAMSIZE = 2560;
	parameter RAMSIZE_1 = RAMSIZE-1;
   output[7:0] q;
   input [7:0] d;
   input [12:0] addr_in;
   input [12:0] addr_out;
   input we, clk1, clk2;

   reg [12:0] addr_out_reg;
   reg [7:0] q;
   reg [7:0] mem [0:RAMSIZE_1] /* synthesis ramstyle = "M144K" */;

`ifdef SIM
   initial begin
     $readmemh("jupiteraceram.hex", mem);
   end
`else
  integer i;
   initial begin
     for (i=0; i<RAMSIZE; i=i+1)
       mem[i] <= 32;
   end
`endif

   always @(posedge clk1) begin
      if (we)
         mem[addr_in] <= d;
   end

   always @(posedge clk2) begin
      //addr_out_reg <= addr_out;
      //q <= mem[addr_out_reg];
      q <= mem[addr_out];
   end

endmodule
