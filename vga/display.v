/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module display(
  input rstn,
  input clk50m,
  input sys_clk,
  input flash_clk,

  // zx spec screen 1 (48k one)
  input[7:0] scr_write,
  input[12:0] scr_write_addr,
  input scr_write_we,

  // zx spec border colour
  input[2:0] border,

  // zx spec screen 2 (128k)
  input[7:0] scr_write2,
  input[12:0] scr_write_addr2,
  input scr_write_we2,

  // zx which screen to show
  input screen_flip,

  // jupiterace
`ifdef JUPITERACE
  input[7:0] ja_write,
  input[12:0] ja_write_addr,
  input ja_write_we,
  input ja_active,
`endif

`ifdef ZX8X
  input[7:0] zx8x_write,
  input zx8x_write_we,
  input zx81_active,
  input zx80_active,
`endif

  // debug / terminal screen
`ifdef DEBUG_SCREEN
  input screen_clk,
  input[7:0] screen_byte,
  input screen_mode,
`endif

  // vga connectors
  output vga_hs,
  output vga_vs,
  output [3:0] vga_r,
  output [3:0] vga_g,
  output [3:0] vga_b
  );

  wire [10 : 0] x_cnt;
  wire [9 : 0]  y_cnt;
  wire hsync_de;
  wire vsync_de;
  wire vga_clk;
  wire [11:0] screen_output;
  wire [11:0] screen_output2;
  wire [11:0] jace_output;
  wire [11:0] zx8x_output;

  wire [11:0] rgb_out;

`ifndef ZX80
parameter zx80_active = 0;
parameter zx81_active = 0;
`endif

`ifndef JUPITERACE
parameter ja_active = 0;
`endif

  vga vga(
  			.clk50m(clk50m),
  			.rstn(rstn),
  			.vga_hs(vga_hs),
  			.vga_vs(vga_vs),
  			.vga_r(vga_r),
  			.vga_g(vga_g),
  			.vga_b(vga_b),
        .x_cnt(x_cnt),
        .y_cnt(y_cnt),
        .hsync_de(hsync_de),
        .vsync_de(vsync_de),
        .rgb_out(rgb_out),
        .vga_clk(vga_clk)
  );

  spectrumscreen spectrumscreen(
    .x_cnt(x_cnt),
    .y_cnt(y_cnt),
    .hsync_de(hsync_de),
    .vsync_de(vsync_de),
    .buf_write(scr_write),
    .buf_write_addr(scr_write_addr),
    .buf_we(scr_write_we),
    .buf_write_clk(sys_clk),
    .border(border),
    .flash_clk(flash_clk),
    .vga_clk(vga_clk),
    .screen_output(screen_output)
    );

  spectrumscreen spectrumscreen2(
    .x_cnt(x_cnt),
    .y_cnt(y_cnt),
    .hsync_de(hsync_de),
    .vsync_de(vsync_de),
    .buf_write(scr_write2),
    .buf_write_addr(scr_write_addr2),
    .buf_we(scr_write_we2),
    .buf_write_clk(sys_clk),
    .border(border),
    .flash_clk(flash_clk),
    .vga_clk(vga_clk),
    .screen_output(screen_output2)
    );

`ifdef JUPITERACE
  jupiterace jupiterace(
    .x_cnt(x_cnt),
    .y_cnt(y_cnt),
    .hsync_de(hsync_de),
    .vsync_de(vsync_de),
    .buf_write(ja_write),
    .buf_write_addr(ja_write_addr),
    .buf_we(ja_write_we),
    .buf_write_clk(sys_clk),
    .border(border),
    .flash_clk(flash_clk),
    .vga_clk(vga_clk),
    .screen_output(jace_output)
    );
`endif

`ifdef ZX8X
	reg[11:0] zx8x_write_addr;
	reg[11:0] zx8x_halt_count = 1'b0;

	reg zx8x_write_we_gate;
	//assign zx8x_write_we_gate = zx8x_halt_count >= 8'h3b && zx8x_halt_count[2:0] == 3'b011;
//	wire zx8x_write_we_gate;
//	assign zx8x_write_we_gate = zx8x_halt_count[2:0] == 3'b011;

	// 59 = 3b = 0011 1011
	//      43 = 0100 0011
	//      4b = 0100 1011
	//      f3 = 1111 0011

	always @(posedge zx8x_write_we) begin
//		zx8x_write_we_gate <= 1'b0;
		zx8x_write_we_gate = zx8x_halt_count[2:0] == 3'b011;
		if (zx8x_write == 8'hff) begin
			zx8x_halt_count <= 12'h0;
			zx8x_write_addr <= 12'h400;
		end else if (zx8x_write == 8'h76) begin
			zx8x_halt_count <= zx8x_halt_count + 1;
		end else if (zx8x_halt_count[2:0] == 3'b011) begin
//			zx8x_write_we_gate <= 1'b1;
			zx8x_write_addr <= zx8x_write_addr + 1;
		end

	end

  zx8x zx8x(
    .x_cnt(x_cnt),
    .y_cnt(y_cnt),
    .hsync_de(hsync_de),
    .vsync_de(vsync_de),
    .buf_write(zx8x_write),
    .buf_write_addr(zx8x_write_addr),
    .buf_we(zx8x_write_we && zx8x_write_we_gate),
    .buf_write_clk(sys_clk),
    .border(border),
    .flash_clk(flash_clk),
    .vga_clk(vga_clk),
    .screen_output(zx8x_output),
    .clk50m(clk50m)
    );
`endif

  assign rgb_out = screen_output;

endmodule
