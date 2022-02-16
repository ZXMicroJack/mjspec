/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module spectrumscreen(
  input [10 : 0] x_cnt,
  input [9 : 0]  y_cnt,
  input hsync_de,
  input vsync_de,
  input vga_clk,

  input[7:0] buf_write,
  input[12:0] buf_write_addr,
  input buf_we,
  input buf_write_clk,

  input[2:0] border,
  input flash_clk,

  output reg[11:0] screen_output
);


parameter FramePeriod =525;           //列周期数
parameter V_SyncPulse=2;              //列同步脉冲（Sync o）
parameter V_BackPorch=33;             //显示后沿（Back porch p）
parameter V_ActivePix=480;            //显示时序段（Display interval q）
parameter V_FrontPorch=10;             //显示前沿（Front porch r）
parameter Vde_start=35;
parameter Vde_end=515;
parameter Hde_start=144;


reg [11:0] border_colour;
wire[7:0] buf_read;
reg[12:0] buf_read_addr;

reg buf_rd = 1'b0;
screen_buffer screen_buffer(
	.read_data(buf_read),
	.addr_out(buf_read_addr),
	.addr_in(buf_write_addr),
	.write_data(buf_write),
	.we(buf_we),
	.clk1(buf_write_clk),
	.clk2(vga_clk && buf_rd)
	);

  // 0 = 000 = 000
  // 1 = 001 = 007
  // 2 = 010 = 700
  // 3 = 011 = 707
  // 4 = 100 = 070
  // 5 = 101 = 077
  // 6 = 110 = 770
  // 7 = 111 = 777

  // ZX SPECTRUM SCREEN BUFFER
  parameter border_left = 64;
  parameter border_top = 48;

  reg is_screen_h;
  reg is_screen_v;
  reg [8:0] x_pos;
  reg [8:0] y_pos;

  // prefetch
  reg[7:0] prefetch_screen_byte;
  reg[7:0] zx_screen_byte;
  reg[7:0] prefetch_screen_attr;
  reg[7:0] zx_screen_attr;

  // left most bit will be 1000
  // final bit will be 0111

  reg[7:0] zx_screen_bytes[0:31];
  reg[7:0] zx_screen_attrs[0:31];
  integer screen_y;
  reg[11:0] ink_colour;
  reg[11:0] paper_colour;
  reg[3:0] intensity;


  always @(posedge vga_clk) begin
  	// is within screen boundaries - ie not border
  	if (x_cnt == 1) border_colour = {border[1] ? 4'h7 : 4'h0, border[2] ? 4'h7 : 4'h0, border[0] ? 4'h7 : 4'h0};
  	if (x_cnt == (Hde_start + border_left - 1) ) begin x_pos <= 0; is_screen_h <= 1'b1; end
  	if (x_cnt == (Hde_start + border_left + 256 + 256 - 1) ) begin is_screen_h <= 1'b0; y_pos <= y_pos + 1; end

		if (x_cnt == (Hde_start + border_left + 256 + 256)) begin
			if (y_cnt == (Vde_start + border_top - 1)) begin y_pos <= 0; is_screen_v <= 1'b1; end
  		if (y_cnt == (Vde_start + border_top + 192 + 191)) is_screen_v <= 1'b0;
		end

  	// prefetch starts at x_cnt = 2 x_pos = 0, ends at x_cnt = ? x_pos = 31
  	// prefetch starts at x_cnt = 36 x_pos = 0, ends at x_cnt = ? x_pos = 31
		`define START_PREFETCH_BYTES	1
  	`define END_PREFETCH_BYTES	65
  	`define START_PREFETCH_ATTRS	67
  	`define END_PREFETCH_ATTRS	131
  	if (is_screen_v) begin
  		if (x_cnt == `START_PREFETCH_BYTES) begin
  			screen_y = y_pos[8:1];
  			buf_read_addr[12:0] <= {screen_y[7:6], screen_y[2:0], screen_y[5:3], 5'b0};
  			x_pos <= 0;
				buf_rd = 1'b1;
  		end else if (x_cnt[0] && x_cnt < `END_PREFETCH_BYTES) begin
  			zx_screen_bytes[x_pos] <= buf_read;
				//$display($stime,,"buf_rad_addr %h buf %h x_pos %h", buf_read_addr, buf_read, x_pos);
  			x_pos <= x_pos + 1;
  			buf_read_addr <= buf_read_addr + 1;
  		end else if (x_cnt == `END_PREFETCH_BYTES) begin
  			zx_screen_bytes[x_pos] <= buf_read;
				//$display($stime,,"buf_rad_addr %h buf %h x_pos %h", buf_read_addr, buf_read, x_pos);
  		end else if (x_cnt == `START_PREFETCH_ATTRS) begin
  			screen_y = y_pos[8:1];
  			buf_read_addr[12:0] <= {3'b110, screen_y[7:3], 5'b0};
  			x_pos <= 0;
  		end else if (x_cnt[0] && x_cnt < `END_PREFETCH_ATTRS) begin
  			zx_screen_attrs[x_pos] <= buf_read;
  			x_pos <= x_pos + 1;
  			buf_read_addr <= buf_read_addr + 1;
  		end else if (x_cnt == `END_PREFETCH_ATTRS) begin
  			zx_screen_attrs[x_pos] <= buf_read;
				buf_rd = 1'b0;
  		end
  	end

  	if (hsync_de && vsync_de) begin
  		if (is_screen_h && is_screen_v) begin
  			// Use prefetch mechanism
  			zx_screen_attr = zx_screen_attrs[x_pos[8:4]];
  			zx_screen_byte = zx_screen_bytes[x_pos[8:4]];

  			intensity = zx_screen_attr[6] ? 4'hf : 4'h7;
  			ink_colour = {zx_screen_attr[1] ? intensity : 4'h0, zx_screen_attr[2] ? intensity : 4'h0, zx_screen_attr[0] ? intensity : 4'h0};
  			paper_colour = {zx_screen_attr[4] ? intensity : 4'h0, zx_screen_attr[5] ? intensity : 4'h0, zx_screen_attr[3] ? intensity : 4'h0};
				//$display($stime,,"y_pos %h x_pos %h byte %h attr %h byte %h attr %h", y_pos, x_pos, zx_screen_bytes[x_pos[8:4]], zx_screen_attrs[x_pos[8:4]], zx_screen_byte, zx_screen_attr);
  			screen_output[11:0] = (zx_screen_byte[x_pos[3:1] ^ 7] ^ (flash_clk & zx_screen_attr[7])) ? ink_colour : paper_colour;

  			// advance bit
  			x_pos <= x_pos + 1;

  		end else screen_output[11:0] = border_colour;
  	end

  end


endmodule
