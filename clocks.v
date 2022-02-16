/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module clocks(
  input clk50m,
  output reg clk14m,
  output reg clk24m576);

// to get zx spectrum 128 clock of 3.546900 we should get x4 this, which is
// 5 single clocks for every 21 double


  reg[13:0] bitmap = 14'b10001000010000;
  reg clkWait = 1'b0;
  reg[5:0] clkCounter = 6'h00;

  always @(posedge clk50m) begin
    if (clkWait ^ bitmap[13]) begin
      clk14m <= !clk14m;
      clkWait <= 1'b0;
      bitmap[13:0] <= {bitmap[12:0], bitmap[13]};
    end else clkWait <= ! clkWait;

    if (clkCounter == 6'd57)
      clkCounter <= 6'd0;
    else begin
      clk24m576 <= !clk24m576;
      clkCounter <= clkCounter + 1;
    end
  end

endmodule
