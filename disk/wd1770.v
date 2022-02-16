/* This file is part of fpga-spec by ZXMicroJack - see LICENSE.txt for moreinfo */
// ddXin is data in from ctrl-module (byte from disk)
// ddXout is data out to ctrl-module (byte to disk)
// dsr is command to ctrl-module
// dsr[15:0] is position in disk
// dsr[4:0] is sector number
// dsr[11:5] is track number
// dsr[12] is disk side
// dsr[16] is read data 0
// dsr[17] is read sector 0
// dsr[19] is read data 1
// dsr[18] is read sector 1
// dsr[20] is write sector 1
// dsr[21] is write sector 1

// dsc is status from ctrl-module
// dsc[0] = ack0, dsc[1] = fin0, dsc[2] = ack1, dsc[3] = fin1, dsc[4] = ack_ack
// TODO format is a bit defective
// TODO speed up
// TODO multiple disk formats
// TODO faster formats and disk creates
module wd1770(
  // interface to ctrl-module
  input[7:0] dd0in,
  input dd0inclk,
  output[7:0] dd0out,
  input dd0outclk,
  output reg[31:0] dsr,
  input[31:0] dcr,
  input clk,
  input[1:0] drsel,
  input[1:0] drwp,

  // interface to cpu
  input [7:0] din,
  output reg[7:0] dout,
  input [1:0] a1_0,
  input rd,
  input wr,
  output reg drq,
  input rstn
  );

  reg[7:0] trk;
  reg[7:0] sect;
  reg step_in = 1'b1;
  reg cmd_is_type_1 = 1'b0;
  reg motor_on = 1'b0;
  reg disk_wp = 1'b0;
  reg datamark_n = 1'b0;
  reg lostdata = 1'b0;

  parameter CR = {2'b01, 2'b00};
  parameter SR = {2'b10, 2'b00};
  parameter TRKW = {2'b01, 2'b01};
  parameter TRKR = {2'b10, 2'b01};
  parameter SECTW = {2'b01, 2'b10};
  parameter SECTR = {2'b10, 2'b10};
  parameter DATAW = {2'b01, 2'b11};
  parameter DATAR = {2'b10, 2'b11};

  parameter TRK = 2'b01;
  parameter SECT = 2'b10;
  parameter DATA = 2'b11;


  localparam IDLE = 0;
  localparam READSECT = 1;
  localparam READING = 2;
  localparam WRITING = 3;
  localparam COMMIT = 4;
  localparam WAITEND = 5;
  localparam STARTREAD = 6;
  localparam STARTWRITE = 7;
  reg[2:0] state = IDLE;

  reg crcerror, recnotfound, spinupcomplete;
  wire trk0_n;

  assign trk0_n = trk != 8'h00;
  wire busy = state != IDLE;

  reg prev_rd = 1'b0, prev_wr = 1'b0;
  reg[7:0] data_reg = 8'h00;

  wire[7:0] fifo_out_data;
  wire fifo_empty;
  reg fifo_reset = 1'b0;
  reg fifo_out_read = 1'b0;

  fifo fifo_in(
    .q(fifo_out_data),
    .d(dd0in),
    .clk(clk),
    .write(dd0inclk),
    .read(fifo_out_read),
    .reset(fifo_reset),
    .empty(fifo_empty));

  reg fifo_in_write = 1'b0;
  reg[7:0] fifo_in_data = 8'h00;
  reg writing_sector = 1'b0;
  reg sector_commit = 1'b0;

  reg[8:0] fifo_in_size = 1'b0;
  reg prev_dsr4 = 1'b0;
  reg[4:0] nr_sectors = 1'b0;

  fifo fifo_out(
    .q(dd0out),
    .d(fifo_in_data),
    .clk(clk),
    .write(fifo_in_write),
    .read(dd0outclk),
    .reset(fifo_reset),
    .empty(fifo_out_empty));


  always @(posedge clk) begin
    if (!rstn) begin
      drq <= 1'b0;
      dsr[31:0] <= 0;
      fifo_reset <= 1;
      fifo_in_size <= 1'b0;
      state <= IDLE;
    end else fifo_reset <= 0;

    case ({(!prev_rd && rd), (!prev_wr && wr), a1_0[1:0]})
      CR: begin
        disk_wp <= 1'b0;
        cmd_is_type_1 <= !din[7];
        casez(din)
          8'b0000????: begin // restore
            // move to track 0 then irq
            // irq <= 1'b1;
            trk <= 8'h00;
            end
          8'b0001????: begin // seek
            // move to track stored in data register then update register then irq
            // irq <= 1'b1;
            trk <= data_reg;
          end
          8'b001?????: begin // step b4 is update track reg
            if (step_in && din[4] && trk != 8'hff)
              trk <= trk + 1;
              // {irq, trk} <= {1'b1, trk + 1};
            else if (!step_in && din[4] && trk != 8'h00)
              // {irq, trk} <= {1'b1, trk - 1};
              trk <= trk - 1;
          end
          8'b010?????: begin // step in b4 is update track reg
            if (din[4] && trk != 8'hff)
              {trk, step_in} <= {trk + 1, 1'b1};
              // {irq, trk, step_in} <= {1'b1, trk + 1, 1'b1};
          end
          8'b011?????: begin // step out b4 is update track reg
            if (din[4] && trk != 8'h00)
              {trk, step_in} <= {trk - 1, 1'b0};
              // {irq, trk, step_in} <= {1'b1, trk - 1, 1'b0};
          end
          8'b100?????: begin // read sector
            // TODO: assumes 18 sectors / track and 256 bytes per sector;
            //TODO side 0  only for now
            nr_sectors <= 1'b1;
            state <= STARTREAD;
          end
          8'b101?????: begin // write sector
            // TODO: assumes 18 sectors / track and 256 bytes per sector;
            if ((drsel[0] && drwp[1]) || (drsel[1] && drwp[0])) begin
              disk_wp <= 1'b1;
              state <= IDLE;
            end else begin
              nr_sectors <= 1'b1;
              state <= STARTWRITE;
            end
          end
          8'b1100????: begin // read address
          end
          8'b1110????: begin // read track
            // TODO: assumes 18 sectors / track and 256 bytes per sector;
            nr_sectors <= 5'd18;
            sect <= 1'b0;
            state <= STARTREAD;
          end
          8'b1111????: begin // write track
            if ((drsel[0] && drwp[1]) || (drsel[1] && drwp[0])) begin
              disk_wp <= 1'b1;
              state <= IDLE;
            end else begin
              // nr_sectors <= 5'd18;
              sect <= 1'b0;
              state <= IDLE;
            end
          end
          8'b1101????: begin // force interrupt
          end
        endcase // casez(din)
        recnotfound <= 1'b0;
      end // CR: begin

      // SR: dout <= 8'b00;
      SR: begin
        dout <= cmd_is_type_1 ?
          {motor_on,    1'b0, spinupcomplete, recnotfound, crcerror,   trk0_n, drq, busy} :
          {motor_on, disk_wp,     datamark_n, recnotfound, crcerror, lostdata, drq, busy};

        if (state == READING) begin
          drq <= !fifo_empty;
          if (fifo_empty) begin
            nr_sectors <= nr_sectors - 1;
            sect <= sect + 1;
            state <= nr_sectors == 1 ? IDLE : STARTREAD;
          end
          if (!dcr[4]) {dsr[16], dsr[19]} <= 2'b00;

        end else if (state == WRITING) begin
          drq <= fifo_in_size != 256;

        end if (state == WAITEND && !dcr[4]) begin
          {dsr[16], dsr[19]} <= 2'b00;
          fifo_in_size <= 0;
          nr_sectors <= nr_sectors - 1;
          sect <= sect + 1;
          state <= nr_sectors == 1 ? IDLE : STARTWRITE;
        end

      end
      TRKW: trk <= din;
      TRKR: dout <= trk;
      SECTW: sect <= din;
      SECTR: dout <= sect;
      DATAW: begin
        data_reg <= din;
        if (state == WRITING) begin
          fifo_in_write <= 1'b1;
          fifo_in_data <= din;
          fifo_in_size <= fifo_in_size + 1;
          if (fifo_in_size == 255) begin
            if (drsel[0])
              dsr[21:0] <= {6'b100000, 3'b000, 1'b0, trk[6:0], sect[4:0]};
            else
              dsr[21:0] <= {6'b010000, 3'b000, 1'b0, trk[6:0], sect[4:0]};
            state <= COMMIT;
          end
          drq <= 1'b0;
        end
      end
      DATAR: begin
        drq <= 1'b0;
        if (state == READING && !fifo_empty) begin
          fifo_out_read <= 1'b1;
          dout[7:0] <= fifo_out_data[7:0];
        end else begin
            dout[7:0] <= 8'hff;
        end
      end
      default: begin
        fifo_out_read <= 1'b0;
        fifo_in_write <= 1'b0;
        fifo_reset <= 1'b0;
      end
    endcase

    prev_rd <= rd;
    prev_wr <= wr;

    // has finished reading/writing sector, reset read command
    if (dcr[4] && state == COMMIT) begin // finished command
      dsr[20] <= 1'b0; // reset sector write command
      dsr[21] <= 1'b0; // reset sector write command
      dsr[16] <= 1'b1; // signal ack of ack
      recnotfound <= dcr[3];
      state <= dcr[3] ? IDLE : WAITEND;
    end

    if (dcr[4] && state == READSECT) begin // finished command
      dsr[17] <= 1'b0; // reset sector read command
      dsr[18] <= 1'b0; // reset sector read command
      dsr[16] <= 1'b1; // signal ack of ack
      recnotfound <= dcr[3];
      state <= dcr[3] ? IDLE : READING;
    end

    if (state == STARTREAD) begin
      state <= READSECT;
      fifo_reset <= 1'b1;
      if (drsel[0])
        dsr[21:0] <= {6'b000100, 3'b000, 1'b0, trk[6:0], sect[4:0]};
      else
        dsr[21:0] <= {6'b000010, 3'b000, 1'b0, trk[6:0], sect[4:0]};
    end

    if (state == STARTWRITE) begin
      state <= WRITING;
      fifo_reset <= 1'b1;
      fifo_in_size <= 1'b0;
    end

  end

endmodule
