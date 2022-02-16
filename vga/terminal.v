/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module terminalscreen(
  input [10 : 0] x_cnt,
  input [9 : 0]  y_cnt,
  input hsync_de,
  input vsync_de,
  input vga_clk,
  input screen_clk,
  input[7:0] screen_byte,
  output reg[11:0] text_output
  );

  parameter Hde_start=144;
  parameter Hde_end=784;
  parameter Vde_start=35;
  parameter Vde_end=515;

  ///////////////////////////////////////////////////////////////////////////////////
  // char debug output
  reg [11:0] screen_pos = 0;

  wire [7:0] ram_read;
  reg [7:0] ram_write;
  reg [12:0] ram_addr;
  wire ram_wclk;
  reg ram_wren;
  reg[12:0] ram_waddr;
  reg[7:0] ram_wdata, ram_data;

  `define TCOLS 64
  `define SCREEN_SIZE 2560
  ram_dual #(`SCREEN_SIZE) ram(ram_read, ram_waddr, ram_addr, ram_wdata, ram_wren, ram_wclk, !vga_clk);

  reg [7:0] FONT [0:767];
  initial begin
    $readmemh("font.hex", FONT);
  end

  // handle clocking in characters
  always @(posedge screen_clk) begin
    if (screen_byte == 8'h00) begin
      screen_pos <= 0;
    end else begin
      if (screen_pos < `SCREEN_SIZE) begin
        ram_waddr = screen_pos;
        ram_wdata = screen_byte;
        ram_wren = 1'b1;
        screen_pos <= screen_pos + 1;
      end
    end
  end
  assign ram_wclk = !screen_clk;

  parameter textStartH = Hde_start + 64;
  parameter textStartV = Vde_start + 61;
  parameter textEndH = textStartH + `TCOLS * 8;
  parameter textEndV = textStartV + 40 * 8;
  integer _x, _y;

  always @(posedge vga_clk) begin
    if (x_cnt >= textStartH && y_cnt >= textStartV && x_cnt < textEndH && y_cnt < textEndV) begin
      if (x_cnt[2:0] == 0) begin
        _x = (x_cnt + 8) - textStartH;
        _y = y_cnt - textStartV;
        ram_addr = {_y[8:3], _x[8:3]};
      end
    end
  end

  reg mybit;
  integer char;
  integer yoff, off;
  always @(negedge vga_clk) begin
    text_output <= 12'h000;
    if (x_cnt >= textStartH && y_cnt >= textStartV && x_cnt < textEndH && y_cnt < textEndV) begin

      yoff = y_cnt[2:0];
      off = x_cnt[2:0];
      if (off == 0) ram_data = ram_read;

      char = (ram_data - 32) * 8;
      case (off)
        0: mybit = FONT[char+yoff][7];
        1: mybit = FONT[char+yoff][6];
        2: mybit = FONT[char+yoff][5];
        3: mybit = FONT[char+yoff][4];
        4: mybit = FONT[char+yoff][3];
        5: mybit = FONT[char+yoff][2];
        6: mybit = FONT[char+yoff][1];
        7: mybit = FONT[char+yoff][0];
      endcase

      text_output <= mybit ? 12'hfff : 12'h000;
    end
  end
  ///////////////////////////////////////////////////////////////////////////////////


endmodule
