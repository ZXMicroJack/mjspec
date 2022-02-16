/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
module zx8x(
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

  output reg[11:0] screen_output,
  input clk50m
);


parameter FramePeriod =525;
parameter V_SyncPulse=2;
parameter V_BackPorch=33;
parameter V_ActivePix=480;
parameter V_FrontPorch=10;
parameter Vde_start=35;
parameter Vde_end=515;
parameter Hde_start=144;
//parameter DISP_START = 12'h407;
//parameter DISP_START = 12'h400;
//reg [11:0] border_colour;
wire[7:0] buf_read;
reg[12:0] buf_read_addr;
reg buf_rd = 1'b0;

zx8x_vram ram(buf_read, buf_write_addr, buf_read_addr, buf_write, buf_we, clk50m, buf_rd);

//reg[12:0] buf_write_addr_x;
//reg buf_we_x = 1'b0;
//reg[2:0] buf_wr_state = 3'b000;
//zx8x_vram ram(buf_read, buf_write_addr_x, buf_read_addr, buf_write, buf_we_x, clk50m, buf_rd);
//
//	always @(posedge clk50m) begin
//		case (buf_wr_state)
//			3'b000: if (buf_we) buf_wr_state <= 3'b001;
//			3'b001: begin buf_write_addr_x <= buf_write_addr; buf_wr_state <= 3'b010; end
//			3'b010: begin buf_we_x <= 1'b1; buf_wr_state <= 3'b011; end
//			3'b011: if (!buf_we) buf_wr_state <= 3'b100;
//			3'b010: begin buf_we_x <= 1'b0; buf_wr_state <= 3'b000; end
//		endcase
//	end


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
  parameter border_colour = 12'h777; // always on zx80 / zx81

  reg is_screen_h;
  reg is_screen_v;
  reg [8:0] x_pos;
  reg [8:0] y_pos;

  // prefetch
  reg[12:0] screen_line_pos_reload;
  reg[12:0] screen_line_pos;
  reg[7:0] mask;
  reg inv, next_inv;
  reg was_halt = 1'b0;

  always @(posedge vga_clk) begin
  	// is within screen boundaries - ie not border
    // display border, maintain scan doubled 256 x 192 with signals x_pos, y_pos is_screen_h is_screen_v

    // latch border colour at x=1 for whole line
//  	if (x_cnt == 1) border_colour = {border[1] ? 4'h7 : 4'h0, border[2] ? 4'h7 : 4'h0, border[0] ? 4'h7 : 4'h0};

		// start of active area
  	if (x_cnt == (Hde_start + border_left - 1) ) begin x_pos <= 0; is_screen_h <= 1'b1; was_halt <= 1'b0; end

  	// end of active area
  	if (x_cnt == (Hde_start + border_left + 256 + 256 - 1) ) begin is_screen_h <= 1'b0; y_pos <= y_pos + 1; end

		// right of active area
		if (x_cnt == (Hde_start + border_left + 256 + 256)) begin
			// line just above active area
			if (y_cnt == (Vde_start + border_top - 1)) begin
				y_pos <= 0;
				is_screen_v <= 1'b1;
				screen_line_pos_reload <= 12'h407;
				screen_line_pos <= 12'h407;
			end

			if (is_screen_v && y_cnt[3:0] == 4'hf)
				screen_line_pos_reload <= screen_line_pos;
			else
				screen_line_pos <= screen_line_pos_reload;

			// line just below active area
  		if (y_cnt == (Vde_start + border_top + 192 + 192)) is_screen_v <= 1'b0;
		end

    // prefetch first byte
    if (is_screen_v) begin
			if (!was_halt) begin
				if ((x_cnt == Hde_start + border_left - 16) || (is_screen_h && x_pos[3:0] == 4'h4)) begin
					buf_read_addr <= screen_line_pos;
					screen_line_pos <= screen_line_pos + 1;
				end

				if ((x_cnt == Hde_start + border_left - 14) || (is_screen_h && x_pos[3:0] == 4'h6)) begin
					buf_rd <= 1'b1;
				end
			end

			if ((x_cnt == Hde_start + border_left - 12) || (is_screen_h && x_pos[3:0] == 4'h8)) begin
				buf_rd <= 1'b0;
				if (was_halt || buf_read == 8'h76) begin
					buf_read_addr[12:0] <= {3'b000, 7'b0000000, y_pos[3:1]};
					was_halt <= 1'b1;
					next_inv <= 1'b0;
				end else begin
					buf_read_addr[12:0] <= {4'b0000, buf_read[5:0], y_pos[3:1]};
					next_inv <= buf_read[7];
				end
			end

			if ((x_cnt == Hde_start + border_left - 8) || (is_screen_h && x_pos[3:0] == 4'hc)) begin
				buf_rd <= 1'b1;
			end

			if ((x_cnt == Hde_start + border_left - 4) || (is_screen_h && x_pos[3:0] == 4'hf)) begin
				mask[7:0] <= buf_read;
				inv <= next_inv;
				buf_rd <= 1'b0;
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
//        screen_output[11:0] <= ((mask[7] && !inv) || (!mask[7] && inv)) ? 12'h777 : 12'h000;
        screen_output[11:0] <= ((mask[7] && !inv) || (!mask[7] && inv)) ? 12'h000 : 12'h777;

			 	// bitshift one every other bit - screen is scan-doubled.
				if (x_cnt[0] && x_pos[3:0] != 4'hf) mask[7:1] <= mask[6:0];

  			// advance bit
  			x_pos <= x_pos + 1;

  		end else screen_output[11:0] <= border_colour;
  	end
  end


endmodule
