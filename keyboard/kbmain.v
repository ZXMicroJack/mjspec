/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module kbmain(
  input kbd_clk,
  input kbd_data,
  input clk50m,
  output [4:0] kvcxzsh_zx,
  output [4:0] kgfdsa,
  output [4:0] ktrewq,
  output [4:0] k54321,
  output [4:0] k67890,
  output [4:0] kyuiop,
  output [4:0] khjklen,
  output [4:0] kbnmsssp_zx,
  output [8:0] kspecial,
  output [4:0] kcxzsssh_ja,
  output [4:0] kvbnmsp_ja
  );

  // PS2
  wire [31:0] kbd_key;
  wire kbd_key_valid;

  ps2 ps2(
    .kbd_clk(kbd_clk),
    .kbd_data(kbd_data),
    .kbd_key(kbd_key),
    .kbd_key_valid(kbd_key_valid),
    .clk(clk50m)
    );

  zxkeyboard zxkeyboard(
    .kbd_key(kbd_key),
    .kbd_key_valid(kbd_key_valid),
    .kvcxzsh_zx(kvcxzsh_zx),
    .kgfdsa(kgfdsa),
    .ktrewq(ktrewq),
    .k54321(k54321),
    .k67890(k67890),
    .kyuiop(kyuiop),
    .khjklen(khjklen),
    .kbnmsssp_zx(kbnmsssp_zx),
    .kspecial(kspecial),
    .kcxzsssh_ja(kcxzsssh_ja),
    .kvbnmsp_ja(kvbnmsp_ja)
    );

endmodule
