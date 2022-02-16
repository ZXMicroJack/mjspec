/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module jupiterace(
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


parameter FramePeriod =525;
parameter V_SyncPulse=2;
parameter V_BackPorch=33;
parameter V_ActivePix=480;
parameter V_FrontPorch=10;
parameter Vde_start=35;
parameter Vde_end=515;
parameter Hde_start=144;

reg [11:0] border_colour;
wire[7:0] buf_read;
reg[12:0] buf_read_addr;
reg buf_rd = 1'b0;
ram_dual ram(buf_read, buf_write_addr, buf_read_addr, buf_write, buf_we, buf_write_clk, buf_rd);
defparam ram.RAMSIZE = 12'hc00;

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
  // parameter border_colour = 12'h077;

  reg is_screen_h;
  reg is_screen_v;
  reg [8:0] x_pos;
  reg [8:0] y_pos;

  // prefetch
  reg[12:0] screen_line_pos;
  reg[7:0] mask;
  reg inv, next_inv;

  always @(posedge vga_clk) begin
  	// is within screen boundaries - ie not border
    // display border, maintain scan doubled 256 x 192 with signals x_pos, y_pos is_screen_h is_screen_v
  	if (x_cnt == 1) border_colour = {border[1] ? 4'h7 : 4'h0, border[2] ? 4'h7 : 4'h0, border[0] ? 4'h7 : 4'h0};
  	if (x_cnt == (Hde_start + border_left - 1) ) begin x_pos <= 0; is_screen_h <= 1'b1; end
  	if (x_cnt == (Hde_start + border_left + 256 + 256 - 1) ) begin is_screen_h <= 1'b0; y_pos <= y_pos + 1; end

		if (x_cnt == (Hde_start + border_left + 256 + 256)) begin
			if (y_cnt == (Vde_start + border_top - 1)) begin y_pos <= 0; is_screen_v <= 1'b1; end
  		if (y_cnt == (Vde_start + border_top + 192 + 192)) is_screen_v <= 1'b0;
		end

    // prefetch first byte
    if (is_screen_v) begin
      // 17f = 1 0111 1111 =
      if (x_cnt == 1) screen_line_pos <= {y_pos[8:4], 5'h00};

      if ((x_cnt == Hde_start + border_left - 16) || (is_screen_h && x_pos[3:0] == 4'h4)) begin
        buf_read_addr <= screen_line_pos;
        screen_line_pos <= screen_line_pos + 1;
				//$display($stime,,"1buf_read_addr %h screen_line_pos %h x_pos %h x_cnt %h",
				//				buf_read_addr, screen_line_pos, x_pos, x_cnt);
      end

      if ((x_cnt == Hde_start + border_left - 14) || (is_screen_h && x_pos[3:0] == 4'h6)) begin
				buf_rd <= 1'b1;
				//$display($stime,,"1buf_read_addr %h screen_line_pos %h x_pos %h x_cnt %h",
				//				buf_read_addr, screen_line_pos, x_pos, x_cnt);
      end

      if ((x_cnt == Hde_start + border_left - 12) || (is_screen_h && x_pos[3:0] == 4'h8)) begin
        buf_rd <= 1'b0;
        buf_read_addr[12:0] <= {3'b001, buf_read[6:0], y_pos[3:1]};
        next_inv <= buf_read[7];
				//$display($stime,,"2buf_read_addr %h screen_line_pos %h x_pos %h x_cnt %h buf_read %h",
				//				buf_read_addr, screen_line_pos, x_pos, x_cnt, buf_read);
      end

      if ((x_cnt == Hde_start + border_left - 8) || (is_screen_h && x_pos[3:0] == 4'hc)) begin
				buf_rd <= 1'b1;
				//$display($stime,,"2buf_read_addr %h screen_line_pos %h x_pos %h x_cnt %h buf_read %h",
				//				buf_read_addr, screen_line_pos, x_pos, x_cnt, buf_read);
      end

      if ((x_cnt == Hde_start + border_left - 4) || (is_screen_h && x_pos[3:0] == 4'hf)) begin
        mask[7:0] <= buf_read;
				inv <= next_inv;
				buf_rd <= 1'b0;
				//$display($stime,,"3buf_read_addr %h screen_line_pos %h x_pos %h x_cnt %h buf_read %h",
				//				buf_read_addr, screen_line_pos, x_pos, x_cnt, buf_read);
      end
    end


		// #define RAM_CHARSET   0x2c00
    // #define SCREEN_POS    0x2400
    // 000 = 2000 = 2400
    // 400 = 2800 = 2c00
    // c00 = 3000 = 3400 = 3800 = 3c00

  	if (hsync_de && vsync_de) begin
  		if (is_screen_h && is_screen_v) begin
  			// Use prefetch mechanism
        screen_output[11:0] <= ((mask[7] && !inv) || (!mask[7] && inv)) ? 12'h777 : 12'h000;

			 	// bitshift one every other bit - screen is scan-doubled.
				if (x_cnt[0] && x_pos[3:0] != 4'hf) mask[7:1] <= mask[6:0];

  			// advance bit
  			x_pos <= x_pos + 1;

  		end else screen_output[11:0] <= border_colour;
  	end
  end


endmodule
