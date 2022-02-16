/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
`timescale 1ns / 1ps

module vga(
			input clk50m,
			input rstn,
			output vga_hs,
			output vga_vs,
			output [3:0] vga_r,
			output [3:0] vga_g,
			output [3:0] vga_b,
			input [11:0] rgb_out,
			output reg [10 : 0] x_cnt,
		  output reg [9 : 0]  y_cnt,
		  output reg hsync_de,
		  output reg vsync_de,
			output reg vga_clk
    );

//-----------------------------------------------------------//
// 1024*768 60Hz VGA - Horizontal timings
//-----------------------------------------------------------//
// parameter LinePeriod =1344;            //行周期数
// parameter H_SyncPulse=136;             //行同步脉冲（Sync a）
// parameter H_BackPorch=160;             //显示后沿（Back porch b）
// parameter H_ActivePix=1024;            //显示时序段（Display interval c）
// parameter H_FrontPorch=24;             //显示前沿（Front porch d）
// parameter Hde_start=296;
// parameter Hde_end=1320;

//-----------------------------------------------------------//
// 1024*768 60Hz VGA - Vertical timings
//-----------------------------------------------------------//
// parameter FramePeriod =806;           //列周期数
// parameter V_SyncPulse=6;              //列同步脉冲（Sync o）
// parameter V_BackPorch=29;             //显示后沿（Back porch p）
// parameter V_ActivePix=768;            //显示时序段（Display interval q）
// parameter V_FrontPorch=3;             //显示前沿（Front porch r）
// parameter Vde_start=35;
// parameter Vde_end=803;

//-----------------------------------------------------------//
// 640x480 60Hz VGA - Horizontal timings
//-----------------------------------------------------------//
parameter LinePeriod =800;            //行周期数
parameter H_SyncPulse=96;             //行同步脉冲（Sync a）
parameter H_BackPorch=48;             //显示后沿（Back porch b）
parameter H_ActivePix=640;            //显示时序段（Display interval c）
parameter H_FrontPorch=16;             //显示前沿（Front porch d）
parameter Hde_start=144;
parameter Hde_end=784;

//-----------------------------------------------------------//
// 640x480 60Hz VGA - Vertical timings
//-----------------------------------------------------------//
parameter FramePeriod =525;           //列周期数
parameter V_SyncPulse=2;              //列同步脉冲（Sync o）
parameter V_BackPorch=33;             //显示后沿（Back porch p）
parameter V_ActivePix=480;            //显示时序段（Display interval q）
parameter V_FrontPorch=10;             //显示前沿（Front porch r）
parameter Vde_start=35;
parameter Vde_end=515;

//-----------------------------------------------------------//
// 800*600 VGA - Horizontal timings
//-----------------------------------------------------------//
//parameter LinePeriod =1056;           //行周期数
//parameter H_SyncPulse=128;            //行同步脉冲（Sync a）
//parameter H_BackPorch=88;             //显示后沿（Back porch b）
//parameter H_ActivePix=800;            //显示时序段（Display interval c）
//parameter H_FrontPorch=40;            //显示前沿（Front porch d）

//-----------------------------------------------------------//
// 800*600 VGA - Vertical timings
//-----------------------------------------------------------//
//parameter FramePeriod =628;           //列周期数
//parameter V_SyncPulse=4;              //列同步脉冲（Sync o）
//parameter V_BackPorch=23;             //显示后沿（Back porch p）
//parameter V_ActivePix=600;            //显示时序段（Display interval q）
//parameter V_FrontPorch=1;             //显示前沿（Front porch r）


  reg[3 : 0]  vga_r_reg;
  reg[3 : 0]  vga_g_reg;
  reg[3 : 0]  vga_b_reg;
  reg hsync_r;
  reg vsync_r;

//----------------------------------------------------------------
////////// Horizontal scan count
//----------------------------------------------------------------
always @ (posedge vga_clk)
       if(~rstn)    x_cnt <= 1;
       else if(x_cnt == LinePeriod) x_cnt <= 1;
       else x_cnt <= x_cnt+ 1;

//----------------------------------------------------------------
////////// Horizontal scanning signals hsync, hsync_de are generated
//----------------------------------------------------------------
always @ (posedge vga_clk)
   begin
       if(~rstn) hsync_r <= 1'b1;
       else if(x_cnt == 1) hsync_r <= 1'b0;            //产生hsync信号
       else if(x_cnt == H_SyncPulse) hsync_r <= 1'b1;


	    if(1'b0) hsync_de <= 1'b0;
       else if(x_cnt == Hde_start) hsync_de <= 1'b1;    //产生hsync_de信号
       else if(x_cnt == Hde_end) hsync_de <= 1'b0;
	end

//----------------------------------------------------------------
////////// Vertical scan count
//----------------------------------------------------------------
always @ (posedge vga_clk)
       if(~rstn) y_cnt <= 1;
       else if(y_cnt == FramePeriod) y_cnt <= 1;
       else if(x_cnt == LinePeriod) y_cnt <= y_cnt+1;

//----------------------------------------------------------------
////////// 垂直扫描信号vsync, vsync_de产生
//----------------------------------------------------------------
always @ (posedge vga_clk)
  begin
       if(~rstn) vsync_r <= 1'b1;
       else if(y_cnt == 1) vsync_r <= 1'b0;    //产生vsync信号
       else if(y_cnt == V_SyncPulse) vsync_r <= 1'b1;

	    if(~rstn) vsync_de <= 1'b0;
       else if(y_cnt == Vde_start) vsync_de <= 1'b1;    //产生vsync_de信号
       else if(y_cnt == Vde_end) vsync_de <= 1'b0;
  end

//----------------------------------------------------------------
////////// VGA image selection output
//----------------------------------------------------------------
  always @(negedge vga_clk) begin
		vga_r_reg <= rgb_out[11:8];
	  vga_g_reg <= rgb_out[7:4];
	  vga_b_reg <= rgb_out[3:0];
	end

  assign vga_hs = hsync_r;
  assign vga_vs = vsync_r;
  assign vga_r = (hsync_de & vsync_de)?vga_r_reg:4'b0000;
  assign vga_g = (hsync_de & vsync_de)?vga_g_reg:4'b0000;
  assign vga_b = (hsync_de & vsync_de)?vga_b_reg:4'b0000;

	//----------------------------------------------------------------
	////////// VGA clock generation
	//----------------------------------------------------------------
	always @(posedge clk50m)
		vga_clk <= !vga_clk;

		// // 65Mhz VGA Clock
	  //   pll pll_inst
	  //  (
	  //   .inclk0(clk),
	  //   .c0(vga_clk),               // 65.0Mhz for 1024x768(60hz)
	  //   .areset(~rstn),
	  //   .locked()
	 	// );

endmodule
