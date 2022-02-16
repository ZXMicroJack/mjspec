`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
// WEB:
// BBS:
// Create Date:    09:34:12 07/20/2016
// Design Name: 	 DDR3_TEST
// Module Name:    DDR3_Top
// Project Name: 	 DDR3_Top
// Target Devices: XC6SLX16-FTG256/XC6SLX25-FTG256 qm_ddr3
// Tool versions:  ISE14.7
// Description: 	 DDR3 memory Test
// Revision: 		 V1.0
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module MJSpec(
 	output led_1,
	input sys_rst_i,
	input sys_clk_i,

  //------->8------->8------->8------->8------->8------->8------->8
	output[3:0] 			tp, // IO PINS FOR TEST PORT
  //------->8------->8------->8------->8------->8------->8------->8


  output vga_hs,
  output vga_vs,
  output[3:0] vga_r,
  output[3:0] vga_g,
  output[3:0] vga_b,

  //////// ps2 ////////
  input kbd_clk,
  input kbd_data,

  //////// audio ////////
  output aud_left,
  output aud_right,

  //////// sram ////////
  output [18:0] SRAM_ADDR,
  inout [7:0] SRAM_DQ,
  output SRAM_WE_N,

  //////// sdcard ////////
  output SD_cs,
  output SD_clk,
  output SD_datain,
  input SD_dataout,

  //////// tape ////////
  input tape_in,
  output tape_out,

  //////// jtag uart ////////
  input juart_rx,
  output juart_tx,
  
  //////// spi upgrade pins ////////
  output fpga_cclk,
  input fpga_miso,
  output fpga_mosi,
  output reg fpga_cso_b,
  
	 //------->8------->8------->8------->8------->8------->8------->8
 	// IO PINS FOR VGA AND MOUSE FOR LOGIC ANALYSER
 	//------->8------->8------->8------->8------->8------->8------->8
	 inout ps2d,
	 inout ps2c
    );

  clocks clocks(
    .clk50m(sys_clk_i),
    .clk14m(clk14m),
    .clk24m576(clk24m576)
    );

  reg[25:0] count;
  always @(posedge sys_clk_i)
    count <= count + 1;

  reg[2:0] count14m;
  always @(posedge clk14m)
    count14m <= count14m + 1;

  reg[8:0] count24m576;
  always @(posedge clk24m576)
    count24m576 <= count24m576 + 1;

  wire sys_clk, ym2149_clk, flash_clk, clk_audio;

  // single clock sources
  assign flash_clk = count[24]; // 1.490Hz
  assign led_1 = count[25]; // 0.745MHz
  assign sys_clk_x2 = count14m[0]; // 7MHz
  assign sys_clk = count14m[1]; // 3.5MHz
  assign ym2149_clk = count14m[2]; // 3.5MHz
  assign clk_audio = count24m576[8]; // 48kHz

  localparam SPEED_NORMAL = 0;
	localparam SPEED_7MHZ = 1;
	localparam SPEED_14MHZ = 2;

	reg[1:0] cpu_speed = SPEED_NORMAL;
	wire cpu_clk = cpu_speed == SPEED_NORMAL ? count14m[1] :
		cpu_speed == SPEED_7MHZ ? count14m[0] :
		cpu_speed == SPEED_14MHZ ? clk14m : count14m[1];
		
	wire clock_selector;
	
	always @(posedge clock_selector) begin
		if (cpu_speed == SPEED_14MHZ) cpu_speed <= SPEED_NORMAL;
		else cpu_speed <= cpu_speed + 1;
	end

///////////////////   MEMORY   ///////////////////
wire [7:0] roms_dout;
wire [15:0] roms_addr;

// 0000-3fff - 128 rom 0 - extension rom
// 4000-7fff - 128 rom 1 - standard 48k rom
// 8000-9fff - multiface 128 rom
// a000-bfff - opus v22 rom
roms roms_inst(
  .q(roms_dout),
  .a(roms_addr),
  .clk(sys_clk_i)
  );

reg ear, mic;

// spectrum screen
wire[7:0] scr_write;
wire[12:0] scr_write_addr;
wire scr_write_we;
reg[2:0] border = 3'd3;

// spectrum screen2
wire[7:0] scr_write2;
wire[12:0] scr_write_addr2;
wire scr_write_we2;
wire screen_flip;

// uart regs
reg[7:0] uart_txdata;
wire[7:0] uart_rxdata;
reg uart_txgo = 1'b0;
wire uart_txready;
wire uart_rxint;
wire uart_txint;

reg uart_rxint_a = 1'b0;
reg uart_rxint_b = 1'b0;
wire juart_tx1;
wire juart_tx2;
wire uart_rxint_x = uart_rxint_a ^ uart_rxint_b;

wire[7:0] uart_status = {6'd0, uart_txready, uart_rxint_x};
assign juart_tx = dswitch[8] ? juart_tx2 : juart_tx1;

// spi regs
reg spi_tx_enable;
reg spi_rx_enable;
reg[7:0] spi_din;
wire[7:0] spi_dout;
reg spi_dout_valid_a = 1'b0;
reg spi_dout_valid_b = 1'b0;
wire spi_dout_valid_x = spi_dout_valid_a ^ spi_dout_valid_b;

wire[7:0] spi_status = {6'd0, spi_wait_n, spi_dout_valid_x};

always @(posedge spi_wait_n)
	spi_dout_valid_a <= ! spi_dout_valid_a;

///////////////////   RAM   ///////////////////
wire[18:0] roms_addr_adv;
wire[18:0] sram2_addr;
wire[7:0] sram2_din;
wire[7:0] sram2_dout;
wire sram2_n_wr;

assign SRAM_ADDR[18:0] = 
	rom_rd_ovr ? roms_addr_adv :
	advmemmap_override ? sram_addr_adv : 
	sram2_addr;
	
assign SRAM_DQ[7:0] = sram2_n_wr ? 8'hzz : sram2_din;
assign sram2_dout = sram2_n_wr ? SRAM_DQ[7:0] : 8'hff;
assign SRAM_WE_N = sram2_n_wr;
assign sram2_n_wr = !sram_wren;

///////////////////   SIDECAR   ///////////////////
assign clk6m25 = count[2];
assign clk390k625 = count[6];
wire[15:0] dswitch;

wire[7:0] disk_data_in0;
wire[7:0] disk_data_in1;
wire[7:0] disk_data_out0;
wire[7:0] disk_data_out1;
wire[31:0] disk_sr;
wire[31:0] disk_cr;

assign hyper_loading = dswitch[12];
wire [7:0] tape_data;
reg tape_hreq = 1'b0;
reg tape_hack = 1'b0;
wire tape_busy;

wire hyperload_fifo_empty;
reg hyperload_fifo_rd;
wire[7:0] hyperload_fifo_data;
wire hyperload_read_data;

fifo #(.RAM_SIZE(512), .ADDRESS_WIDTH(9)) hyperload_fifo_inst(
  .q(hyperload_fifo_data[7:0]),
  .d(tape_data[7:0]),
  .clk(sys_clk_i),
  .write(tape_dclk),
  .reset(tape_reset),

  .read(hyperload_fifo_rd),
  .empty(hyperload_fifo_empty),
  .full(hyperload_fifo_full)
  );



CtrlModule MyCtrlModule (
  .clk(clk6m25),
  .clk26(sys_clk_i),
  .reset_n(sys_rst_i),

  //-- Video signals for OSD
  .vga_hsync(vga_hs_),
  .vga_vsync(vga_vs_),
  .osd_window(osd_window),
  .osd_pixel(osd_pixel),

  //-- PS2 keyboard
  .ps2k_clk_in(kbd_clk),
  .ps2k_dat_in(kbd_data),

  //-- SD card signals
  .spi_clk(SD_clk),
  .spi_mosi(SD_datain),
  .spi_miso(SD_dataout),
  .spi_cs(SD_cs),

  //-- DIP switches
  .dipswitches(dswitch),

  //-- Control signals
  .host_divert_keyboard(host_divert_keyboard),
  .host_divert_sdcard(host_divert_sdcard),

  // tape interface
  .ear_in(mic),
  .ear_out(ear_in_sc),
  .clk390k625(clk390k625),

  // disk interface
  .disk_data_in(disk_data_out0),
  .disk_data_out(disk_data_in0),
  .disk_data_clkin(disk_data_clkout),
  .disk_data_clkout(disk_data_clkin),

   // disk interface
   .disk_sr(disk_sr),
   .disk_cr(disk_cr),

   //hyperload interface
   .tape_data_out(tape_data),
   .tape_dclk_out(tape_dclk),
   .tape_reset_out(tape_reset),

   .tape_hreq(tape_hreq),
   .tape_busy(tape_busy),
   .cpu_reset(!RESET_n),

   // jtag uart interface
   .juart_rx(juart_rx),
   .juart_tx(juart_tx1)
);

wire[3:0] vga_r_o;
wire[3:0] vga_g_o;
wire[3:0] vga_b_o;

wire[7:0] vga_red_i, vga_green_i, vga_blue_i;
assign vga_red_i = {vga_r_o[3:0], 4'h0};
assign vga_green_i = {vga_g_o[3:0], 4'h0};
assign vga_blue_i = {vga_b_o[3:0], 4'h0};

wire[7:0] vga_red_o, vga_green_o, vga_blue_o;

wire[3:0] vga_r_ = vga_red_o[7:4];
wire[3:0] vga_g_ = vga_green_o[7:4];
wire[3:0] vga_b_ = vga_blue_o[7:4];

// OSD Overlay
OSD_Overlay overlay (
  // .clk(clk25),
  .clk(sys_clk_50m),
  .red_in(vga_red_i),
  .green_in(vga_green_i),
  .blue_in(vga_blue_i),
  .window_in(1'b1),
  .osd_window_in(osd_window),
  .osd_pixel_in(osd_pixel),
  .hsync_in(vga_hsync_i),
  .red_out(vga_red_o),
  .green_out(vga_green_o),
  .blue_out(vga_blue_o),
  .window_out( ),
  .scanline_ena(1'b0) //scandblr_reg[1])
);

///////////////////   DISPLAY   ///////////////////
  display display(
    .clk50m(sys_clk_i),
    .rstn(sys_rst_i),
    .sys_clk(cpu_clk),
    .flash_clk(flash_clk),

    // zx spec screen 1 (48k one)
    .scr_write(scr_write),
    .scr_write_addr(scr_write_addr),
    .scr_write_we(scr_write_we),

    // zx spec border colour
    .border(border),

    // zx spec screen 2 (128k)
    .scr_write2(scr_write2),
    .scr_write_addr2(scr_write_addr2),
    .scr_write_we2(scr_write_we2),

`ifdef JUPITERACE
    // jupiterace screen
    .ja_write(ja_write),
    .ja_write_addr(ja_write_addr),
    .ja_write_we(ja_write_we),
    .ja_active(jupiterace_active && !mm_active),
`endif

`ifdef ZX8X
		.zx8x_write(zx8x_write),
		.zx8x_write_we(zx8x_write_we),
		.zx81_active(zx81_active && !mm_active),
		.zx80_active(zx80_active && !mm_active),
`endif

    // zx which screen to show
    .screen_flip(1'b0),

    // outputs
    .vga_hs(vga_hs_),
    .vga_vs(vga_vs_),
    .vga_r(vga_r_o),
    .vga_g(vga_g_o),
    .vga_b(vga_b_o)
    );


///////////////////   GLUE   ///////////////////
reg [7:0] tap_block_load_routine [0:107];
initial begin
  $readmemh("patches/hyperloader.hex", tap_block_load_routine);
end

wire[7:0] tap_status = {5'b0, hyperload_fifo_full, tape_busy, hyperload_fifo_empty};
wire hyperload_rom_rd;
///////////////////   ADV_MEMMAP   ///////////////////
reg[6:0] mempage[0:15];
reg[15:0] memro = 16'h0000;
reg advmemmap_on = 1'b0;
reg advmemmap_romovr = 1'b0;
wire[18:0] sram_addr_adv = {7'h40 ^ mempage[addr[15:12]], addr[11:0]};

wire advmemmap_override = advmemmap_on && mempage[addr[15:12]] != 7'h00 && !nMREQ;
wire advmemmap_override_write = advmemmap_on && is_mem_write && advmemmap_override && memro[addr[15:12]];
reg inh_opus = 1'b0;
reg inh_mf128 = 1'b0;
reg inh_mf1 = 1'b0;
// wire advmemmap_override_write = 1'b0;
///////////////////   GLUE   ///////////////////
wire[7:0] kbport_dout;

// rom address / data bus

// TODO load rom from disk
// 0000-3fff - 128 rom 0 - extension rom
// 4000-7fff - 128 rom 1 - standard 48k rom
// 8000-9fff - multiface 128 rom
// a000-bfff - opus v22 rom
// c000-dfff - multiface 1 rom
wire[2:0] rom_page;
assign rom_page =
  mf128_active ? 3'b100 :
  mf1_active ? 3'b110 :
  opus_active ? 3'b101 :
  {s128_rom_select, addr[13]} == 2'b00 ? 3'b000 :
  {s128_rom_select, addr[13]} == 2'b01 ? 3'b001 :
  {s128_rom_select, addr[13]} == 2'b10 ? 3'b010 : 3'b011;

assign roms_addr[15:0] = {rom_page[2:0], addr[12:0]};
wire rom_rd;

assign roms_addr_adv[18:0] = {3'b011, rom_page[2:0], addr[12:0]};
// ram address / data bus
assign sram2_addr[18:0] = {1'b0, ram_page[4:0], addr[12:0]};
assign sram2_din[7:0] = cpu_dout[7:0];
wire ram_rd;
wire[4:0] ram_page;
assign ram_page =
  (mf1_active || mf128_active) && addr[15:13] == 3'b001 ? 5'b10110 : // mf128 at 8k  -> ext 0xb x16k
  opus_active && addr[15:13] == 3'b001 ? 5'b10111 :  // opus at 8k   -> ext 0xc x16k
  addr[15:14] == 2'b01 ? {4'b01010, addr[13]} :                  // 48ks at 16k  -> ext 0x8 x16k
  addr[15:14] == 2'b10 ? {4'b00100, addr[13]} :                  // 48ks at 32k  -> ext 0x2 x16k
  addr[15:14] == 2'b11 ? { 1'b0,s128_ram_page_ctl[2:0], addr[13] } :
                                                    // 128ks at 48k -> ext 0x0 | s128_page[2:0] x 16k
  {4'b1010, addr[13]};                                          // 48k at 0k    -> ext 0xa x16k

// screen write address / data bus
assign scr_write[7:0] = cpu_dout[7:0];
assign scr_write_addr[12:0] = addr[12:0];

// screen2 write address / data bus
assign scr_write2[7:0] = cpu_dout[7:0];

// opus discovery signals
reg opus_active = 1'b0;
reg opus_active_tobe = 1'b0;

reg[7:0] mc6821_reg[0:3];
wire opd_wd1770_drq;
wire[1:0] opd_wd1770_a1_0;
wire opd_wd1770_rd, opd_wd1770_wr;
wire[7:0] opd_wd1770_din;
wire[7:0] opd_wd1770_dout;
assign opd_wd1770_a1_0[1:0] = addr[1:0];
assign opd_wd1770_enable = opus_active && addr[15:2] == 14'h0a00;
assign opd_mc6821_enable = opus_active && addr[15:2] == 14'h0c00;
assign opd_ram_enable = opus_active && addr[15:13] == 3'b001 && !opd_wd1770_enable && !opd_mc6821_enable;
assign opd_rom_enable = opus_active && addr[15:13] == 3'b000;
wire[7:0] mc6821_reg_dout;
assign mc6821_reg_dout[7:0] = mc6821_reg[addr[1:0]][7:0];
assign opd_wd1770_rd = is_mem_read && opd_wd1770_enable;
assign opd_wd1770_wr = is_mem_write && opd_wd1770_enable;

// speccy external inputs
assign tape_out = mic;
wire ear_in = ear_in_sc ^ tape_in;

// speccy 128 special signals
wire[7:0] m128_7ffd;
assign m128_7ffd = {2'b00, s128_pg_deny, s128_rom_select, s128_shadow_screen, s128_ram_page_ctl[2:0]};
reg s128_pg_deny = 1'b0;
reg s128_rom_select = 1'b0;
reg s128_shadow_screen = 1'b0;
reg[2:0] s128_ram_page_ctl = 3'b0;

wire NMI;
wire nHALT;
assign NMI = mf1_nmi_pending || mf128_nmi_pending || opd_wd1770_drq;
assign RESET_n = !kf12;

// multiface 128 signals
reg mf128_enabled = 1'b0, mf128_active = 1'b0, mf128_nmi_pending = 1'b0;
wire mf128_rd;

// multiface 1 signals
reg mf1_enabled = 1'b0, mf1_active = 1'b0, mf1_nmi_pending = 1'b0;
wire mf1_rd;

// soundchip 128 signals
// ym2149
// BDIR  BC  MODE
//   0   0   inactive
//   0   1   read value
//   1   0   write value
//   1   1   set address

wire ym2149_enabled;
wire ym2149_bdir, ym2149_bc;
wire[7:0] ym2149_di;
wire[7:0] ym2149_do;

assign ym2149_bdir = !nIORQ && !nWR && (addr[15:0] == 16'hbffd || addr[15:0] == 16'hfffd);
assign ym2149_bc = !nIORQ && ((!nWR && addr[15:0] == 16'hfffd) || (!nRD && addr[15:0] == 16'hfffd));
assign ym2149_enabled = !nIORQ && !nRD && addr[15:0] == 16'hfffd;
assign ym2149_di[7:0] = ym2149_bdir ? cpu_dout[7:0] : 8'h00;
//   assign bdir = (cpuaddr[15] && cpuaddr[1:0]==2'b01 && !iorq_n && !wr_n)? 1'b1 : 1'b0;
//   assign bc1 = (cpuaddr[15] && cpuaddr[1:0]==2'b01 && cpuaddr[14] && !iorq_n)? 1'b1 : 1'b0;                                                              

// spi & uart logic
wire uart_enabled_status = dswitch[8] && !nIORQ && (addr[15:0] == 16'h00ff);
wire uart_enabled_data = dswitch[8] && !nIORQ && (addr[15:0] == 16'h01ff);
wire spi_enabled_status = dswitch[8] && !nIORQ && (addr[15:0] == 16'h03ff);
wire spi_enabled_data = dswitch[8] && !nIORQ && (addr[15:0] == 16'h02ff);

// databus read mux
assign cpu_din[7:0] =
  hyperload_read_data ? hyperload_fifo_data[7:0] :
  hyperload_read_status ? tap_status[7:0] :
  hyperload_rom_rd ? tap_block_load_routine[addr[13:0] - 13'h0556] :
  rom_rd_ovr ? sram2_dout[7:0] :
  rom_rd ? roms_dout[7:0] :
  ram_rd ? sram2_dout[7:0] :
  kb_enable ? kbport_dout[7:0] :
  m128reg_enable ? m128_7ffd[7:0] :
  mf128_rd ? 8'h00 :
  mf1_rd ? 8'h00 :
  (is_mem_read && opd_mc6821_enable) ? mc6821_reg_dout[7:0] :
  (is_mem_read && opd_wd1770_enable) ? opd_wd1770_dout[7:0] :
  ym2149_enabled ? ym2149_do :
  (uart_enabled_data && !nRD) ? uart_rxdata :
  (uart_enabled_status && !nRD) ? uart_status :
  (spi_enabled_status && !nRD) ? spi_status :
  (spi_enabled_data && !nRD) ? spi_dout :
  8'hff;

// address line / cpu decoding
// assign is_rom_addr = ((!opus_active && !mf128_active && addr[15:14] == 2'b00 && !advmemmap_override) || ((opus_active || mf128_active) && addr[15:13] == 2'b000 && !advmemmap_override));
assign is_rom_addr = ((!opus_active && !mf1_active && !mf128_active && addr[15:14] == 2'b00 && !advmemmap_override) || ((opus_active || mf128_active || mf1_active) && addr[15:13] == 2'b000));
assign is_mem_read = !nMREQ && !nRD;
assign is_mem_write = !nMREQ && !nWR;
assign scr_write_we = is_mem_write && addr[15:14] == 2'b01 && (addr[13:0] < 14'd6912);
assign sram_wren = !advmemmap_override_write && is_mem_write && !is_rom_addr && !opd_mc6821_enable && !opd_wd1770_enable;
// assign sram_wren = is_mem_write && !is_rom_addr && !opd_mc6821_enable && !opd_wd1770_enable;
assign rom_rd = is_mem_read && is_rom_addr;
assign rom_rd_ovr = is_mem_read && is_rom_addr && advmemmap_romovr;
// assign hyperload_rom_rd = hyper_loading && is_mem_read && advmemmap_override && is_rom_addr && addr[13:0] >= 14'h0556 && addr[13:0] < 14'h05c2 && rom_page[2:0] == 3'b010;
assign hyperload_rom_rd = hyper_loading && is_mem_read && is_rom_addr && addr[13:0] >= 14'h0556 && addr[13:0] < 14'h05c2 && rom_page[2:0] == 3'b010;

assign hyperload_read_data = hyper_loading && !nIORQ && !nRD && addr[15:0] == 16'h0dff;
assign hyperload_read_status = hyper_loading && !nIORQ && !nRD && addr[15:0] == 16'h0eff;
assign ram_rd = is_mem_read && !is_rom_addr && !opd_mc6821_enable && !opd_wd1770_enable;
assign kb_enable = !nIORQ && !nRD && addr[7:0] == 8'hfe;
assign m128reg_enable = !nIORQ && !nRD && addr[15:0] == 16'h7ffd;
assign mf128_rd = !inh_mf128 && !nIORQ && !nRD && (addr[7:0] == 8'hbf || addr[7:0] == 8'h3f);
assign mf1_rd = !inh_mf1 && !nIORQ && !nRD && (addr[7:0] == 8'h9f || addr[7:0] == 8'h1f);

//TODO no shadow screen
//TODO memory map bit too simple - page all separate no overlapping

wire opus_active_detect = !nMREQ && !nM1 && (addr[15:0] == 16'h1708 || addr[15:0] == 16'h0008 || addr[15:0] == 16'h0048);
wire opus_inactive_detect = !nMREQ && !nM1 && addr[15:0] == 16'h1748;
assign opd_wd1770_din[7:0] = cpu_dout[7:0];

// sequential logic glue
always @(negedge nM1)
  opus_active <= opus_active_tobe;

  
wire total_reset;
wire mf1_button;
reg hyperload_fifo_rd_next = 1'b0;
always @(posedge cpu_clk) begin
	// multiface 128 activation logic
  if (mf128_button && !mf128_nmi_pending && !mf128_active && !inh_mf128)
    { mf128_enabled, mf128_nmi_pending } <= 2'b11;
  if (!mf128_active && !nMREQ && !nM1 && {addr[15:1], 1'b0} == 16'h0066 && mf128_nmi_pending)
    mf128_active <= 1'b1;

	// multiface 1 activation logic
  if (mf1_button && !mf1_nmi_pending && !mf1_active && !inh_mf1)
    mf1_nmi_pending <= 1'b1;
  if (!mf1_active && !nMREQ && !nM1 && {addr[15:1], 1'b0} == 16'h0066 && mf1_nmi_pending)
    mf1_active <= 1'b1;
    
  if (!inh_opus && opus_active_detect)
    opus_active_tobe <= 1'b1;

  if (opus_inactive_detect)
    opus_active_tobe <= 1'b0;

  if (hyperload_fifo_rd_next)
    {hyperload_fifo_rd_next, hyperload_fifo_rd} <= 2'b01;
  else
    hyperload_fifo_rd <= 1'b0;

  // hard reset
  if (!RESET_n) begin
    s128_pg_deny <= 1'b0;
    s128_ram_page_ctl <= 3'b0;
    s128_rom_select <= 1'b0;
    mf1_active <= 1'b0;
    mf1_nmi_pending <= 1'b0;
    mf1_enabled <= 1'b0;
    mf128_active <= 1'b0;
    mf128_nmi_pending <= 1'b0;
    mf128_enabled <= 1'b0;
    mc6821_reg[0] <= 8'h00;
    mc6821_reg[1] <= 8'h00;
    mc6821_reg[2] <= 8'h00;
    mc6821_reg[3] <= 8'h00;
    opus_active_tobe <= 1'b0;
    
    
    if (total_reset) begin
			inh_mf1 <= 1'b0;
			inh_mf128 <= 1'b0;
			inh_opus <= 1'b0;
			advmemmap_on <= 1'b0;
			advmemmap_romovr <= 1'b0;
		end
  end

  if (!nMREQ && !nWR) begin
    if (opd_mc6821_enable) mc6821_reg[addr[1:0]] <= cpu_dout[7:0];
  end


  // io write registers
	uart_txgo <= 1'b0;
  if (!nIORQ && !nWR) begin
    casez(addr[15:0])
      16'b????_????_????_???0: begin
        border[2:0] <= cpu_dout[2:0];
        ear <= cpu_dout[4];
        mic <= cpu_dout[3];
      end
      16'h7ffd: begin
        if (!s128_pg_deny) // && _128_mode)// 128 mode reg
          {s128_pg_deny, s128_rom_select, s128_shadow_screen, s128_ram_page_ctl} <= cpu_dout[5:0];
      end

      // multiface 1 IO ports
      16'h??1f: begin 
        mf1_nmi_pending <= 1'b0;
      end
//       16'h??9f: begin
//         {mf1_enabled, mf1_nmi_pending} <= 2'b10;
//       end

      // multiface 128 IO ports
      16'h??3f: begin // out
        {mf128_enabled, mf128_nmi_pending} <= 2'b00;
      end
      16'h??bf: begin // in
        {mf128_enabled, mf128_nmi_pending} <= 2'b10;
      end

      // ctrl-module interface
      16'h0eff: begin
        tape_hreq <= cpu_dout[0];
      end
      16'h01ff: if (dswitch[8]) begin
				uart_txdata[7:0] <= cpu_dout[7:0];
				uart_txgo <= 1'b1;
      end
      16'h02ff: if (dswitch[8]) begin
				spi_din[7:0] <= cpu_dout[7:0];
				spi_tx_enable <= 1'b1;
				spi_rx_enable <= 1'b0;
      end
      16'h03ff: if (dswitch[8]) begin
				spi_tx_enable <= cpu_dout[1];
				spi_rx_enable <= cpu_dout[2];
				fpga_cso_b <= cpu_dout[0];
      end
      
      16'h05ff: if (dswitch[8]) {inh_mf1, inh_mf128, inh_opus, advmemmap_romovr, advmemmap_on} <= cpu_dout[4:0];
      16'h06ff: if (dswitch[8]) memro[15:8] <= cpu_dout[7:0];
      16'h07ff: if (dswitch[8]) memro[7:0] <= cpu_dout[7:0];
      16'h?4ff: if (dswitch[8]) mempage[addr[15:12]] <= cpu_dout[6:0];

      endcase
  end

  // side actions on io read
  if (!nIORQ && !nRD) begin
    casez(addr[15:0])
      16'h??9f: begin // mf1 in
        mf1_active <= 1'b1;
      end
      16'h??1f: begin // mf1 out
        mf1_active <= 0;
      end
      16'h??bf: begin // mf128 in
        mf128_active <= mf128_enabled;
      end
      16'h??3f: begin // mf128 out
        mf128_active <= 0;
      end
      16'h0dff: begin
        hyperload_fifo_rd_next <= 1'b1;
      end
      16'h01ff: if (dswitch[8]) begin // reset rxint
				uart_rxint_b <= uart_rxint_a;
      end
      16'h02ff: if (dswitch[8]) begin
				spi_dout_valid_b <= spi_dout_valid_a;
      end
    endcase
  end
end


///////////////////   DISK CONTROLLER   ///////////////////
wd1770 wd1770_inst(
  .dd0in(disk_data_in0),
  .dd0inclk(disk_data_clkin),
  .dd0out(disk_data_out0),
  .dd0outclk(disk_data_clkout),
  .dsr(disk_sr),
  .dcr(disk_cr),
  .drsel({mc6821_reg[0][0], mc6821_reg[0][1]}),
  .drwp(dswitch[7:6]),

  .clk(sys_clk_i),

  // interface to cpu
  .din(opd_wd1770_din),
  .dout(opd_wd1770_dout),
  .a1_0(opd_wd1770_a1_0),
  .rd(opd_wd1770_enable && is_mem_read),
  .wr(opd_wd1770_enable && is_mem_write),
  .drq(opd_wd1770_drq),
  .rstn(RESET_n)
  );


///////////////////   CPU   ///////////////////
wire [15:0] addr;
wire  [7:0] cpu_din;
wire  [7:0] cpu_dout;
wire        nM1;
wire        nMREQ;
wire        nIORQ;
wire        nRD;
wire        nWR;
wire        nRFSH;
wire        nBUSACK;
wire         INT;
reg					zxINT;
wire				zx8xINT;

reg        BUSRQ; // = ~ioctl_download;
// wire        RESET;
// wire         NMI;

reg _128_mode = 0;
wire[211:0]	cpu_reg;  // IFF2, IFF1, IM, IY, HL', DE', BC', IX, HL, DE, BC, PC, SP, R, I, F', A', F, A
reg[211:0]	dir_reg;  // IFF2, IFF1, IM, IY, HL', DE', BC', IX, HL, DE, BC, PC, SP, R, I, F', A', F, A
reg	dir_set = 1'b0;

assign INT = zxINT;

tv80s cpu(
  // Outputs
  .m1_n(nM1),
  .mreq_n(nMREQ),
  .iorq_n(nIORQ),
  .rd_n(nRD),
  .wr_n(nWR),
  .rfsh_n(nRFSH),
  .halt_n(nHALT),
  .busak_n(nBUSACK),
  .A(addr[15:0]),
  .dout(cpu_dout),

  // Inputs
  .reset_n(RESET_n),
  .clk(cpu_clk),
  .wait_n(1'b1),
  .int_n(!zxINT),
  .nmi_n(!NMI),
  .busrq_n(1'b1),
  .di(cpu_din)
  );

/////////////////////////////////////////////////////////////////////////////////////////
// PS2 keyboard
wire [4:0] kgfdsa, ktrewq, k54321, k67890, kyuiop, khjklen;
wire [4:0] kvcxzsh_zx, kbnmsssp_zx; // zx spectrum specifics
wire [4:0] kcxzsssh_ja, kvbnmsp_ja; // jupiter ace specifics
wire [8:0] kspecial;

kbmain kbmain(
      .kbd_clk(host_divert_keyboard ? 1'b1 : kbd_clk),
      .kbd_data(host_divert_keyboard ? 1'b1 : kbd_data),
      .clk50m(sys_clk_i),
      .kvcxzsh_zx(kvcxzsh_zx),
      .kgfdsa(kgfdsa),
      .ktrewq(ktrewq),
      .k54321(k54321),
      .k67890(k67890),
      .kyuiop(kyuiop),
      .khjklen(khjklen),
      .kbnmsssp_zx(kbnmsssp_zx),
      .kcxzsssh_ja(kcxzsssh_ja),
      .kvbnmsp_ja(kvbnmsp_ja),
      .kspecial(kspecial)
      );

wire kf12, kfpipe, kf11, kf10, kf9, kf8;
assign kfpipe = kspecial[3];
assign kf10 = kspecial[2];
assign kf11 = kspecial[1];
assign kf12 = kspecial[0];
assign kf9 = kspecial[4];
assign kf8 = kspecial[5];
assign kf7 = kspecial[6];
assign mf1_button = kspecial[7]; // f6
assign mf128_button = kspecial[8]; // f5

assign clock_selector = kf10;
assign total_reset = kfpipe;

// TODO cleanup
assign kbport_dout =
  addr[15:8] == 8'h00 ? {1'b1, ear_in, 1'b1, kvcxzsh_zx & kgfdsa & ktrewq & k54321 & k67890 & kyuiop & khjklen & kbnmsssp_zx} :
  addr[15:8] == 8'hfe ? {1'b1, ear_in, 1'b1, kvcxzsh_zx} :
  addr[15:8] == 8'hfd ? {1'b1, ear_in, 1'b1, kgfdsa} :
  addr[15:8] == 8'hfb ? {1'b1, ear_in, 1'b1, ktrewq} :
  addr[15:8] == 8'hf7 ? {1'b1, ear_in, 1'b1, k54321} :
  addr[15:8] == 8'hef ? {1'b1, ear_in, 1'b1, k67890} :
  addr[15:8] == 8'hdf ? {1'b1, ear_in, 1'b1, kyuiop} :
  addr[15:8] == 8'hbf ? {1'b1, ear_in, 1'b1, khjklen} :
  addr[15:8] == 8'h7f ? {1'b1, ear_in, 1'b1, kbnmsssp_zx} :
  8'hff;

  /////////////////////////////////////////////////////////////////////////////////////////
  // AUDIO

  audio audio(
    .aud_left(aud_left),
    .aud_right(aud_right),
    .clk50m(sys_clk_i),
    .clk_audio(clk_audio),
    .rstn(RESET_n),
    .ym2149_clk(ym2149_clk),
    .ym2149_di(ym2149_di),
    .ym2149_do(ym2149_do),
    .ym2149_bdir(ym2149_bdir),
    .ym2149_bc(ym2149_bc),
    .ear(ear),
    .ear_in(ear_in && dswitch[13])
  );

  ///////////////////   Generate 50Hz Interrupts   ///////////////////
  reg[17:0] INT_timer = 0;
  `define INT_PERIOD  140000
  `define INT_ONPERIOD   128
  always @(posedge sys_clk_x2) begin
    INT_timer <= INT_timer + 1;

    if (INT_timer == `INT_PERIOD) begin
      zxINT <= 1'b1;
      INT_timer <= 0;
    end else if (INT_timer == `INT_ONPERIOD)
      zxINT <= 1'b0;
  end

  ///////////////////   SPI to FPGA flash   ///////////////////
	spi spi_fpga(
		.clk(count14m[0]), // 7MHz
		.enviar_dato(spi_tx_enable),
		.recibir_dato(spi_rx_enable),
		.din(spi_din),
		.dout(spi_dout),
		.wait_n(spi_wait_n),
		.spi_clk(fpga_cclk),
		.spi_di(fpga_mosi),
		.spi_do(fpga_miso)
	);
	
	always @(posedge uart_rxint)
		uart_rxint_a <= !uart_rxint_a;
	
	simple_uart uart_inst(
		.clk(sys_clk_i),
		.reset(RESET_n),
		.txdata(uart_txdata),
		.txgo(uart_txgo),
		.txready(uart_txready),
		.rxdata(uart_rxdata),
		.rxint(uart_rxint),
		.txint(uart_txint),
		.clock_divisor(16'h01b2),
		.rxd(dswitch[8] && juart_rx),
		.txd(juart_tx2)
	);

  ///////////////////   LOGIC ANALYSER   ///////////////////

assign tp[3:0] = {
	spi_wait_n,
	^spi_dout,
	spi_tx_enable,
  spi_rx_enable
};

// assign tp[3:0] = {
assign vga_hs = vga_hs_;
assign vga_vs = vga_vs_;
assign vga_r = vga_r_;
assign vga_g = vga_g_;
assign vga_b = vga_b_;


endmodule
