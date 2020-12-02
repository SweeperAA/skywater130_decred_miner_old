`timescale 1ns / 1ps

`include "decred_defines.v"

`ifdef USE_NONBLOCKING_HASH_MACRO
module decred_nonblock (
`else
module decred_block (
`endif
  input  wire  EXT_RESET_N_fromHost,
  input  wire  SCLK_fromHost,
  input  wire  M1_CLK,
  input  wire  SPI_CLK,
  input  wire  SCSN_fromHost,
  input  wire  MOSI_fromHost,
  input  wire  MISO_fromClient,
  input  wire  IRQ_OUT_fromClient,
  input  wire  ID_fromClient,

  output wire  SCSN_toClient,
  output wire  SCLK_toClient,
  output wire  MOSI_toClient,
  output wire  EXT_RESET_N_toClient,
  output wire  ID_toHost,

  output wire  CLK_LED,
  output wire  MISO_toHost,
  output wire  HASH_LED,
  output wire  IRQ_OUT_toHost,
  output wire  hash_clock_reset
  );

  // //////////////////////////////////////////////////////
  // Pass-through wires
  wire rst_local;
  wire sclk_local;
  wire scsn_local;
  wire mosi_local;
  wire miso_local;
  wire irq_local;
  wire address_stobe;
  wire write_enable;
  wire [6:0] setSPIAddr;

  // //////////////////////////////////////////////////////
  // Heartbeat output

  reg [23:1] counter;
  
  always @(posedge M1_CLK)
    if (rst_local) 
	    counter <= 0;
	  else
	    counter <= counter + 1'b1;

  assign CLK_LED = counter[23];

  // //////////////////////////////////////////////////////
  // SPI deserializer

  wire       start_of_transfer;
  wire       end_of_transfer;
  wire [7:0] mosi_data_out;
  wire       mosi_data_ready;
  wire       miso_data_request;
  wire [7:0] miso_data_in;

  spi spiBlock(
    .iCLK(SPI_CLK),
    .RST(rst_local),
    .SCLK(sclk_local),
    .SCSN(scsn_local),
    .MOSI(mosi_local),

    .start_of_transfer(start_of_transfer),
    .end_of_transfer(end_of_transfer),
	  .mosi_data_out(mosi_data_out),
    .mosi_data_ready(mosi_data_ready),
    .MISO(miso_local),
    .miso_data_request(miso_data_request),
    .miso_data_in(miso_data_in)
  );

  // //////////////////////////////////////////////////////
  // SPI pass through
  spi_passthrough spiPassBlock(
    .iCLK(SPI_CLK),
    .RSTin(EXT_RESET_N_fromHost),
    .ID_in(ID_fromClient),
    .IRQ_in(IRQ_OUT_fromClient),
    .address_strobe(address_stobe),
    .currentSPIAddr(address[14:8]),
    .setSPIAddr(setSPIAddr),

    .SCLKin(SCLK_fromHost),
    .SCSNin(SCSN_fromHost),
    .MOSIin(MOSI_fromHost),
    .MISOout(MISO_toHost),

    .rst_local(rst_local),
    .sclk_local(sclk_local),
    .scsn_local(scsn_local),
    .mosi_local(mosi_local),
    .miso_local(miso_local),
    .irq_local(irq_local),
    .write_enable(write_enable),

    .RSTout(EXT_RESET_N_toClient),
    .SCLKout(SCLK_toClient),
    .SCSNout(SCSN_toClient),
    .MOSIout(MOSI_toClient),
    .MISOin(MISO_fromClient),
    .IRQout(IRQ_OUT_toHost)
  );

  // //////////////////////////////////////////////////////
  // Interface to addressalyzer

  wire [14:0] address;
  wire        regFile_read_strobe;
  wire        regFile_write_strobe;

  addressalyzer addressalyzerBlock (
    .iCLK(SPI_CLK),
    .RST(rst_local),

    .start_of_transfer(start_of_transfer),
    .end_of_transfer(end_of_transfer),
    .data_in_value(mosi_data_out),
    .data_in_ready(mosi_data_ready),
    .data_out_request(miso_data_request),
    .write_enable_mask(write_enable),

    .ram_address_out(address),
    .address_strobe(address_stobe),
    .ram_read_strobe(regFile_read_strobe),
    .ram_write_strobe(regFile_write_strobe)
  );

  // //////////////////////////////////////////////////////
  // Interface to regfile


  regBank #(.NUM_OF_MACROS(4))
  regBankBlock (
    .iCLK(SPI_CLK),
    .RST(rst_local),
    .MAIN_CLOCK(M1_CLK),
    .address(address[7:0]),
    .data_in(mosi_data_out),
    .read_strobe(regFile_read_strobe),
    .write_strobe(regFile_write_strobe),
    .hash_clock_reset(hash_clock_reset),
    .data_out(miso_data_in),
    .LED_out(HASH_LED),
    .spi_addr(setSPIAddr),
    .ID_out(ID_toHost),
    .interrupt_out(irq_local)
  );

endmodule // decred
