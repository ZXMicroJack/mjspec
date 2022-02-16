/* TODO: I cannot remember where I lifted this from, it is not my work, but it is
 * in common use in freely distributed open sources. */

module dsdac1o(
   output    reg             DACout,   //Average Output feeding analog lowpass
   input          [MSBI:0]    DACin,   //DAC input (excess 2**MSBI)
   input                  CLK,
   input                   RESET //
);

parameter MSBI = 16;

reg [MSBI+2:0] DeltaAdder;   //Output of Delta Adder
reg [MSBI+2:0] SigmaAdder;   //Output of Sigma Adder
reg [MSBI+2:0] SigmaLatch;   //Latches output of Sigma Adder
reg [MSBI+2:0] DeltaB;      //B input of Delta Adder

always @ (*)
   DeltaB = {SigmaLatch[MSBI+2], SigmaLatch[MSBI+2]} << (MSBI+1);

always @(*)
   DeltaAdder = DACin + DeltaB;

always @(*)
   SigmaAdder = DeltaAdder + SigmaLatch;

always @(posedge CLK or posedge RESET)
   if(RESET) begin
      SigmaLatch <= 1'b1 << (MSBI+1);
      DACout <= 1'b0;
   end else begin
      SigmaLatch <= SigmaAdder;
      DACout <= SigmaLatch[MSBI+2];
   end
endmodule
