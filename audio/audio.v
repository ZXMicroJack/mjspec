/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module audio(
  output aud_left,
  output aud_right,
  input clk50m,
  input clk_audio,
  input rstn,

  input ym2149_clk,
  input[7:0] ym2149_di,
  output[7:0] ym2149_do,
  input ym2149_bdir,
  input ym2149_bc,

  input ear,
  input ear_in
  );

  // generate sine wave
  // aud_test aud_test(
  //   .aud_clk(count[9]),
  //   .dac_out_l(dac_out_l)
  //   );

  // audio dacs
  reg [15:0] dac_out_l;
  wire[7:0] ym2149_cha_out, ym2149_chb_out, ym2149_chc_out;

  dsdac1o dsdac1ol(
    .DACout(aud_left),
    .DACin(dac_out_l),
    .CLK(clk50m),
    .RESET(!rstn)
    );

  dsdac1o dsdac1or(
    .DACout(aud_right),
    .DACin(dac_out_l),
    .CLK(clk50m),
    .RESET(!rstn)
    );



/*
    -- data bus
    I_DA                : in  std_logic_vector(7 downto 0);
    O_DA                : out std_logic_vector(7 downto 0);
    O_DA_OE_L           : out std_logic;
    -- control
    I_A9_L              : in  std_logic;
    I_A8                : in  std_logic;
    I_BDIR              : in  std_logic;
    I_BC2               : in  std_logic;
    I_BC1               : in  std_logic;
    I_SEL_L             : in  std_logic;

    O_AUDIO             : out std_logic_vector(7 downto 0);
    O_AUDIO_A           : out std_logic_vector(7 downto 0);
    O_AUDIO_B           : out std_logic_vector(7 downto 0);
    O_AUDIO_C           : out std_logic_vector(7 downto 0);
    -- port a
    I_IOA               : in  std_logic_vector(7 downto 0);
    O_IOA               : out std_logic_vector(7 downto 0);
    O_IOA_OE_L          : out std_logic;
    -- port b
    I_IOB               : in  std_logic_vector(7 downto 0);
    O_IOB               : out std_logic_vector(7 downto 0);
    O_IOB_OE_L          : out std_logic;

    ENA                 : in  std_logic; -- clock enable for higher speed operation
    RESET_L             : in  std_logic;
    CLK                 : in  std_logic;  -- note 6 Mhz
    CLK28               : in  std_logic
*/
  ym2149 ym2149(
      .CLK(ym2149_clk),
      .CLK28(clk50m),
      .ENA(1'b1),
      .RESET_L(rstn),
      .I_A9_L(1'b0),
      .I_A8(1'b1),
      .I_BDIR(ym2149_bdir),
      .I_BC1(ym2149_bc),
      .I_BC2(1'b1),
      .I_DA(ym2149_di),
      .O_DA(ym2149_do),
      .O_AUDIO_A(ym2149_cha_out),
      .O_AUDIO_B(ym2149_chb_out),
      .O_AUDIO_C(ym2149_chc_out),
      .I_SEL_L(1'b1),
      .I_IOA(8'h00),
      .I_IOB(8'h00));

  wire[9:0] ym2149_aud_out;
  assign ym2149_aud_out =
    {2'b00, ym2149_cha_out} +
    {2'b00, ym2149_chb_out} +
    {2'b00, ym2149_chc_out};

  always @(posedge clk_audio)
    dac_out_l <= (ear ? 16'hc000 : 16'h4000) + (ear_in ? 16'he000 : 16'h2000) + {ym2149_aud_out,6'h00};

endmodule
