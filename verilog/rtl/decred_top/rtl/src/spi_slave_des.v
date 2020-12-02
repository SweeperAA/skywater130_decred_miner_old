`timescale 1ns / 1ps

module spi (
  input  wire  iCLK,
  input  wire  RST,
  input  wire  SCLK,
  input  wire  SCSN,
  input  wire  MOSI,

  output reg       start_of_transfer,
  output reg       end_of_transfer,
  output reg [7:0] mosi_data_out,
  output reg       mosi_data_ready,
  output reg       MISO,
  output reg       miso_data_request,
  input  [7:0]     miso_data_in
  );

  // //////////////////////////////////////////////////////
  // synchronizers
  reg [1:0] scsn_resync;
  reg [1:0] sclk_resync;
  reg [1:0] mosi_resync;

  reg [1:0] scsn_edge;
  reg [1:0] sclk_edge;

  wire scsn_rs;
  wire mosi_rs;
  reg  rising_sclk;
  reg  falling_sclk;

  always @(posedge iCLK)
    if (RST) begin
      sclk_resync <= 0;
      sclk_edge   <= 'h0;
      scsn_resync <= 'h3;
      scsn_edge   <= 'h3;
      mosi_resync <= 0;
    end
    else begin
      scsn_resync <= {scsn_resync[0], SCSN};
      scsn_edge   <= {scsn_edge[0], scsn_resync[1]};
      sclk_resync <= {sclk_resync[0], SCLK};
      sclk_edge   <= {sclk_edge[0], sclk_resync[1]};
      mosi_resync <= {mosi_resync[0], MOSI};
    end

  assign scsn_rs = scsn_resync[1];
  assign mosi_rs = mosi_resync[1];
  
  always @(posedge iCLK)
    if (RST) begin
      rising_sclk  <= 0;
	  falling_sclk <= 0;
      start_of_transfer <= 0;
      end_of_transfer <= 0;
	end
	else begin
	  rising_sclk  <= !sclk_edge[1] & sclk_edge[0] & !scsn_rs;
      falling_sclk <= sclk_edge[1] & !sclk_edge[0] & !scsn_rs; 
      start_of_transfer <= scsn_edge[1] & !scsn_edge[0];
      end_of_transfer <= !scsn_edge[1] & scsn_edge[0];
	end

  // //////////////////////////////////////////////////////
  // strobes

  reg [2:0] bitcount;
  reg       byteCountStrobe;

  always @(posedge iCLK)
    if (RST) begin
      bitcount <= 0;
      byteCountStrobe <= 0;
    end
	else if (start_of_transfer) begin
      bitcount <= 0;
      byteCountStrobe <= 0;
    end
    else if (falling_sclk) begin
      bitcount <= bitcount + 1'b1;
      byteCountStrobe <= (bitcount == 'h7);
    end
    else if (byteCountStrobe | scsn_rs)
      byteCountStrobe <= 0;

  // //////////////////////////////////////////////////////
  // MOSI snapshot register and output

  reg [7:0] mosi_data_shift_reg;

  always @(posedge iCLK)
    if (RST) begin
      mosi_data_shift_reg <= 0;
    end
    else if (rising_sclk) begin
      mosi_data_shift_reg <= {mosi_data_shift_reg[6:0], mosi_rs};
    end

  always @(posedge iCLK)
    if (RST) begin
      mosi_data_out <= 0;
    end
    else if (byteCountStrobe) begin
      mosi_data_out <= mosi_data_shift_reg;
    end

  always @(posedge iCLK)
    if (RST)
      mosi_data_ready <= 0;
    else
      mosi_data_ready <= byteCountStrobe;

  // //////////////////////////////////////////////////////
  // MISO input capture and presentation to host

  reg [7:0] miso_data_shift_reg;

  always @(posedge iCLK)
    if (RST)
      miso_data_request <= 0;
    else
      miso_data_request <= byteCountStrobe;

  always @(posedge iCLK)
    if (RST) begin
      miso_data_shift_reg <= 0;
	end
    else if (miso_data_request) begin
      miso_data_shift_reg <= miso_data_in;
	end
    else if (falling_sclk)
      miso_data_shift_reg <= {miso_data_shift_reg[6:0], 1'b0};

  always @(posedge iCLK)
    if (RST)
      MISO <= 0;
    else
      MISO <= miso_data_shift_reg[7];


endmodule // spi
