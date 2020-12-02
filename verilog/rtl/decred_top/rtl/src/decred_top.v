`timescale 1ns / 1ps

`include "decred_defines.v"

module decred_top (
  input  wire  EXT_RESET_N_fromHost,
  input  wire  SCLK_fromHost,
  input  wire  M1_CLK_IN,
  input  wire  M1_CLK_SELECT,
  input  wire  PLL_INPUT,
  input  wire  S1_CLK_IN,
  input  wire  S1_CLK_SELECT,
  input  wire  SCSN_fromHost,
  input  wire  MOSI_fromHost,
  input  wire  MISO_fromClient,
  input  wire  IRQ_OUT_fromClient,
  input  wire  ID_fromClient,

  input  wire  SPI_CLK_RESET_N,

  output wire  SCSN_toClient,
  output wire  SCLK_toClient,
  output wire  MOSI_toClient,
  output wire  EXT_RESET_N_toClient,
  output wire  ID_toHost,

  output wire  CLK_LED,
  output wire  MISO_toHost,
  output wire  HASH_LED,
  output wire  IRQ_OUT_toHost
  );

  // //////////////////////////////////////////////////////
  // Clocking

  // M1 clock is sourced from pin or PLL
  wire m1_clk_internal;
  assign m1_clk_internal = (M1_CLK_SELECT) ? M1_CLK_IN : PLL_INPUT;

  // S1 clock is sourced from pin or divider
  wire s1_clk_internal;
  wire s1_div_output;

  clock_div #(.SIZE(3)) clock_divBlock (
    .in(m1_clk_internal),
    .out(s1_div_output),
    .N(3'h6),
    .resetb(SPI_CLK_RESET_N)
  );

  assign s1_clk_internal = (S1_CLK_SELECT) ? S1_CLK_IN : s1_div_output;

`ifdef USE_NONBLOCKING_HASH_MACRO
  decred_nonblock decred(
`else
  decred_block decred(
`endif
    .EXT_RESET_N_fromHost(EXT_RESET_N_fromHost),
    .SCLK_fromHost(SCLK_fromHost),
    .M1_CLK(m1_clk_internal),
    .SPI_CLK(s1_clk_internal),
    .SCSN_fromHost(SCSN_fromHost),
    .MOSI_fromHost(MOSI_fromHost),
    .MISO_fromClient(MISO_fromClient),
    .IRQ_OUT_fromClient(IRQ_OUT_fromClient),
    .ID_fromClient(ID_fromClient),

    .SCSN_toClient(SCSN_toClient),
    .SCLK_toClient(SCLK_toClient),
    .MOSI_toClient(MOSI_toClient),
    .EXT_RESET_N_toClient(EXT_RESET_N_toClient),
    .ID_toHost(ID_toHost),

    .CLK_LED(CLK_LED),
    .MISO_toHost(MISO_toHost),
    .HASH_LED(HASH_LED),
    .IRQ_OUT_toHost(IRQ_OUT_toHost),
    .hash_clock_reset()
  );

endmodule // decred_top
